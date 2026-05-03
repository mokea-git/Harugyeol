import type { FastifyInstance } from 'fastify';
import { eq, gte } from 'drizzle-orm';
import { db } from '../db';
import { analyses, journals } from '../db/schema';

export async function analysisRoutes(app: FastifyInstance) {
  const auth = { onRequest: [app.authenticate] };

  app.get('/:journalId', auth, async (req, reply) => {
    const { journalId } = req.params as { journalId: string };

    const analysis = await db.query.analyses.findFirst({
      where: eq(analyses.journalId, journalId),
    });
    if (!analysis) return reply.status(404).send({ error: '분석 결과가 없습니다.' });
    return analysis;
  });

  app.get('/weekly', auth, async (req) => {
    const { userId } = req.user as { userId: string };
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const weeklyJournals = await db.query.journals.findMany({
      where: eq(journals.userId, userId),
      with: { analyses: true },
    });

    return weeklyJournals;
  });
}
