# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 프로젝트 개요

**하루결 (Harugyeol)** — AI 일기 + 습관 트래커 + AI 코치 앱
- 사용자가 일기를 쓰면 Claude Haiku가 감정 태그·습관 키워드 자동 추출, 한 줄 피드백 제공
- 주간 리포트 자동 생성 (매주 월요일 node-cron + Resend 이메일)
- AI 코치 1:1 채팅 (사용자의 감정 패턴 컨텍스트 포함)
- 타겟: 한국 MZ / 수익 모델: 무료 7일 체험 → 월 4,900원 구독

전체 설계 문서: [`docs/harugyeol_context.md`](docs/harugyeol_context.md)

---

## 모노레포 구조

```
Harugyeol/
├── harugyeol/          # Flutter 앱
└── harugyeol-server/   # Fastify 백엔드 서버
```

---

## 앱 (`harugyeol/`)

**스택**: Flutter · Dart · Riverpod · GoRouter · Dio · flutter_secure_storage · table_calendar · RevenueCat

### 개발 명령어

```bash
flutter run                     # 개발 실행
flutter run --release           # 릴리즈 빌드 테스트
flutter build apk --release     # APK 빌드
flutter build appbundle         # 구글플레이 제출용
```

### 앱 구조

```
lib/
├── main.dart / app.dart          # 진입점 + GoRouter
├── core/
│   ├── constants/                # colors.dart, api.dart
│   ├── network/dio_client.dart   # JWT 인터셉터
│   └── storage/secure_storage.dart
├── features/
│   ├── auth/                     # 로그인·회원가입
│   ├── journal/                  # 일기 목록·작성
│   ├── analysis/                 # AI 분석 결과
│   ├── coach/                    # AI 코치 채팅
│   └── subscription/             # RevenueCat 플랜
└── shared/themes/app_theme.dart
```

### 브랜드 컬러

| 용도 | 값 |
|------|----|
| 액션 버튼 / 로고 | `#659b5e` |
| 보조 텍스트 / 태그 | `#556f44` |
| AI 코치 말풍선 | `#283f3b` |
| 배경 | `#F7F6F2` |

---

## 백엔드 (`harugyeol-server/`)

**스택**: Fastify · TypeScript · PostgreSQL · drizzle-orm · JWT/bcrypt · PM2 · Nginx · node-cron · Resend · Claude Haiku API

### 개발 명령어

```bash
npm run dev         # ts-node로 개발 서버 (ts-node src/index.ts)
npm run build       # tsc 컴파일
npm run start       # 컴파일된 JS 실행 (PM2 환경)
npm run db:generate # drizzle-kit generate (마이그레이션 생성)
npm run db:migrate  # drizzle-kit migrate (마이그레이션 적용)
```

### 핵심 API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/auth/register` | 회원가입 |
| POST | `/auth/login` | 로그인 → JWT |
| POST | `/journals` | 일기 저장 → AI 분석 자동 트리거 |
| GET | `/journals` | 목록 조회 |
| GET | `/analyses/:journalId` | 분석 결과 조회 |
| GET | `/analyses/weekly` | 주간 리포트 데이터 |
| POST | `/coach/message` | AI 코치 대화 |
| POST | `/subscriptions/webhook` | RevenueCat 웹훅 |

### Claude Haiku 호출 방식

- **모델**: `claude-haiku-4-5-20251001`
- API 키는 서버에만 보관 (`ANTHROPIC_API_KEY` 환경변수), 앱에 노출 금지
- 호출 흐름: `앱 → Fastify API → Claude API`
- 프롬프트 구조: `docs/harugyeol_context.md` 6번 섹션 참고
- 분석 결과는 반드시 JSON만 반환하도록 프롬프트 구성

### DB 스키마 (핵심 테이블)

`users`, `journals`, `analyses`, `subscriptions`, `coach_messages`  
상세 DDL: `docs/harugyeol_context.md` 4번 섹션 참고

---

## 인프라

- **서버**: 맥미니 셀프호스팅 — Fastify + PostgreSQL + Nginx(SSL 종료) + PM2
- **SSL**: Let's Encrypt (자동갱신)
- **스케줄러**: node-cron (매주 월요일 주간 리포트)
- **이메일**: Resend (무료 3,000건/월)

---

## 플랜 분기 (Free vs Pro)

- 무료: 7일 체험
- Pro: RevenueCat 웹훅 → `subscriptions.status = 'active'`로 업데이트
- 플랜 체크는 반드시 서버 사이드에서 `subscriptions` 테이블 기준으로 수행
