# Supabase Setup Guide for StudyNova

This guide will help you connect your Flutter app to Supabase for authentication and database management.

## Step 1: Create a Supabase Account and Project

1. Go to [supabase.com](https://supabase.com) and sign up for a free account
2. Create a new project:
   - Click "New Project"
   - Enter a project name (e.g., "StudyNova")
   - Set a secure database password
   - Select a region closest to your users
   - Click "Create new project" and wait for it to initialize

## Step 2: Get Your Supabase Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. You'll see two keys:
   - **Project URL**: This is your Supabase URL
   - **anon (public)**: This is your public API key (anonKey)
3. Copy both values - you'll need them in the next step

## Step 3: Add Credentials to Your Flutter App

1. Open `lib/main.dart` in your project
2. Find these lines:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```
3. Replace with your actual credentials:
   ```dart
   await Supabase.initialize(
     url: 'https://your-project.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
   );
   ```

## Step 4: Set Up Authentication in Supabase

1. In Supabase dashboard, go to **Authentication** → **Providers**
2. Make sure **Email** provider is enabled (it should be by default)
3. Go to **Authentication** → **Policies** and check settings:
   - Allow email/password sign-ups
   - Allow new user registration

## Step 5: Create Database Tables (Optional)

For course data, you can create these tables in Supabase:

### Users Table
The users table is automatically created by Supabase Auth. Check it in **SQL Editor**.

### Courses Table
```sql
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  content JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX courses_user_id_idx ON courses(user_id);
```

### Enrollments Table
```sql
CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  progress INTEGER DEFAULT 0
);

-- Create index
CREATE INDEX enrollments_user_id_idx ON enrollments(user_id);
CREATE INDEX enrollments_course_id_idx ON enrollments(course_id);
```

## Step 6: Set Up Row Level Security (RLS)

For security, enable Row Level Security on your tables:

1. Go to **SQL Editor**
2. Run this to enable RLS on courses:
   ```sql
   ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

   -- Users can only see their own courses
   CREATE POLICY "Users can view their own courses" ON courses
     FOR SELECT USING (auth.uid() = user_id);

   -- Users can only insert their own courses
   CREATE POLICY "Users can insert their own courses" ON courses
     FOR INSERT WITH CHECK (auth.uid() = user_id);

   -- Users can only update their own courses
   CREATE POLICY "Users can update their own courses" ON courses
     FOR UPDATE USING (auth.uid() = user_id);

   -- Users can only delete their own courses
   CREATE POLICY "Users can delete their own courses" ON courses
     FOR DELETE USING (auth.uid() = user_id);
   ```

3. Do the same for enrollments table

## Step 7: Test Authentication

1. In your terminal, run:
   ```bash
   flutter pub get
   flutter run
   ```

2. Test the authentication flow:
   - Tap "Sign In" → Try signing up with a test email
   - Check your Supabase dashboard under **Authentication** → **Users** to see registered users
   - Test login with the credentials you just created

## Step 8: Connect Database Operations

Update your app to fetch and store data. Example for fetching user's courses:

```dart
// In a new file: lib/services/course_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseService {
  final _supabase = Supabase.instance.client;

  // Get all user's courses
  Future<List<Map<String, dynamic>>> getUserCourses() async {
    final userId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase
        .from('courses')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);

    return response;
  }

  // Create a new course
  Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required Map<String, dynamic> content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase
        .from('courses')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'content': content,
        })
        .select();

    return response.first;
  }

  // Update a course
  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
  }) async {
    await _supabase
        .from('courses')
        .update({
          'title': title,
          'description': description,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', courseId);
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _supabase
        .from('courses')
        .delete()
        .eq('id', courseId);
  }
}
```

## Step 9: Troubleshooting

### "Connection refused" error
- Check your Supabase URL and anonKey are correct
- Make sure you're using the public anonKey, not the service_role_key

### "Authentication error" on sign-up
- Check that email provider is enabled in Supabase
- Verify the email format is valid
- Check Supabase logs for detailed error messages

### RLS errors when querying
- Make sure Row Level Security policies are set correctly
- Verify auth.uid() matches the user making the request
- Check you're using an authenticated user session

### Need real-time updates?
Subscribe to changes using Supabase Realtime:
```dart
final coursesStream = _supabase
    .from('courses')
    .stream(primaryKey: ['id'])
    .eq('user_id', userId)
    .asyncMap((rows) => rows.map((row) => Course.fromJson(row)).toList());
```

## Useful Links

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Authentication Guide](https://supabase.com/docs/guides/auth)
- [Supabase Database Guide](https://supabase.com/docs/guides/database)
- [Supabase RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)

## Environment Variables (Optional but Recommended)

For production, use environment variables instead of hardcoding credentials:

1. Create `.env` file:
   ```
   SUPABASE_URL=your_url_here
   SUPABASE_ANON_KEY=your_key_here
   ```

2. Add to pubspec.yaml:
   ```yaml
   dev_dependencies:
     flutter_dotenv: ^5.0.0
   ```

3. Update main.dart:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await dotenv.load();
     
     await Supabase.initialize(
       url: dotenv.env['SUPABASE_URL'] ?? '',
       anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
     );
   }
   ```
