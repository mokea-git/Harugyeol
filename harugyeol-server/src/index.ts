import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { analysesRoutes } from './routes/analyses';
import { coachRoutes } from './routes/coach';
import { journalsRoutes } from './routes/journals';
import { profilesRoutes } from './routes/profiles';
import { subscriptionsRoutes } from './routes/subscriptions';
import { registerPgSyncCron } from './cron/pg-full-sync';

const server = Fastify({
  logger: true,
  // data URI 프로필 이미지 업로드를 위해 기본(1MB)보다 크게 설정
  bodyLimit: 5 * 1024 * 1024,
});

async function start() {
  // Content-Type: application/json이지만 body가 비어있는 요청 허용 (빈 {}로 처리)
  server.addContentTypeParser('application/json', { parseAs: 'string' }, function (_req, body, done) {
    if (!body) return done(null, {});
    try {
      done(null, JSON.parse(body as string));
    } catch (err) {
      done(err as Error, undefined);
    }
  });

  // CORS — Flutter 앱 + 웹에서 접근 허용
  await server.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  });

  // 헬스체크
  server.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

  // 라우트 등록
  await server.register(analysesRoutes);
  await server.register(coachRoutes);
  await server.register(journalsRoutes);
  await server.register(profilesRoutes);
  await server.register(subscriptionsRoutes);

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST ?? '0.0.0.0';

  await server.listen({ port, host });
  console.log(`🚀 하루결 서버 실행 중 — http://${host}:${port}`);

  // PostgreSQL 백업 크론 (POSTGRES_URL 설정 시 활성화)
  registerPgSyncCron();
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
