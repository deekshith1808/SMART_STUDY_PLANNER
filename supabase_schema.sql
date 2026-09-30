-- ==============================================================================
-- SMART STUDY PLANNER - SUPABASE DATABASE SCHEMA
-- Run this script in your Supabase SQL Editor:
-- Supabase Dashboard > SQL Editor > New Query > Paste & Run
-- ==============================================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  education_type TEXT NOT NULL DEFAULT 'school',
  branch TEXT,
  course TEXT,
  subjects JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view and manage their own profile"
  ON public.profiles
  FOR ALL
  USING (auth.uid() = id);

-- 2. STUDY SESSIONS TABLE (Pomodoro & Focus Logs)
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id TEXT NOT NULL,
  subject_name TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 25,
  session_type TEXT DEFAULT 'pomodoro'
);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own study sessions"
  ON public.study_sessions
  FOR ALL
  USING (auth.uid() = user_id);

-- 3. SCHEDULED TASKS TABLE (Timetable & Tasks)
CREATE TABLE IF NOT EXISTS public.scheduled_tasks (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  subject_id TEXT NOT NULL,
  subject_name TEXT NOT NULL,
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  start_time TEXT DEFAULT '09:00',
  end_time TEXT DEFAULT '10:00',
  is_completed BOOLEAN DEFAULT FALSE,
  priority TEXT DEFAULT 'medium',
  description TEXT
);

ALTER TABLE public.scheduled_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own scheduled tasks"
  ON public.scheduled_tasks
  FOR ALL
  USING (auth.uid() = user_id);

-- 4. QUICK NOTES TABLE (Sticky Craft Paper Notes)
CREATE TABLE IF NOT EXISTS public.quick_notes (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  subject_id TEXT NOT NULL,
  subject_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.quick_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own notes"
  ON public.quick_notes
  FOR ALL
  USING (auth.uid() = user_id);

-- 5. DUOLINGO LEARNING JOURNEY & EXAM HURDLE TABLE
CREATE TABLE IF NOT EXISTS public.journey_progress (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 1,
  last_study_date TIMESTAMP WITH TIME ZONE,
  has_streak_shield BOOLEAN DEFAULT TRUE,
  nodes_json JSONB DEFAULT '[]'::jsonb,
  hurdle_json JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.journey_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own learning journey progress"
  ON public.journey_progress
  FOR ALL
  USING (auth.uid() = user_id);

-- Auto profile creation trigger when a user signs up (Optional helper)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, education_type, subjects)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'school',
    '[]'::jsonb
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
