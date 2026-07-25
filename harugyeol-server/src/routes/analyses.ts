import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import { analyzeJournal } from '../lib/journalAnalysis';
import {
  createAnalysis,
  findAnalysisByJournalId,
  findAnalysisByUserAndJournalId,
  listWeeklyAnalyses,
} from '../lib/postgres';

export async function analysesRoutes(fastify: FastifyInstance) {
  // POST /analyses/trigger
  fastify.post<{ Body: { journal_id: string; content: string } }>(
    '/analyses/trigger',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { journal_id, content } = request.body;
      const { user } = request;

      if (!journal_id || !content) {
        return reply.code(400).send({ error: 'journal_id and content are required' });
      }

      const existing = await findAnalysisByJournalId(journal_id);
      if (existing) {
        return reply.code(409).send({ error: 'Already analyzed' });
      }

      let parsed;
      try {
        parsed = await analyzeJournal(content);
      } catch (err) {
        request.log.error({ err }, 'Failed to analyze journal');
        return reply.code(502).send({ error: 'AI analysis failed' });
      }

      const analysis = await createAnalysis({
        journalId: journal_id,
        userId: user.id,
        emotions: parsed.emotions,
        habits: parsed.habits,
        feedback: parsed.feedback,
        summary: parsed.summary ?? null,
      });

      return reply.code(201).send(analysis);
    },
  );

  // GET /analyses/weekly
  fastify.get(
    '/analyses/weekly',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;

      const now = new Date();
      const dayOfWeek = now.getDay();
      const sunday = new Date(now);
      sunday.setDate(now.getDate() - dayOfWeek);
      sunday.setHours(0, 0, 0, 0);

      const data = await listWeeklyAnalyses(user.id, sunday.toISOString());
      return reply.send(data ?? []);
    },
  );

  // GET /analyses/:journalId
  fastify.get<{ Params: { journalId: string } }>(
    '/analyses/:journalId',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { journalId } = request.params;
      const { user } = request;

      const data = await findAnalysisByUserAndJournalId(user.id, journalId);
      if (!data) return reply.code(404).send({ error: 'Not found' });
      return reply.send(data);
    },
  );
}
