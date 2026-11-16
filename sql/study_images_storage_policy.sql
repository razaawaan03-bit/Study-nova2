-- Supabase Storage Policies for study_images bucket
-- This configuration should be applied in your Supabase dashboard

-- IMPORTANT: Manually create the storage bucket named "study_images" in the Supabase dashboard
-- Storage > Buckets > Create a new bucket > Name: "study_images" > Uncheck "Public bucket"

-- Then run the SQL commands below in the SQL Editor:

-- Enable RLS on storage.objects (if not already enabled globally)
-- This should already be enabled by Supabase by default

-- Policy 1: Allow users to upload images to their own folder
drop policy if exists "Users can upload study images" on storage.objects;
create policy "Users can upload study images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'study_images' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow users to read their own images
drop policy if exists "Users can read their own study images" on storage.objects;
create policy "Users can read their own study images"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'study_images' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow users to update their own images
drop policy if exists "Users can update their own study images" on storage.objects;
create policy "Users can update their own study images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'study_images' and
  (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'study_images' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own images
drop policy if exists "Users can delete their own study images" on storage.objects;
create policy "Users can delete their own study images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'study_images' and
  (storage.foldername(name))[1] = auth.uid()::text
);

-- NOTES:
-- 1. The bucket must be named "study_images"
-- 2. Users can only access images in their own folder (user_id/...)
-- 3. Make sure the bucket exists before applying these policies
-- 4. To create the bucket if it doesn't exist, go to Supabase Dashboard > Storage > Create new bucket
