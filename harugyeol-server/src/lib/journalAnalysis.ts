import Anthropic from '@anthropic-ai/sdk';

export type ParsedJournalAnalysis = {
  emotions: string[];
  habits: string[];
  feedback: string;
  summary?: string;
};

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

function extractJson(text: string): string {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  return (match?.[1] ?? text).trim();
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];
}

function normalizeAnalysis(value: unknown): ParsedJournalAnalysis {
  const parsed = value && typeof value === 'object' ? (value as Record<string, unknown>) : {};

  return {
    emotions: stringArray(parsed.emotions),
    habits: stringArray(parsed.habits),
    feedback: typeof parsed.feedback === 'string' ? parsed.feedback : '',
    summary: typeof parsed.summary === 'string' ? parsed.summary : undefined,
  };
}

function buildJournalAnalysisPrompt(content: string): string {
  return `당신은 공감 능력이 뛰어난 AI 일기 분석가입니다.
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
- JSON만 반환, 다른 텍스트 없음`;
}

export async function analyzeJournal(content: string): Promise<ParsedJournalAnalysis> {
  const message = await anthropic.messages.create({
    model: 'claude-haiku-4-5',
    max_tokens: 512,
    messages: [
      {
        role: 'user',
        content: buildJournalAnalysisPrompt(content),
      },
    ],
  });

  const rawText = message.content[0].type === 'text' ? message.content[0].text : '';
  return normalizeAnalysis(JSON.parse(extractJson(rawText)));
}

export async function safelyAnalyzeJournal(content: string): Promise<ParsedJournalAnalysis | null> {
  try {
    return await analyzeJournal(content);
  } catch (err) {
    console.error('[analyzeJournal] 실패:', err instanceof Error ? err.message : err);
    return null;
  }
}
