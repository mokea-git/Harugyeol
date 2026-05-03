import Anthropic from '@anthropic-ai/sdk';
import { db } from '../db';
import { analyses } from '../db/schema';

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const MODEL = 'claude-haiku-4-5-20251001';

export async function analyzeJournal(journalId: string, content: string) {
  const message = await client.messages.create({
    model: MODEL,
    max_tokens: 512,
    system:
      '당신은 공감 능력이 뛰어난 AI 일기 분석가입니다. 반드시 JSON만 반환하고 다른 텍스트는 출력하지 마세요.',
    messages: [
      {
        role: 'user',
        content: `아래 일기를 읽고 JSON으로만 응답하세요.

일기:
${content}

응답 형식:
{
  "emotions": ["감정1", "감정2", "감정3"],
  "habits": ["습관1", "습관2"],
  "feedback": "한 줄 공감 피드백 (50자 이내)"
}

규칙:
- emotions는 최대 3개, 2글자 이상 한국어, 일기에서 실제로 느껴지는 감정만
- habits는 운동, 수면, 독서, 식사, 공부 등 반복 가능한 행동만
- feedback은 판단 없이 공감하는 톤으로`,
      },
    ],
  });

  const raw = (message.content[0] as { type: string; text: string }).text;
  const parsed = JSON.parse(raw) as {
    emotions: string[];
    habits: string[];
    feedback: string;
  };

  await db.insert(analyses).values({
    journalId,
    emotions: parsed.emotions,
    habits: parsed.habits,
    feedback: parsed.feedback,
  });
}

export async function getCoachReply(
  userMessage: string,
  emotionSummary: string
): Promise<string> {
  const message = await client.messages.create({
    model: MODEL,
    max_tokens: 512,
    system: `당신은 하루결 앱의 AI 코치입니다.
사용자의 일기와 감정 패턴을 바탕으로 따뜻하게 대화합니다.

역할:
- 판단하지 않고 공감하며 듣기
- 사용자가 스스로 생각할 수 있도록 질문하기
- 감정 패턴에 대한 인사이트 제공
- 다음 한 걸음을 함께 생각하기

톤: 친근하지만 전문적, 짧고 명확하게, 한국어

사용자의 최근 감정 패턴: ${emotionSummary || '없음'}`,
    messages: [{ role: 'user', content: userMessage }],
  });

  return (message.content[0] as { type: string; text: string }).text;
}
