import type { FastifyInstance } from 'fastify';
import { eq } from 'drizzle-orm';
import { db } from '../db';
import { subscriptions, users } from '../db/schema';

export async function subscriptionRoutes(app: FastifyInstance) {
  const auth = { onRequest: [app.authenticate] };

  // RevenueCat 웹훅: 구독 상태 업데이트
  app.post('/webhook', async (req, reply) => {
    const secret = req.headers['x-revenuecat-secret'];
    if (secret !== process.env.REVENUECAT_WEBHOOK_SECRET) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }

    const event = req.body as {
      event: { type: string; app_user_id: string; expiration_at_ms?: number };
    };
    const { type, app_user_id, expiration_at_ms } = event.event;

    const status = type === 'INITIAL_PURCHASE' || type === 'RENEWAL' ? 'active' : 'expired';
    const expiresAt = expiration_at_ms ? new Date(expiration_at_ms) : null;

    await db
      .update(subscriptions)
      .set({ status, ...(expiresAt ? { expiresAt } : {}) })
      .where(eq(subscriptions.rcCustomerId, app_user_id));

    // users.plan도 동기화
    const sub = await db.query.subscriptions.findFirst({
      where: eq(subscriptions.rcCustomerId, app_user_id),
    });
    if (sub) {
      await db
        .update(users)
        .set({ plan: status === 'active' ? 'pro' : 'free' })
        .where(eq(users.id, sub.userId));
    }

    return reply.status(200).send({ ok: true });
  });

  app.get('/status', auth, async (req) => {
    const { userId } = req.user as { userId: string };
    const sub = await db.query.subscriptions.findFirst({
      where: eq(subscriptions.userId, userId),
    });
    return sub ?? { status: 'inactive' };
  });
}
