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
| 프레임워크 | **Flutter** | 경험 있음, UI 완성도 높음, 세팅 빠름 |
| 언어 | **Dart** | Flutter 기본 언어 |
| 상태관리 | **Riverpod** | Flutter 생태계 표준, 타입 안전 |
| 네비게이션 | **GoRouter** | 선언형, 딥링크 지원 |
| HTTP | **Dio** | 인터셉터, 에러 핸들링 편함 |
| 로컬 저장 | **flutter_secure_storage** | JWT 토큰 안전 보관 |
| 결제 | **RevenueCat (purchases_flutter)** | 인앱결제 Apple/Google 대응 |
| 달력 | **table_calendar** | 습관 히트맵용 |

### 백엔드 (맥미니 셀프호스팅)

| 역할 | 선택 | 이유 |
|------|------|------|
| API 서버 | Fastify (Node.js + TypeScript) | 가볍고 빠름 |
| DB | PostgreSQL | 안정적 |
| Auth | 자체 JWT + bcrypt | 외부 의존 없음 |
| 리버스 프록시 | Nginx | SSL 종료 + 라우팅 |
| SSL | Let's Encrypt | 무료 자동갱신 |
| 프로세스 관리 | PM2 | 서버 다운 시 자동 재시작 |
| 스케줄러 | node-cron | 주간 리포트 자동 발송 |
| 이메일 | Resend | 무료 3,000건/월 |

### 클라우드 (최소한만)

| 역할 | 선택 |
|------|------|
| 앱 빌드/배포 | GitHub Actions + Fastlane (또는 Codemagic) |
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
  plan TEXT DEFAULT 'free',
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
  emotions TEXT[] NOT NULL,
  habits TEXT[] NOT NULL,
  feedback TEXT NOT NULL,
  summary TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 구독
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rc_customer_id TEXT,
  status TEXT DEFAULT 'inactive',
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI 코치 대화
CREATE TABLE coach_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 5. API 엔드포인트 설계

```
POST /auth/register
POST /auth/login
POST /auth/refresh

POST   /journals
GET    /journals
GET    /journals/:id
DELETE /journals/:id

GET /analyses/:journalId
GET /analyses/weekly

POST /coach/message
GET  /coach/history

POST /subscriptions/webhook
GET  /subscriptions/status
```

---

## 6. Claude Haiku 프롬프트 설계

### 일기 분석
```
당신은 공감 능력이 뛰어난 AI 일기 분석가입니다.
아래 일기를 읽고 JSON으로만 응답하세요.

일기:
{journal_content}

응답 형식:
{
  "emotions": ["감정1", "감정2", "감정3"],
  "habits": ["습관1", "습관2"],
  "feedback": "한 줄 공감 피드백 (50자 이내)"
}

규칙:
- emotions는 실제로 느껴지는 감정만, 최대 3개
- habits는 운동/수면/독서/식사/공부 등 반복 가능한 행동만
- feedback은 판단 없이 공감하는 톤
- JSON만 반환, 다른 텍스트 없음
```

### AI 코치 시스템 프롬프트
```
당신은 하루결 앱의 AI 코치입니다.
사용자의 일기와 감정 패턴을 바탕으로 따뜻하게 대화합니다.

역할: 판단 없이 공감, 스스로 생각하도록 질문, 인사이트 제공
톤: 친근하지만 전문적, 짧고 명확하게, 한국어

사용자의 최근 감정 패턴: {emotion_summary}
```

---

## 7. Flutter 앱 구조

```
lib/
├── main.dart
├── app.dart                  # GoRouter 세팅
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── api.dart
│   ├── network/
│   │   └── dio_client.dart
│   └── storage/
│       └── secure_storage.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── repositories/
│   ├── journal/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── repositories/
│   ├── analysis/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── repositories/
│   ├── coach/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── repositories/
│   └── subscription/
│       ├── screens/
│       └── providers/
└── shared/
    ├── widgets/
    └── themes/
        └── app_theme.dart
```

---

## 8. 브랜드 컬러 (colors.dart)

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFF659B5E); // 메인 액션
  static const secondary  = Color(0xFF556F44); // 보조 텍스트
  static const dark       = Color(0xFF283F3B); // AI 코치 말풍선
  static const background = Color(0xFFF7F6F2); // 오프화이트
  static const surface    = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1A1A18);
  static const textSecondary = Color(0xFF6B6B67);
  static const emotionBg     = Color(0xFFE8F0E7);
}
```

---

## 9. MVP 기능 범위 (4주)

### Week 1 — 기반 세팅
- [ ] Flutter 프로젝트 생성 (Riverpod + GoRouter + Dio)
- [ ] Fastify 서버 세팅 (TypeScript + PostgreSQL)
- [ ] JWT 인증 (회원가입 / 로그인)
- [ ] 일기 작성 + 목록 화면

### Week 2 — AI 연동
- [ ] Claude Haiku API 연동 (서버사이드)
- [ ] 일기 저장 시 자동 분석 트리거
- [ ] 감정 태그 + 한 줄 피드백 화면

### Week 3 — 습관 트래킹 + AI 코치
- [ ] 습관 캘린더 (table_calendar)
- [ ] 습관 히트맵
- [ ] AI 코치 채팅 화면

### Week 4 — 수익화 + 출시
- [ ] 주간 리포트 (node-cron + Resend)
- [ ] RevenueCat 인앱결제 연동
- [ ] 무료(7일) / 유료 플랜 분기
- [ ] 구글플레이 베타 출시

### MVP 제외 (v2)
- 푸시 알림, 소셜 로그인, 커스텀 습관 카테고리, 다크모드
- iOS 출시 (Apple Developer $99/년)

---

## 10. 수익 구조

| 항목 | 내용 |
|------|------|
| 무료 티어 | 7일 체험 |
| 월 구독 | 4,900원/월 |
| 연 구독 | 39,000원/년 |
| 목표 구독자 | 205명 |
| 월 API 비용 | ~25,000원 |
| 인앱결제 수수료 | 30% → 실수령 약 70만원 |

---

## 11. 브랜드 아이덴티티

| 항목 | 내용 |
|------|------|
| 앱 이름 | 하루결 |
| 영문명 | Harugyeol |
| 슬로건 | 오늘 하루의 결을 읽어드립니다 |
| 메인 컬러 | #659b5e |
| 보조 컬러 | #556f44 |
| 다크 베이스 | #283f3b |
| 배경 | #F7F6F2 |
| 앱스토어 부제 | 쓰면 알아서 분석되는 일기장 |
| 검색 키워드 | 일기, 다이어리, 감정일기, AI일기, 습관트래커, 자기계발, 마음챙김 |

---

## 12. 인프라

- 맥미니 (도메인 + 외부접근 가능) → Fastify + PostgreSQL + Nginx + PM2
- Let's Encrypt SSL 자동갱신
- 구글플레이 베타 배포 (Android 먼저)
- iOS는 v2에서

---

## 13. Claude Code 시작 명령

```bash
# Flutter 앱
flutter create harugyeol
cd harugyeol
flutter pub add flutter_riverpod riverpod_annotation go_router dio \
  flutter_secure_storage table_calendar purchases_flutter

# 백엔드
mkdir harugyeol-server && cd harugyeol-server
npm init -y
npm install fastify @fastify/jwt @fastify/cors pg drizzle-orm dotenv node-cron resend
npm install -D typescript ts-node @types/node drizzle-kit
```

---

*생성일: 2026-05-03*
*스택: React Native (Expo) → Flutter (사용자 Flutter 경험 보유)*