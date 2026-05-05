import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import {
  getSubscriptionStatus,
  startTrial,
  upgradeToPro,
  downgradePlan,
} from '../lib/sqlite';

export async function subscriptionsRoutes(fastify: FastifyInstance) {
  // GET /subscriptions/status
  fastify.get(
    '/subscriptions/status',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const status = getSubscriptionStatus(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/trial — 7일 무료 체험 시작
  fastify.post(
    '/subscriptions/trial',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const current = getSubscriptionStatus(user.id);

      // 이미 PRO이면 trial 필요 없음
      if (current.plan === 'pro') {
        return reply.send(current);
      }
      // 이미 trial 중이거나 만료 후 재신청 모두 허용 (재시작)
      const status = startTrial(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/activate — 앱에서 결제 성공 후 즉시 서버 플랜 업데이트
  fastify.post(
    '/subscriptions/activate',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const status = upgradeToPro(user.id);
      return reply.send(status);
    },
  );

  // POST /subscriptions/webhook — RevenueCat 웹훅
  // RevenueCat > Project > Webhooks 에서 이 URL 등록
  fastify.post<{ Body: Record<string, unknown> }>(
    '/subscriptions/webhook',
    async (request, reply) => {
      const event = request.body as any;
      const eventType: string = event?.event?.type ?? '';
      const userId: string | undefined =
        event?.event?.app_user_id ??
        event?.event?.original_app_user_id ??
        event?.app_user_id;

      fastify.log.info({ eventType, userId }, 'RevenueCat webhook received');

      if (!userId) {
        return reply.code(400).send({ error: 'missing user id' });
      }

      // 구독 활성화 이벤트
      const activateEvents = [
        'INITIAL_PURCHASE',
        'RENEWAL',
        'UNCANCELLATION',
        'NON_RENEWING_PURCHASE',
      ];
      // 구독 비활성화 이벤트
      const deactivateEvents = ['CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE'];

      if (activateEvents.includes(eventType)) {
        upgradeToPro(userId);
        fastify.log.info({ userId }, 'Plan upgraded to PRO');
      } else if (deactivateEvents.includes(eventType)) {
        downgradePlan(userId, 'free');
        fastify.log.info({ userId }, 'Plan downgraded to free');
      }

      return reply.code(200).send({ received: true });
    },
  );
}
