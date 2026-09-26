# 하루결 (Harugyeol)

> 오늘 하루의 결을 읽어드립니다 — AI 일기 + 습관 트래커 + AI 코치 앱

## 프로젝트 구조

```
Harugyeol/
├── haru_app/           # Flutter 앱 (iOS / Android)
├── harugyeol-server/   # Fastify 백엔드 API
├── docs/               # 설계 문서
└── assets/             # 공유 디자인 에셋
```

## 빠른 시작

### Flutter 앱
```bash
cd haru_app
flutter pub get
flutter run
```

### 백엔드 서버

PostgreSQL을 먼저 준비하고 `POSTGRES_URL`을 설정하세요. [로컬 개발 안내](harugyeol-server/LOCAL_DEVELOPMENT.md)를 참고하세요.

```bash
cd harugyeol-server
npm ci
npm run dev
```

## 기술 스택

| 영역 | 스택 |
|------|------|
| 앱 | Flutter · Dart · Riverpod · GoRouter · RevenueCat |
| 백엔드 | Fastify · TypeScript · Supabase · drizzle-orm · node-cron · Resend |
| AI | Claude Haiku (`claude-haiku-4-5-20251001`) |
| 인프라 | 맥미니 셀프호스팅 · Nginx · PM2 · Let's Encrypt |
