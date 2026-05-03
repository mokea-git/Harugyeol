import cron from 'node-cron';
import { Resend } from 'resend';
import { db } from '../db';
import { users, journals, analyses } from '../db/schema';
import { eq, gte } from 'drizzle-orm';

const resend = new Resend(process.env.RESEND_API_KEY);

async function generateWeeklyReports() {
  const allUsers = await db.query.users.findMany();
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);

  for (const user of allUsers) {
    const weeklyJournals = await db.query.journals.findMany({
      where: eq(journals.userId, user.id),
      with: { analyses: true },
    });

    if (!weeklyJournals.length) continue;

    // analyses는 one-to-many 배열
    const allEmotions = weeklyJournals.flatMap((j) => j.analyses?.flatMap((a) => a.emotions) ?? []);
    const allHabits = weeklyJournals.flatMap((j) => j.analyses?.flatMap((a) => a.habits) ?? []);

    const emotionCounts = allEmotions.reduce<Record<string, number>>((acc, e) => {
      acc[e] = (acc[e] ?? 0) + 1;
      return acc;
    }, {});
    const topEmotions = Object.entries(emotionCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([e]) => e);

    const habitSet = [...new Set(allHabits)];

    await resend.emails.send({
      from: process.env.RESEND_FROM!,
      to: user.email,
      subject: '하루결 주간 리포트 📋',
      html: `
        <h2>이번 주 하루결 리포트</h2>
        <p>일기 수: ${weeklyJournals.length}편</p>
        <p>주요 감정: ${topEmotions.join(', ') || '없음'}</p>
        <p>기록된 습관: ${habitSet.join(', ') || '없음'}</p>
      `,
    });
  }
}

export function startCronJobs() {
  // 매주 월요일 오전 9시
  cron.schedule('0 9 * * 1', generateWeeklyReports, {
    timezone: 'Asia/Seoul',
  });
}
