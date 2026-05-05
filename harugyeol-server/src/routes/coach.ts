import { FastifyInstance } from 'fastify';
import Anthropic from '@anthropic-ai/sdk';
import { requireAuth } from '../middleware/auth';
import {
  clearCoachMessages,
  countCoachMessagesToday,
  getSubscriptionStatus,
  insertCoachMessage,
  listCoachMessages,
  listRecentAnalyses,
} from '../lib/sqlite';

const FREE_DAILY_COACH_LIMIT = 5;

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

export async function coachRoutes(fastify: FastifyInstance) {
  // POST /coach/message
  fastify.post<{ Body: { message: string } }>(
    '/coach/message',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { message } = request.body;
      const user = (request as any).user;

      if (!message?.trim()) {
        return reply.code(400).send({ error: 'message is required' });
      }

      // 무료 플랜 일 5회 제한
      const subStatus = getSubscriptionStatus(user.id);
      if (!subStatus.isPro) {
        const todayCount = countCoachMessagesToday(user.id);
        if (todayCount >= FREE_DAILY_COACH_LIMIT) {
          return reply.code(403).send({
            error: `오늘 무료 AI 코치 대화(${FREE_DAILY_COACH_LIMIT}회)를 모두 사용했어요. PRO로 업그레이드하면 무제한으로 대화할 수 있어요.`,
            code: 'COACH_LIMIT_EXCEEDED',
            plan: subStatus.plan,
          });
        }
      }

      // 최근 감정 패턴 가져오기 (최근 7개 분석)
      const recentAnalyses = listRecentAnalyses(user.id, 7);

      const emotionSummary = recentAnalyses
        ? recentAnalyses
            .flatMap((a) => a.emotions as string[])
            .reduce<Record<string, number>>((acc, e) => {
              acc[e] = (acc[e] ?? 0) + 1;
              return acc;
            }, {})
        : {};

      const emotionSummaryText = Object.entries(emotionSummary)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([emotion, count]) => `${emotion}(${count}회)`)
        .join(', ');

      // 이전 대화 히스토리 가져오기 (최근 10개)
      const history = listCoachMessages(user.id, 10, false);

      const conversationHistory = (history ?? [])
        .reverse()
        .map((m) => ({
          role: m.role as 'user' | 'assistant',
          content: m.content as string,
        }));

      // 현재 메시지 추가
      conversationHistory.push({ role: 'user', content: message });

      // Claude 호출
      const response = await anthropic.messages.create({
        model: 'claude-haiku-4-5',
        max_tokens: 512,
        system: `당신은 하루결 앱의 AI 코치입니다.
사용자의 일기와 감정 패턴을 바탕으로 따뜻하게 대화합니다.

역할: 판단 없이 공감, 스스로 생각하도록 질문, 인사이트 제공
톤: 친근하지만 전문적, 짧고 명확하게, 반드시 한국어로 응답
응답 길이: 2~4문장 이내로 간결하게

사용자의 최근 감정 패턴: ${emotionSummaryText || '아직 분석 데이터가 없습니다'}`,
        messages: conversationHistory,
      });

      const assistantMessage =
        response.content[0].type === 'text' ? response.content[0].text : '';

      // 대화 저장 (user + assistant)
      insertCoachMessage(user.id, 'user', message);
      insertCoachMessage(user.id, 'assistant', assistantMessage);

      return reply.send({ message: assistantMessage });
    },
  );

  // GET /coach/history
  fastify.get(
    '/coach/history',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;

      const data = listCoachMessages(user.id, 50, true);
      return reply.send(data ?? []);
    },
  );

  // DELETE /coach/history  (대화 초기화)
  fastify.delete(
    '/coach/history',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      clearCoachMessages(user.id);
      return reply.send({ ok: true });
    },
  );
}
