-- Create study_scans table
create table if not exists public.study_scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  topic text not null,
  subject text not null default 'General',
  image_url text,
  explanation text not null default '',
  key_points text[] default array[]::text[],
  mind_map_data jsonb default '{}'::jsonb,
  quiz_data jsonb default '[]'::jsonb,
  explanation_level text default 'normal',
  important_concepts text[] default array[]::text[],
  common_mistakes text[] default array[]::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Create index on user_id for faster queries
create index if not exists idx_study_scans_user_id on public.study_scans(user_id);
create index if not exists idx_study_scans_created_at on public.study_scans(created_at desc);
create index if not exists idx_study_scans_subject on public.study_scans(subject);

-- Enable Row Level Security
alter table public.study_scans enable row level security;

-- Create function to update updated_at timestamp
create or replace function public.handle_study_scans_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Drop existing trigger if it exists
drop trigger if exists set_study_scans_updated_at on public.study_scans;

-- Create trigger for updated_at
create trigger set_study_scans_updated_at
before update on public.study_scans
for each row execute function public.handle_study_scans_updated_at();

-- Row Level Security Policies

-- Policy 1: Users can create their own study scans
drop policy if exists "Users can create their own study scans" on public.study_scans;
create policy "Users can create their own study scans"
on public.study_scans
for insert
with check (auth.uid() = user_id);

-- Policy 2: Users can read their own study scans
drop policy if exists "Users can read their own study scans" on public.study_scans;
create policy "Users can read their own study scans"
on public.study_scans
for select
using (auth.uid() = user_id);

-- Policy 3: Users can update their own study scans
drop policy if exists "Users can update their own study scans" on public.study_scans;
create policy "Users can update their own study scans"
on public.study_scans
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Policy 4: Users can delete their own study scans
drop policy if exists "Users can delete their own study scans" on public.study_scans;
create policy "Users can delete their own study scans"
on public.study_scans
for delete
using (auth.uid() = user_id);
