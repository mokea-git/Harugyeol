import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseAuthKey =
  process.env.SUPABASE_ANON_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseAuthKey) {
  throw new Error('SUPABASE_URL and one of SUPABASE_ANON_KEY/SUPABASE_SERVICE_ROLE_KEY must be set');
}

// OAuth 토큰 검증 전용 클라이언트
export const supabaseAdmin = createClient(supabaseUrl, supabaseAuthKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// JWT 토큰으로 사용자 검증
export async function getUserFromToken(token: string) {
  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}
