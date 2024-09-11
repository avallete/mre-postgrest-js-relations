-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS moddatetime;

-- Files table
CREATE TABLE files (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  size BIGINT NOT NULL,
  type TEXT,
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  path TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Shared files table
CREATE TABLE shared_files (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  file_id BIGINT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  shared_by UUID NOT NULL REFERENCES auth.users(id),
  shared_with UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for faster queries
CREATE INDEX idx_files_owner ON files(owner_id);
CREATE INDEX idx_shared_files_shared_with ON shared_files(shared_with);

-- Add triggers for updating the updated_at column
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON files
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON shared_files
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

-- Enable Row Level Security
ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_files ENABLE ROW LEVEL SECURITY;

-- Policies for files table
CREATE POLICY "Users can view their own files"
  ON files FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert their own files"
  ON files FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own files"
  ON files FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own files"
  ON files FOR DELETE
  USING (auth.uid() = owner_id);

-- Policies for shared_files table
CREATE POLICY "Users can view files shared with them"
  ON shared_files FOR SELECT
  USING (auth.uid() = shared_with);

CREATE POLICY "Users can see files shared with them or by them" ON shared_files
FOR SELECT
USING (
  auth.uid() = shared_with OR
  auth.uid() = shared_by
);

CREATE POLICY "Users can share their own files"
  ON shared_files FOR INSERT
  WITH CHECK (auth.uid() = (SELECT owner_id FROM files WHERE id = file_id));

CREATE POLICY "File owners can update sharing"
  ON shared_files FOR UPDATE
  USING (auth.uid() = (SELECT owner_id FROM files WHERE id = file_id));

CREATE POLICY "File owners can revoke sharing"
  ON shared_files FOR DELETE
  USING (auth.uid() = (SELECT owner_id FROM files WHERE id = file_id));

-- Policy to allow users to view files shared with them
CREATE POLICY "Users can view shared files"
  ON files FOR SELECT
  USING (
    EXISTS (
      SELECT 1 
      FROM shared_files 
      WHERE shared_files.file_id = files.id 
      AND shared_files.shared_with = auth.uid()
    )
  );

-- Create a function to check if a file is shared with the current user
CREATE OR REPLACE FUNCTION public.is_file_shared_with_user(file_path TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  target_file_id BIGINT;
BEGIN
  -- Get the file_id from the files table based on the file path
  SELECT id INTO target_file_id FROM files WHERE path = file_path;
  
  -- Check if the file is shared with the current user
  RETURN EXISTS (
    SELECT 1
    FROM shared_files
    WHERE file_id = target_file_id
      AND shared_with = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY "Users can read their own and shared files" ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'files' 
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR 
    is_file_shared_with_user(name)
  )
);

-- Allow users to upload files
CREATE POLICY "Users can upload files" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'files' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to update their own files
CREATE POLICY "Users can update their own files" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'files' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own files
CREATE POLICY "Users can delete their own files" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'files' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create a custom view with limited user information
CREATE OR REPLACE VIEW public.user_share_info AS
SELECT id, email, COALESCE(raw_user_meta_data->>'full_name', email) AS name, raw_user_meta_data->>'avatar_url' AS avatar_url
FROM auth.users;

-- Add the files table to the realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE shared_files;