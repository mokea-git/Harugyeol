-- ============================================================
-- 하루결 (Harugyeol) — Supabase 초기 스키마
-- Supabase SQL Editor에서 순서대로 실행하세요.
-- ============================================================

-- ── 1. users 프로필 테이블 ────────────────────────────────────
-- auth.users는 Supabase가 자동 관리, 우리 앱 데이터는 별도 저장
CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname   TEXT,
  avatar_url TEXT,
  plan       TEXT NOT NULL DEFAULT 'free',   -- 'free' | 'pro'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 신규 유저 가입 시 프로필 자동 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nickname, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', '하루결 사용자'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── 2. journals 테이블 ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journals (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  date       DATE NOT NULL,
  mood_emoji TEXT,                           -- 사용자가 선택한 이모지
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, date)                     -- 하루 한 개
);

-- ── 3. analyses 테이블 ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.analyses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id  UUID NOT NULL REFERENCES public.journals(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emotions    TEXT[] NOT NULL DEFAULT '{}',
  habits      TEXT[] NOT NULL DEFAULT '{}',
  feedback    TEXT NOT NULL DEFAULT '',
  summary     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 4. coach_messages 테이블 ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.coach_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 5. subscriptions 테이블 ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rc_customer_id TEXT,                        -- RevenueCat customer ID
  status        TEXT NOT NULL DEFAULT 'inactive', -- 'active' | 'inactive' | 'cancelled'
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

-- ============================================================
-- Row Level Security (RLS) 설정
-- 반드시 활성화해야 다른 유저 데이터 보호됩니다.
-- ============================================================

ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coach_messages  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions   ENABLE ROW LEVEL SECURITY;

-- profiles RLS
CREATE POLICY "본인 프로필만 조회" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "본인 프로필만 수정" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- journals RLS
CREATE POLICY "본인 일기만 조회" ON public.journals
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "본인 일기만 작성" ON public.journals
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "본인 일기만 수정" ON public.journals
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "본인 일기만 삭제" ON public.journals
  FOR DELETE USING (auth.uid() = user_id);

-- analyses RLS (Flutter 직접 조회용)
CREATE POLICY "본인 분석만 조회" ON public.analyses
  FOR SELECT USING (auth.uid() = user_id);
-- INSERT/UPDATE는 service_role(서버)만 가능 (정책 없으면 anon 차단됨)

-- coach_messages RLS (Flutter 직접 조회용)
CREATE POLICY "본인 대화만 조회" ON public.coach_messages
  FOR SELECT USING (auth.uid() = user_id);

-- subscriptions RLS
CREATE POLICY "본인 구독만 조회" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- 인덱스 (성능 최적화)
-- ============================================================
CREATE INDEX IF NOT EXISTS journals_user_date_idx ON public.journals (user_id, date DESC);
CREATE INDEX IF NOT EXISTS analyses_journal_idx   ON public.analyses (journal_id);
CREATE INDEX IF NOT EXISTS analyses_user_idx      ON public.analyses (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS coach_user_idx         ON public.coach_messages (user_id, created_at DESC);
