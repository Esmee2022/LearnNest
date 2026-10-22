import { createClient, type SupabaseClient } from '@supabase/supabase-js';
let client: SupabaseClient | undefined;
export function db() {
  if (!client) {
    const url = process.env.SUPABASE_URL; const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new Error('Supabase is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.');
    client = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  }
  return client;
}
export function checked<T>(result: {data:T|null;error:{message:string}|null}): T {
  if (result.error) throw new Error(result.error.message);
  if (result.data === null) throw new Error('Expected a database result');
  return result.data;
}
