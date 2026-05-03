import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcrypt';
import { eq } from 'drizzle-orm';
import { db } from '../db';
import { users } from '../db/schema';

export async function authRoutes(app: FastifyInstance) {
  app.post('/register', async (req, reply) => {
    const { email, password } = req.body as { email: string; password: string };

    const existing = await db.query.users.findFirst({ where: eq(users.email, email) });
    if (existing) return reply.status(409).send({ error: '이미 가입된 이메일입니다.' });

    const passwordHash = await bcrypt.hash(password, 10);
    const [user] = await db.insert(users).values({ email, passwordHash }).returning();

    const token = app.jwt.sign({ userId: user.id });
    return { token };
  });

  app.post('/login', async (req, reply) => {
    const { email, password } = req.body as { email: string; password: string };

    const user = await db.query.users.findFirst({ where: eq(users.email, email) });
    if (!user) return reply.status(401).send({ error: '이메일 또는 비밀번호가 올바르지 않습니다.' });

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return reply.status(401).send({ error: '이메일 또는 비밀번호가 올바르지 않습니다.' });

    const token = app.jwt.sign({ userId: user.id });
    return { token };
  });

  app.post('/refresh', { onRequest: [app.authenticate] }, async (req) => {
    const token = app.jwt.sign({ userId: (req.user as { userId: string }).userId });
    return { token };
  });
}
