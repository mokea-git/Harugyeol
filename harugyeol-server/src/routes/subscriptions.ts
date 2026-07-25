import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import {
  ensureProfileFromAuthUser,
  getSubscriptionStatus,
  startTrial,
  upgradeToPro,
  downgradePlan,
} from '../lib/postgres';

type RevenueCatWebhookBody = {
  event?: {
    type?: string;
    app_user_id?: string;
    original_app_user_id?: string;
  };
  app_user_id?: string;
};

export async function subscriptionsRoutes(fastify: FastifyInstance) {
  // GET /subscriptions/status
  fastify.get(
    '/subscriptions/status',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      const status = await getSubscriptionStatus(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/trial
  fastify.post(
    '/subscriptions/trial',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      await ensureProfileFromAuthUser({ id: user.id, email: user.email, user_metadata: user.user_metadata });
      const current = await getSubscriptionStatus(user.id);

      if (current.plan === 'pro') {
        return reply.send(current);
      }
      const status = await startTrial(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/activate
  fastify.post(
    '/subscriptions/activate',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      await ensureProfileFromAuthUser({ id: user.id, email: user.email, user_metadata: user.user_metadata });
      const status = await upgradeToPro(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/webhook
  fastify.post<{ Body: RevenueCatWebhookBody }>(
    '/subscriptions/webhook',
    async (request, reply) => {
      const event = request.body;
      const eventType: string = event?.event?.type ?? '';
      const userId: string | undefined =
        event?.event?.app_user_id ??
        event?.event?.original_app_user_id ??
        event?.app_user_id;

      fastify.log.info({ eventType, userId }, 'RevenueCat webhook received');

      if (!userId) {
        return reply.code(400).send({ error: 'missing user id' });
      }

      const activateEvents = ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION', 'NON_RENEWING_PURCHASE'];
      const deactivateEvents = ['CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE'];

      if (activateEvents.includes(eventType)) {
        await upgradeToPro(userId);
        fastify.log.info({ userId }, 'Plan upgraded to PRO');
      } else if (deactivateEvents.includes(eventType)) {
        await downgradePlan(userId, 'free');
        fastify.log.info({ userId }, 'Plan downgraded to free');
      }

      return reply.code(200).send({ received: true });
    },
  );
}
