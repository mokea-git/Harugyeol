import { FastifyInstance } from 'fastify';
import Anthropic from '@anthropic-ai/sdk';
import { requireAuth } from '../middleware/auth';
import {
  createAnalysis,
  createJournal,
  countJournalsThisMonth,
  findAnalysisByUserAndJournalId,
  getJournalById,
  getSubscriptionStatus,
  listJournalsByUser,
} from '../lib/sqlite';

const FREE_MONTHLY_JOURNAL_LIMIT = 10;

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

/** Claude가 ```json ... ``` 형식으로 반환할 때 코드 펜스를 제거 */
function extractJson(text: string): string {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (match) return match[1].trim();
  return text.trim();
}

type ParsedAnalysis = {
  emotions: string[];
  habits: string[];
  feedback: string;
  summary?: string;
};

async function analyzeJournal(content: string): Promise<ParsedAnalysis | null> {
  try {
    const message = await anthropic.messages.create({
      model: 'claude-haiku-4-5',
      max_tokens: 512,
      messages: [
        {
          role: 'user',
          content: `당신은 공감 능력이 뛰어난 AI 일기 분석가입니다.
아래 일기를 읽고 JSON으로만 응답하세요.

일기:
${content}

응답 형식:
{
  "emotions": ["감정1", "감정2", "감정3"],
  "habits": ["습관1", "습관2"],
  "feedback": "한 줄 공감 피드백 (50자 이내)",
  "summary": "오늘 하루를 한 문장으로 (30자 이내)"
}

규칙:
- emotions는 실제로 느껴지는 감정만, 최대 3개
- habits는 운동/수면/독서/식사/공부 등 반복 가능한 행동만
- feedback은 판단 없이 공감하는 톤
- JSON만 반환, 다른 텍스트 없음`,
        },
      ],
    });

    const rawText = message.content[0].type === 'text' ? message.content[0].text : '';
    const parsed = JSON.parse(extractJson(rawText)) as ParsedAnalysis;

    return {
      emotions: Array.isArray(parsed.emotions) ? parsed.emotions : [],
      habits: Array.isArray(parsed.habits) ? parsed.habits : [],
      feedback: typeof parsed.feedback === 'string' ? parsed.feedback : '',
      summary: typeof parsed.summary === 'string' ? parsed.summary : undefined,
    };
  } catch (err) {
    console.error('[analyzeJournal] 실패:', err instanceof Error ? err.message : err);
    return null;
  }
}

function toJournalResponse(userId: string, journal: ReturnType<typeof createJournal>) {
  const analysis = findAnalysisByUserAndJournalId(userId, journal.id);
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
      const user = (request as any).user;
      const content = request.body?.content?.trim();
      const date = request.body?.date?.trim();
      const shouldAnalyze = request.body?.analyze !== false;

      if (!content) {
        return reply.code(400).send({ error: 'content is required' });
      }

      // 무료 플랜 월 10개 제한
      const subStatus = getSubscriptionStatus(user.id);
      if (!subStatus.isPro) {
        const monthCount = countJournalsThisMonth(user.id);
        if (monthCount >= FREE_MONTHLY_JOURNAL_LIMIT) {
          return reply.code(403).send({
            error: `이번 달 무료 일기(${FREE_MONTHLY_JOURNAL_LIMIT}개)를 모두 사용했어요. PRO로 업그레이드하면 무제한으로 쓸 수 있어요.`,
            code: 'JOURNAL_LIMIT_EXCEEDED',
            plan: subStatus.plan,
          });
        }
      }

      // 요구사항: AI 분석 완료 전에는 저장 확정하지 않음
      if (shouldAnalyze) {
        const parsed = await analyzeJournal(content);
        if (!parsed) {
          return reply.code(502).send({ error: 'AI 분석에 실패했어요. 잠시 후 다시 시도해 주세요.' });
        }

        const journal = createJournal({ userId: user.id, content, date: date || undefined });
        createAnalysis({
          journalId: journal.id,
          userId: user.id,
          emotions: parsed.emotions,
          habits: parsed.habits,
          feedback: parsed.feedback,
          summary: parsed.summary ?? null,
        });

        return reply.code(201).send(toJournalResponse(user.id, journal));
      }

      const journal = createJournal({ userId: user.id, content, date: date || undefined });
      return reply.code(201).send(toJournalResponse(user.id, journal));
    },
  );

  // GET /journals
  fastify.get(
    '/journals',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const journals = listJournalsByUser(user.id, 200).map((j) => toJournalResponse(user.id, j));
      return reply.send(journals);
    },
  );

  // GET /journals/:id
  fastify.get<{ Params: { id: string } }>(
    '/journals/:id',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;
      const journal = getJournalById(user.id, request.params.id);
      if (!journal) {
        return reply.code(404).send({ error: 'journal not found' });
      }
      return reply.send(toJournalResponse(user.id, journal));
    },
  );
}
