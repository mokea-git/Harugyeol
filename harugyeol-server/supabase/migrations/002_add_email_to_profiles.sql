-- ============================================================
-- profiles 테이블에 email 추가 + 트리거 업데이트
-- Supabase SQL Editor에서 실행하세요.
-- ============================================================

-- email 컬럼 추가
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT;

-- 트리거 함수 업데이트: email + ON CONFLICT upsert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname, avatar_url, email)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      '하루결 사용자'
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture'
    ),
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE SET
    nickname   = COALESCE(EXCLUDED.nickname,   public.profiles.nickname),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
    email      = COALESCE(EXCLUDED.email,      public.profiles.email),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
