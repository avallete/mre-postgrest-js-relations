import type { Database } from "./database.types";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient<Database>('http://127.0.0.1:54321','eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU');

async function first() {
    // all is good with direct "foreign key" hinting
    const { data, error } = (await supabase
        .from("shared_files")
        .select(`
            file_id,
            shared_by,
            file:files!shared_files_file_id_fkey(id, name, size, type, created_at, path, owner_id),
            shared_by_user:user_share_info!shared_files_shared_by_fkey(id, name, email, avatar_url)
        `)
        .eq("shared_with", 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9'))
    console.log('error: ', error)
    console.log('data: ', data)
    console.log(data![0].file?.name)
    console.log(data![0].shared_by_user?.name)
    // The error happen when using the column name alias, here the runtime result is the same
    const { data: data2, error: error2 } = (await supabase
        .from("shared_files")
        .select(`
            file_id,
            shared_by,
            file:files!file_id(id, name, size, type, created_at, path, owner_id),
            shared_by_user:user_share_info!shared_by(id, name, email, avatar_url)
        `)
        .eq("shared_with", 'f5b8c2a1-e8d4-4f67-8b6a-95e3f220f5c9'))
    console.log('error2: ', error2)
    console.log('data2: ', data2)
    // This should not raise error, but it does
    console.log(data2![0].file?.name)
    console.log(data2![0].shared_by_user?.name)
}

async function second() {
    // all is good with direct "foreign key" hinting
    const { data, error } = (await supabase
        .from("files")
        .select(`
            *,
            shared_with_users:shared_files(
                user:user_share_info!shared_files_shared_by_fkey(id, email, name, avatar_url)
            )
        `)
        .eq("owner_id", 'd7bed83c-bf93-4f34-9c2a-83e2776ef661')
        .order("created_at", { ascending: false })) 
    console.log('error: ', error)
    console.log('data: ', data)
    console.log(data![0].shared_with_users[0].user?.name)
    // Error happen when using the column name alias, here the runtime result is the same
    // but the type inference yield an array for "shared_with_users.user"
    const { data: data2, error: error2 } = (await supabase
        .from("files")
        .select(`
            *,
            shared_with_users:shared_files(
                user:user_share_info!shared_with(id, email, name, avatar_url)
            )
        `)
        .eq("owner_id", 'd7bed83c-bf93-4f34-9c2a-83e2776ef661')
        .order("created_at", { ascending: false })) 
    console.log('error2: ', error2)
    console.log('data2: ', data2)
    // This should not raise error, but it does
    console.log(data2![0].shared_with_users[0].user?.name)
}

console.log('--------------------------------- first')
await first()
console.log('--------------------------------- second')
await second()