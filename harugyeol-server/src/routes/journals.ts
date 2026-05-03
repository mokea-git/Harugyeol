import type { FastifyInstance } from 'fastify';
import { eq, and, desc } from 'drizzle-orm';
import { db } from '../db';
import { journals } from '../db/schema';
import { analyzeJournal } from '../services/claude';

export async function journalRoutes(app: FastifyInstance) {
  const auth = { onRequest: [app.authenticate] };

  app.post('/', auth, async (req, reply) => {
    const { userId } = req.user as { userId: string };
    const { content, date } = req.body as { content: string; date: string };

    const [journal] = await db
      .insert(journals)
      .values({ userId, content, date })
      .returning();

    // 비동기로 AI 분석 트리거 (응답 블로킹 없이)
    analyzeJournal(journal.id, content).catch((err) =>
      app.log.error({ err }, 'AI 분석 실패')
    );

    return reply.status(201).send(journal);
  });

  app.get('/', auth, async (req) => {
    const { userId } = req.user as { userId: string };
    return db.query.journals.findMany({
      where: eq(journals.userId, userId),
      orderBy: [desc(journals.date)],
    });
  });

  app.get('/:id', auth, async (req, reply) => {
    const { userId } = req.user as { userId: string };
    const { id } = req.params as { id: string };

    const journal = await db.query.journals.findFirst({
      where: and(eq(journals.id, id), eq(journals.userId, userId)),
    });
    if (!journal) return reply.status(404).send({ error: '일기를 찾을 수 없습니다.' });
    return journal;
  });

  app.delete('/:id', auth, async (req, reply) => {
    const { userId } = req.user as { userId: string };
    const { id } = req.params as { id: string };

    const deleted = await db
      .delete(journals)
      .where(and(eq(journals.id, id), eq(journals.userId, userId)))
      .returning();

    if (!deleted.length) return reply.status(404).send({ error: '일기를 찾을 수 없습니다.' });
    return reply.status(204).send();
  });
}
