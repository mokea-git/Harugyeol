import 'dotenv/config';
import Fastify, { FastifyReply, FastifyRequest } from 'fastify';
import fjwt from '@fastify/jwt';
import cors from '@fastify/cors';

import { authRoutes } from './routes/auth';
import { journalRoutes } from './routes/journals';
import { analysisRoutes } from './routes/analyses';
import { coachRoutes } from './routes/coach';
import { subscriptionRoutes } from './routes/subscriptions';
import { startCronJobs } from './services/cron';

// @fastify/jwt가 추가하는 authenticate 데코레이터 타입 선언
declare module 'fastify' {
  interface FastifyInstance {
    authenticate(request: FastifyRequest, reply: FastifyReply): Promise<void>;
  }
}

const app = Fastify({ logger: true });

app.register(cors, { origin: true });
app.register(fjwt, { secret: process.env.JWT_SECRET! });

// JWT 검증 헬퍼 데코레이터 (라우트에서 onRequest: [app.authenticate] 로 사용)
app.decorate('authenticate', async (request: FastifyRequest, reply: FastifyReply) => {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.send(err);
  }
});

app.register(authRoutes, { prefix: '/auth' });
app.register(journalRoutes, { prefix: '/journals' });
app.register(analysisRoutes, { prefix: '/analyses' });
app.register(coachRoutes, { prefix: '/coach' });
app.register(subscriptionRoutes, { prefix: '/subscriptions' });

const start = async () => {
  try {
    await app.listen({ port: Number(process.env.PORT) || 3000, host: '0.0.0.0' });
    startCronJobs();
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
