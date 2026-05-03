import type { FastifyInstance } from 'fastify';
import { eq, desc } from 'drizzle-orm';
import { db } from '../db';
import { coachMessages, analyses, journals } from '../db/schema';
import { getCoachReply } from '../services/claude';

export async function coachRoutes(app: FastifyInstance) {
  const auth = { onRequest: [app.authenticate] };

  app.post('/message', auth, async (req, reply) => {
    const { userId } = req.user as { userId: string };
    const { content } = req.body as { content: string };

    // 최근 감정 패턴 수집
    const recentJournals = await db.query.journals.findMany({
      where: eq(journals.userId, userId),
      with: { analyses: true },
      orderBy: [desc(journals.createdAt)],
      limit: 7,
    });
    // analyses는 배열(one-to-many) — 첫 번째 항목의 감정 태그 취합
    const emotionSummary = recentJournals
      .flatMap((j) => j.analyses?.flatMap((a) => a.emotions) ?? [])
      .join(', ');

    // 대화 기록 저장
    await db.insert(coachMessages).values({ userId, role: 'user', content });

    const reply_content = await getCoachReply(content, emotionSummary);
    const [saved] = await db
      .insert(coachMessages)
      .values({ userId, role: 'assistant', content: reply_content })
      .returning();

    return reply.status(201).send(saved);
  });

  app.get('/history', auth, async (req) => {
    const { userId } = req.user as { userId: string };
    return db.query.coachMessages.findMany({
      where: eq(coachMessages.userId, userId),
      orderBy: [desc(coachMessages.createdAt)],
      limit: 50,
    });
  });
}
