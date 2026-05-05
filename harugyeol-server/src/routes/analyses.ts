import { FastifyInstance } from 'fastify';
import Anthropic from '@anthropic-ai/sdk';
import { requireAuth } from '../middleware/auth';
import {
  createAnalysis,
  findAnalysisByJournalId,
  findAnalysisByUserAndJournalId,
  listWeeklyAnalyses,
} from '../lib/sqlite';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

/** Claude가 ```json ... ``` 형식으로 반환할 때 코드 펜스를 제거 */
function extractJson(text: string): string {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (match) return match[1].trim();
  return text.trim();
}

export async function analysesRoutes(fastify: FastifyInstance) {
  // POST /analyses/trigger
  // 일기 저장 후 Claude 분석을 요청하는 엔드포인트
  fastify.post<{ Body: { journal_id: string; content: string } }>(
    '/analyses/trigger',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { journal_id, content } = request.body;
      const user = (request as any).user;

      if (!journal_id || !content) {
        return reply.code(400).send({ error: 'journal_id and content are required' });
      }

      // 이미 분석된 일기인지 확인
      const existing = findAnalysisByJournalId(journal_id);

      if (existing) {
        return reply.code(409).send({ error: 'Already analyzed' });
      }

      // Claude Haiku 분석 요청
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

      let parsed: {
        emotions: string[];
        habits: string[];
        feedback: string;
        summary?: string;
      };

      try {
        parsed = JSON.parse(extractJson(rawText));
      } catch {
        return reply.code(500).send({ error: 'Claude returned invalid JSON', raw: rawText });
      }

      const analysis = createAnalysis({
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

  // GET /analyses/:journalId
  fastify.get<{ Params: { journalId: string } }>(
    '/analyses/:journalId',
    { preHandler: requireAuth },
    async (request, reply) => {
      const { journalId } = request.params;
      const user = (request as any).user;

      const data = findAnalysisByUserAndJournalId(user.id, journalId);

      if (!data) return reply.code(404).send({ error: 'Not found' });
      return reply.send(data);
    },
  );

  // GET /analyses/weekly
  // 이번 주(일~토) 분석 결과 집계
  fastify.get(
    '/analyses/weekly',
    { preHandler: requireAuth },
    async (request, reply) => {
      const user = (request as any).user;

      // 이번 주 일요일 계산
      const now = new Date();
      const dayOfWeek = now.getDay(); // 0=일
      const sunday = new Date(now);
      sunday.setDate(now.getDate() - dayOfWeek);
      sunday.setHours(0, 0, 0, 0);

      const data = listWeeklyAnalyses(user.id, sunday.toISOString());
      return reply.send(data ?? []);
    },
  );
}
