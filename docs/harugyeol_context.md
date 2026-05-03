# 하루결 (Harugyeol) — 프로젝트 컨텍스트

> Claude Code에 전달하는 전체 프로젝트 설계 문서입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | 하루결 (Harugyeol) |
| 슬로건 | 오늘 하루의 결을 읽어드립니다 |
| 부제 | 쓰면 알아서 분석되는 일기 |
| 카테고리 | AI 일기 + 습관 트래커 + AI 코치 |
| 타겟 | 한국 MZ, 자기계발 관심, 감정 정리 원하는 일반 소비자 (B2C) |
| 수익 목표 | 2026년 월 100만원 (구독자 205명 × 4,900원) |

---

## 2. 핵심 컨셉

**"일기를 쓰면 AI가 알아서 분석한다"**

- 사용자는 자유롭게 일기만 씀
- AI가 감정 태그 자동 추출
- AI가 습관 키워드 자동 감지 (운동, 수면, 독서 등) → 별도 입력 없이 트래킹
- 주간 리포트 자동 생성 (매주 월요일)
- AI 코치와 1:1 대화 가능

---

## 3. 기술 스택

### 앱 (프론트엔드)

| 역할 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | React Native (Expo SDK 51+) | RN 선택, Expo로 빠른 시작 |
| 언어 | TypeScript | 익숙한 환경 |
| 네비게이션 | Expo Router | Next.js App Router와 구조 동일 |
| 스타일 | NativeWind | Tailwind 문법 그대로 RN에서 사용 |
| 상태관리 | Zustand | 가볍고 단순 |
| 결제 | RevenueCat | 인앱결제 (Apple/Google) 필수 대응 |

### 백엔드 (맥미니 셀프호스팅)

| 역할 | 선택 | 이유 |
|------|------|------|
| API 서버 | Fastify (Node.js) | 가볍고 빠름, TypeScript 지원 |
| DB | PostgreSQL | 안정적, Supabase도 내부는 Postgres |
| Auth | 자체 JWT + bcrypt | 외부 의존 없음 |
| 리버스 프록시 | Nginx | SSL 종료 + 라우팅 |
| SSL | Let's Encrypt | 무료 자동갱신 |
| 프로세스 관리 | PM2 | 서버 다운 시 자동 재시작 |
| 스케줄러 | node-cron | 주간 리포트 자동 발송 |
| 이메일 | Resend | 무료 3,000건/월 |

### 클라우드 (최소한만)

| 역할 | 선택 |
|------|------|
| 앱 빌드 | EAS Build (Expo) |
| 이메일 발송 | Resend |
| 결제 관리 | RevenueCat |

### AI

| 항목 | 내용 |
|------|------|
| 모델 | Claude Haiku (claude-haiku-4-5) |
| 용도 | 감정 분석, 습관 추출, AI 코치 대화 |
| 호출 방식 | 앱 → 맥미니 Fastify API → Claude API (키는 서버에만 보관) |
| 비용 | 사용자 1인당 월 약 120원 (마진 97.5%) |

---

## 4. DB 스키마 (핵심 테이블)

```sql
-- 사용자
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  plan TEXT DEFAULT 'free', -- 'free' | 'pro'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 일기
CREATE TABLE journals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI 분석 결과
CREATE TABLE analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_id UUID REFERENCES journals(id) ON DELETE CASCADE,
  emotions TEXT[] NOT NULL,       -- 감정 태그 배열
  habits TEXT[] NOT NULL,         -- 습관 키워드 배열
  feedback TEXT NOT NULL,         -- AI 한 줄 피드백
  summary TEXT,                   -- 주간 리포트용 요약
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 구독
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rc_customer_id TEXT,            -- RevenueCat customer ID
  status TEXT DEFAULT 'inactive', -- 'active' | 'inactive' | 'expired'
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI 코치 대화
CREATE TABLE coach_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,             -- 'user' | 'assistant'
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. API 엔드포인트 설계

### Auth
```
POST /auth/register        회원가입
POST /auth/login           로그인 → JWT 반환
POST /auth/refresh         토큰 갱신
```

### 일기
```
POST   /journals           일기 작성 → 자동으로 AI 분석 트리거
GET    /journals           목록 조회 (날짜순)
GET    /journals/:id       단건 조회
DELETE /journals/:id       삭제
```

### 분석
```
GET /analyses/:journalId   특정 일기의 분석 결과
GET /analyses/weekly       주간 리포트 데이터
```

### AI 코치
```
POST /coach/message        메시지 전송 → Claude Haiku 응답
GET  /coach/history        대화 기록 조회
```

### 구독
```
POST /subscriptions/webhook   RevenueCat 웹훅 수신
GET  /subscriptions/status    현재 구독 상태
```

---

## 6. Claude Haiku 프롬프트 설계 (초안)

### 일기 분석 프롬프트
```
당신은 공감 능력이 뛰어난 AI 일기 분석가입니다.
아래 일기를 읽고 JSON으로만 응답하세요.

일기:
{journal_content}

응답 형식:
{
  "emotions": ["감정1", "감정2", "감정3"],  // 최대 3개, 2글자 이상 한국어
  "habits": ["습관1", "습관2"],              // 일기에서 발견된 습관 키워드
  "feedback": "한 줄 공감 피드백 (50자 이내)"
}

규칙:
- emotions는 일기에서 실제로 느껴지는 감정만
- habits는 운동, 수면, 독서, 식사, 공부 등 반복 가능한 행동만
- feedback은 판단 없이 공감하는 톤으로
- 반드시 JSON만 반환, 다른 텍스트 없음
```

### AI 코치 시스템 프롬프트
```
당신은 하루결 앱의 AI 코치입니다.
사용자의 일기와 감정 패턴을 바탕으로 따뜻하게 대화합니다.

역할:
- 판단하지 않고 공감하며 듣기
- 사용자가 스스로 생각할 수 있도록 질문하기
- 감정 패턴에 대한 인사이트 제공
- 다음 한 걸음을 함께 생각하기

톤: 친근하지만 전문적, 짧고 명확하게, 한국어

사용자의 최근 감정 패턴: {emotion_summary}
```

---

## 7. MVP 기능 범위 (4주)

### Week 1 — 기반 세팅
- [ ] Expo 프로젝트 생성 (TypeScript + Expo Router + NativeWind)
- [ ] Fastify 서버 세팅 (TypeScript)
- [ ] PostgreSQL 연결 (pg 또는 drizzle-orm)
- [ ] JWT 인증 (회원가입 / 로그인)
- [ ] 일기 CRUD API + 앱 화면

### Week 2 — AI 연동
- [ ] Claude Haiku API 연동
- [ ] 일기 저장 시 자동 분석 트리거
- [ ] 감정 태그 + 한 줄 피드백 화면 표시
- [ ] 분석 결과 DB 저장

### Week 3 — 습관 트래킹 + AI 코치
- [ ] 습관 키워드 캘린더 마킹
- [ ] 습관 히트맵 화면
- [ ] AI 코치 대화 화면 (채팅 UI)
- [ ] 대화 기록 저장 + 불러오기

### Week 4 — 수익화 + 출시
- [ ] 주간 리포트 생성 (node-cron)
- [ ] Resend 이메일 발송
- [ ] RevenueCat 인앱결제 연동
- [ ] 무료(7일) / 유료 플랜 분기 처리
- [ ] 구글플레이 베타 출시

### MVP 제외 (v2)
- 푸시 알림
- 소셜 로그인
- 커스텀 습관 카테고리
- 다크모드
- iOS 출시 (Apple Developer 계정 $99/년 필요)

---

## 8. 수익 구조

| 항목 | 내용 |
|------|------|
| 무료 티어 | 7일 체험 |
| 월 구독 | 4,900원/월 |
| 연 구독 | 39,000원/년 (월 3,250원 환산) |
| 목표 구독자 | 205명 |
| 월 API 비용 | ~25,000원 (205명 × 120원) |
| 인앱결제 수수료 | 30% (Apple/Google) → 실수령 약 70만원 |

---

## 9. 브랜드 아이덴티티

| 항목 | 내용 |
|------|------|
| 앱 이름 | 하루결 |
| 영문명 | Harugyeol |
| 슬로건 | 오늘 하루의 결을 읽어드립니다 |
| 메인 컬러 | `#659b5e` (액션 버튼, 로고) |
| 보조 컬러 | `#556f44` (보조 텍스트, 태그) |
| 다크 베이스 | `#283f3b` (AI 코치 말풍선, 다크 요소) |
| 배경 | `#F7F6F2` (따뜻한 오프화이트) |
| 앱스토어 부제 | 쓰면 알아서 분석되는 일기장 |
| 검색 키워드 | 일기, 다이어리, 감정일기, AI일기, 습관트래커, 자기계발, 마음챙김 |

---

## 10. 인프라

- 맥미니 (도메인 연결, 외부 접근 가능) → Fastify + PostgreSQL + Nginx + PM2
- Let's Encrypt SSL 자동갱신
- EAS Build → 구글플레이 배포
- DDNS 확인 필요 (ISP IP 변동 대비)

---

## 11. Claude Code 시작 명령 제안

```bash
# 앱
npx create-expo-app harugyeol --template blank-typescript
cd harugyeol
npx expo install expo-router nativewind tailwindcss zustand

# 백엔드
mkdir harugyeol-server && cd harugyeol-server
npm init -y
npm install fastify @fastify/jwt @fastify/cors pg drizzle-orm dotenv
npm install -D typescript ts-node @types/node drizzle-kit
```

---

*이 문서는 Claude와의 대화를 기반으로 자동 생성되었습니다.*
*생성일: 2026-05-03*
