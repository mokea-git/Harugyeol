import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { analysesRoutes } from './routes/analyses';
import { coachRoutes } from './routes/coach';
import { journalsRoutes } from './routes/journals';
import { profilesRoutes } from './routes/profiles';

const server = Fastify({
  logger: true,
  // data URI 프로필 이미지 업로드를 위해 기본(1MB)보다 크게 설정
  bodyLimit: 5 * 1024 * 1024,
});

async function start() {
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

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST ?? '0.0.0.0';

  await server.listen({ port, host });
  console.log(`🚀 하루결 서버 실행 중 — http://${host}:${port}`);
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
