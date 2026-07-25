import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { initSchema } from './lib/postgres';
import { analysesRoutes } from './routes/analyses';
import { coachRoutes } from './routes/coach';
import { journalsRoutes } from './routes/journals';
import { petsRoutes } from './routes/pets';
import { profilesRoutes } from './routes/profiles';
import { subscriptionsRoutes } from './routes/subscriptions';

const server = Fastify({
  logger: true,
  bodyLimit: 5 * 1024 * 1024,
});

async function start() {
  server.addContentTypeParser('application/json', { parseAs: 'string' }, function (_req, body, done) {
    if (!body) return done(null, {});
    try {
      done(null, JSON.parse(body as string));
    } catch (err) {
      done(err as Error, undefined);
    }
  });

  await server.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  });

  server.get<{ Querystring: Record<string, string | undefined> }>(
    '/',
    async (request, reply) => {
      const query = request.query;
      const isOAuthCallback =
        query.code ||
        query.error ||
        query.error_code ||
        query.error_description;

      if (!isOAuthCallback) {
        return reply.send({ status: 'ok', service: 'harugyeol-server' });
      }

      const appCallback =
        process.env.APP_AUTH_CALLBACK_URL ??
        'io.supabase.harugyeol://login-callback';
      const params = new URLSearchParams();
      Object.entries(query).forEach(([key, value]) => {
        if (value) params.set(key, value);
      });
      const redirectUrl = `${appCallback}?${params.toString()}`;

      return reply.type('text/html; charset=utf-8').send(`<!doctype html>
<html lang="ko">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>하루결 로그인</title>
  </head>
  <body>
    <script>window.location.replace(${JSON.stringify(redirectUrl)});</script>
    <p>하루결 앱으로 돌아가는 중입니다.</p>
  </body>
</html>`);
    },
  );

  server.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

  await initSchema();

  await server.register(analysesRoutes);
  await server.register(coachRoutes);
  await server.register(journalsRoutes);
  await server.register(petsRoutes);
  await server.register(profilesRoutes);
  await server.register(subscriptionsRoutes);

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.HOST ?? '0.0.0.0';

  await server.listen({ port, host });
  console.log(`하루결 서버 실행 중 — http://${host}:${port}`);
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
