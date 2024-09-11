-- Insert sample users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
VALUES
  ('d7bed83c-bf93-4f34-9c2a-83e2776ef661', 'user1@example.com', crypt('password123', gen_salt('bf')), now(), '{"full_name": "User One", "avatar_url": "https://example.com/avatars/user1.jpg"}'),
  ('f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9', 'user2@example.com', crypt('password456', gen_salt('bf')), now(), '{"full_name": "User Two", "avatar_url": "https://example.com/avatars/user2.jpg"}');

-- Insert sample files
INSERT INTO files (name, size, type, owner_id, path)
VALUES
  ('document1.pdf', 1024000, 'application/pdf', 'd7bed83c-bf93-4f34-9c2a-83e2776ef661', 'd7bed83c-bf93-4f34-9c2a-83e2776ef661/document1.pdf'),
  ('image1.jpg', 512000, 'image/jpeg', 'd7bed83c-bf93-4f34-9c2a-83e2776ef661', 'd7bed83c-bf93-4f34-9c2a-83e2776ef661/image1.jpg'),
  ('spreadsheet1.xlsx', 2048000, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9', 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9/spreadsheet1.xlsx');

-- Insert sample shared files
INSERT INTO shared_files (file_id, shared_by, shared_with)
VALUES
  (1, 'd7bed83c-bf93-4f34-9c2a-83e2776ef661', 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9'),
  (3, 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9', 'd7bed83c-bf93-4f34-9c2a-83e2776ef661');