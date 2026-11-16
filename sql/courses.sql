-- Create courses table for saved courses
CREATE TABLE IF NOT EXISTS public.courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  course_type TEXT NOT NULL DEFAULT 'general_learning',
  class_level TEXT,
  subject TEXT,
  exam_target TEXT,
  length TEXT NOT NULL DEFAULT 'medium',
  difficulty TEXT NOT NULL DEFAULT 'beginner',
  language TEXT NOT NULL DEFAULT 'english',
  learning_goal TEXT,
  content JSONB NOT NULL DEFAULT '{}',
  chapter_count INT NOT NULL DEFAULT 0,
  topic_count INT NOT NULL DEFAULT 0,
  progress INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT false,
  cover_image TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_studied_at TIMESTAMPTZ
);

-- Enable row level security on courses table
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- Trigger to auto-set updated_at on insert
CREATE OR REPLACE FUNCTION public.handle_courses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_courses_updated_at
BEFORE UPDATE ON public.courses
FOR EACH ROW EXECUTE FUNCTION public.handle_courses_updated_at();

-- Create policy: Users can create their own courses
DROP POLICY IF EXISTS "Users can create their own courses" ON public.courses;
CREATE POLICY "Users can create their own courses"
ON public.courses
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can read their own courses
DROP POLICY IF EXISTS "Users can read their own courses" ON public.courses;
CREATE POLICY "Users can read their own courses"
ON public.courses
FOR SELECT
USING (auth.uid() = user_id);

-- Create policy: Users can update their own courses
DROP POLICY IF EXISTS "Users can update their own courses" ON public.courses;
CREATE POLICY "Users can update their own courses"
ON public.courses
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can delete their own courses
DROP POLICY IF EXISTS "Users can delete their own courses" ON public.courses;
CREATE POLICY "Users can delete their own courses"
ON public.courses
FOR DELETE
USING (auth.uid() = user_id);