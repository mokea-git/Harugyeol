import { FastifyInstance } from 'fastify';
import { requireAuth } from '../middleware/auth';
import { safelyAnalyzeJournal } from '../lib/journalAnalysis';
import {
  JournalRecord,
  createAnalysis,
  createJournal,
  countJournalsThisMonth,
  findAnalysisByUserAndJournalId,
  getJournalById,
  getSubscriptionStatus,
  listJournalsByUser,
} from '../lib/postgres';

const FREE_MONTHLY_JOURNAL_LIMIT = 10;

async function toJournalResponse(userId: string, journal: JournalRecord) {
  const analysis = await findAnalysisByUserAndJournalId(userId, journal.id);
  return {
    id: journal.id,
    user_id: journal.user_id,
    content: journal.content,
    date: journal.date,
    created_at: journal.created_at,
    analysis,
  };
}

export async function journalsRoutes(fastify: FastifyInstance) {
  // POST /journals
  fastify.post<{ Body: { content: string; date?: string; analyze?: boolean } }>(
    '/journals',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      const content = request.body?.content?.trim();
      const date = request.body?.date?.trim();
      const shouldAnalyze = request.body?.analyze !== false;

      if (!content) {
        return reply.code(400).send({ error: 'content is required' });
      }

      const subStatus = await getSubscriptionStatus(user.id);
      if (!subStatus.isPro) {
        const monthCount = await countJournalsThisMonth(user.id);
        if (monthCount >= FREE_MONTHLY_JOURNAL_LIMIT) {
          return reply.code(403).send({
            error: `이번 달 무료 일기(${FREE_MONTHLY_JOURNAL_LIMIT}개)를 모두 사용했어요. PRO로 업그레이드하면 무제한으로 쓸 수 있어요.`,
            code: 'JOURNAL_LIMIT_EXCEEDED',
            plan: subStatus.plan,
          });
        }
      }

      if (shouldAnalyze) {
        const parsed = await safelyAnalyzeJournal(content);
        if (!parsed) {
          return reply.code(502).send({ error: 'AI 분석에 실패했어요. 잠시 후 다시 시도해 주세요.' });
        }

        const journal = await createJournal({ userId: user.id, content, date: date || undefined });
        await createAnalysis({
          journalId: journal.id,
          userId: user.id,
          emotions: parsed.emotions,
          habits: parsed.habits,
          feedback: parsed.feedback,
          summary: parsed.summary ?? null,
        });

        return reply.code(201).send(await toJournalResponse(user.id, journal));
      }

      const journal = await createJournal({ userId: user.id, content, date: date || undefined });
      return reply.code(201).send(await toJournalResponse(user.id, journal));
    },
  );

  // GET /journals
  fastify.get(
    '/journals',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      const journals = await listJournalsByUser(user.id, 200);
      const result = await Promise.all(journals.map((j) => toJournalResponse(user.id, j)));
      return reply.send(result);
    },
  );

  // GET /journals/:id
  fastify.get<{ Params: { id: string } }>(
    '/journals/:id',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { user } = request;
      const journal = await getJournalById(user.id, request.params.id);
      if (!journal) {
        return reply.code(404).send({ error: 'journal not found' });
      }
      return reply.send(await toJournalResponse(user.id, journal));
    },
  );
}
