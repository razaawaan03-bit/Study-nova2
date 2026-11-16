# 🚀 StudyNova - Quick Start Card

## ⚡ In 5 Minutes

### 1. Get Dependencies
```bash
flutter pub get
```

### 2. Get Supabase Credentials
- Go to https://supabase.com
- Create account & project
- Get URL + Anon Key from Settings → API

### 3. Update main.dart
```dart
await Supabase.initialize(
  url: 'https://YOUR-PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY_HERE',
);
```

### 4. Run
```bash
flutter run
```

---

## 📱 App Flow

```
START
  ↓
SPLASH (2 sec)
  ↓
CHECK: User logged in?
  ├─ YES → HOME
  └─ NO → WELCOME
            ├─ Explore Features
            ├─ Sign In → Login form
            │            ├─ OR Forgot Password
            │            └─ New user? → Sign Up
            └─ Sign Up form → Login
```

---

## 💾 Database Schema

```
USERS (created by Supabase Auth)
├─ id (UUID)
├─ email
├─ password (hashed)
└─ user_metadata (full_name)

COURSES
├─ id (UUID)
├─ user_id (FK → users)
├─ title
├─ description
├─ content (JSONB)
├─ is_published
├─ created_at
└─ updated_at

ENROLLMENTS
├─ id (UUID)
├─ user_id (FK → users)
├─ course_id (FK → courses)
├─ enrolled_at
└─ progress (0-100)
```

---

## 🛠️ Code Snippets

### Authenticate User
```dart
import 'package:studynova/services/auth_service.dart';

final auth = AuthService();

// Sign up
await auth.signUp(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'John Doe',
);

// Sign in
await auth.signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

### Get/Create Courses
```dart
import 'package:studynova/services/course_service.dart';

final courses = CourseService();

// Get all courses
List<Map> myCourses = await courses.getUserCourses();

// Create course
await courses.createCourse(
  title: 'Flutter Basics',
  description: 'Learn Flutter',
  content: {'modules': []},
);

// Real-time updates
courses.streamUserCourses().listen((data) {
  print('Updated: $data');
});
```

### Create Courses Table (SQL)
```sql
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  content JSONB DEFAULT '{}',
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their courses" ON courses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their courses" ON courses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their courses" ON courses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their courses" ON courses
  FOR DELETE USING (auth.uid() = user_id);
```

---

## 📂 File Structure
```
lib/
├── main.dart                    ← START HERE
├── screen/splash/
│   └── splash.screen.dart       ← 2 sec loading
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    ← Sign in
│   │   └── signup_screen.dart   ← Sign up
│   ├── home/
│   │   └── home_screen.dart     ← Dashboard
│   └── welcome/
│       ├── welcome_screen.dart  ← Intro
│       └── features_screen.dart ← Features
└── services/
    ├── auth_service.dart        ← Auth logic
    └── course_service.dart      ← DB operations
```

---

## 🧪 Test Checklist

- [ ] App runs without errors
- [ ] Splash screen shows for 2 seconds
- [ ] Welcome screen appears
- [ ] "Explore Features" button works
- [ ] "Sign In" button works
- [ ] Sign up form accepts email
- [ ] Password validation works (min 6 chars)
- [ ] Can't login without credentials
- [ ] Error messages appear on failure
- [ ] Check Supabase → Users sees test account
- [ ] Home screen shows after login
- [ ] Logout button works

---

## 🔑 Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `AuthService` | `services/auth_service.dart` | User authentication |
| `CourseService` | `services/course_service.dart` | Database CRUD |
| `SplashScreen` | `screen/splash/splash.screen.dart` | Loading screen |
| `WelcomeScreen` | `screens/welcome/welcome_screen.dart` | App introduction |
| `LoginScreen` | `screens/auth/login_screen.dart` | User login |
| `SignupScreen` | `screens/auth/signup_screen.dart` | User registration |
| `HomeScreen` | `screens/home/home_screen.dart` | Main dashboard |
| `FeaturesScreen` | `screens/welcome/features_screen.dart` | Feature overview |

---

## ⚠️ Errors & Fixes

| Error | Fix |
|-------|-----|
| `White screen` | Check Supabase URL/key in main.dart |
| `Auth failing` | Enable Email provider in Supabase Auth |
| `Widget not found` | Run `flutter pub get` again |
| `Image not showing` | Place `study_nova.png` in `assets/images/` |
| `Connection timeout` | Check internet & Supabase project status |

---

## 📚 Documentation

| Doc | When to Read |
|-----|--------------|
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Setting up Supabase |
| [README_IMPLEMENTATION.md](README_IMPLEMENTATION.md) | Understanding structure |
| [EXAMPLES_DATABASE_INTEGRATION.dart](EXAMPLES_DATABASE_INTEGRATION.dart) | Code examples |
| [IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md) | Full overview |

---

## 🎯 What's Done

✅ Authentication (Email/Password)
✅ Splash Screen (2 sec)
✅ Welcome Screen
✅ Features Screen
✅ Login Screen
✅ Signup Screen
✅ Home Dashboard
✅ Auth Service
✅ Course Service (CRUD)
✅ Real-time Database Support
✅ Error Handling
✅ Supabase Integration
✅ Row Level Security Ready

---

## 🚶 Next Steps

1. Add Supabase credentials to main.dart
2. Create database tables (use SQL from this guide)
3. Test sign up/login flow
4. Build course creation screen
5. Add AI integration
6. Deploy to App Store/Play Store

---

## 🆘 Need Help?

1. Check error messages carefully
2. Read [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
3. Check Supabase dashboard logs
4. Review code in EXAMPLES_DATABASE_INTEGRATION.dart
5. Verify database tables exist
6. Check auth session is valid

---

## 📞 Resources

- Flutter Docs: https://flutter.dev
- Supabase Docs: https://supabase.com/docs
- Supabase Flutter: https://supabase.com/docs/reference/dart/
- Dart Docs: https://dart.dev/guides

---

**Good luck! 🚀 Your StudyNova app is ready to launch!**
