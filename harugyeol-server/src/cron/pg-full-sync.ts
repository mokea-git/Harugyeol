/**
 * PostgreSQL 전체 동기화 크론
 *
 * - 매시간 실행 (기본값)
 * - SQLite 전체 데이터를 PostgreSQL에 upsert
 * - 이미 동기화된 레코드는 ON CONFLICT 로 무시 or 업데이트
 * - PostgreSQL 미설정 or 연결 실패 시 조용히 skip
 */
import cron from 'node-cron';
import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import {
  getPgPool,
  initPgSchema,
  pgUpsertAnalysis,
  pgUpsertCoachMessage,
  pgUpsertJournal,
  pgUpsertProfile,
} from '../lib/postgres';

type SyncResult = {
  journals: number;
  analyses: number;
  coachMessages: number;
  profiles: number;
  errors: number;
};

async function runFullSync(): Promise<void> {
  const pool = getPgPool();
  if (!pool) return; // POSTGRES_URL 미설정

  const sqlitePath = resolve(process.env.SQLITE_PATH ?? './data/harugyeol.sqlite');
  mkdirSync(dirname(sqlitePath), { recursive: true });

  let db: DatabaseSync;
  try {
    db = new DatabaseSync(sqlitePath, { readOnly: true });
  } catch (err) {
    console.error('[PG sync] SQLite 열기 실패:', (err as Error).message);
    return;
  }

  const result: SyncResult = { journals: 0, analyses: 0, coachMessages: 0, profiles: 0, errors: 0 };
  const startAt = Date.now();

  try {
    // ── journals ─────────────────────────────────────────────────
    const journals = db
      .prepare(`SELECT id, user_id, content, date, created_at FROM journals`)
      .all() as Array<{ id: string; user_id: string; content: string; date: string; created_at: string }>;

    for (const j of journals) {
      try {
        await pgUpsertJournal(j);
        result.journals++;
      } catch { result.errors++; }
    }

    // ── analyses ──────────────────────────────────────────────────
    const analyses = db
      .prepare(`SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at FROM analyses`)
      .all() as Array<{
        id: string; journal_id: string; user_id: string;
        emotions_json: string; habits_json: string;
        feedback: string; summary: string | null; created_at: string;
      }>;

    for (const a of analyses) {
      try {
        await pgUpsertAnalysis(a);
        result.analyses++;
      } catch { result.errors++; }
    }

    // ── coach_messages ────────────────────────────────────────────
    const messages = db
      .prepare(`SELECT id, user_id, role, content, created_at FROM coach_messages`)
      .all() as Array<{ id: number; user_id: string; role: string; content: string; created_at: string }>;

    for (const m of messages) {
      try {
        await pgUpsertCoachMessage(m);
        result.coachMessages++;
      } catch { result.errors++; }
    }

    // ── profiles ──────────────────────────────────────────────────
    const profiles = db
      .prepare(`SELECT user_id, email, name, image_url, plan, trial_started_at, created_at, updated_at FROM profiles`)
      .all() as Array<{
        user_id: string; email: string; name: string | null; image_url: string | null;
        plan: string; trial_started_at: string | null; created_at: string; updated_at: string;
      }>;

    for (const p of profiles) {
      try {
        await pgUpsertProfile(p);
        result.profiles++;
      } catch { result.errors++; }
    }

    const elapsed = Date.now() - startAt;
    console.log(
      `[PG sync] 완료 ${elapsed}ms — journals:${result.journals} analyses:${result.analyses} coach:${result.coachMessages} profiles:${result.profiles} errors:${result.errors}`,
    );
  } catch (err) {
    console.error('[PG sync] 예외 발생:', (err as Error).message);
  } finally {
    db.close();
  }
}

/**
 * 매시간 full sync 크론 등록
 * schedule 예시: '0 * * * *' = 매시 정각
 */
export function registerPgSyncCron(schedule = '0 * * * *'): void {
  if (!getPgPool()) {
    console.log('[PG sync] POSTGRES_URL 미설정 — 백업 크론 skip');
    return;
  }

  // 서버 시작 시 최초 1회 즉시 실행 (누락분 복구)
  initPgSchema()
    .then(() => runFullSync())
    .catch((err) => console.error('[PG sync] 초기 동기화 실패:', (err as Error).message));

  cron.schedule(schedule, () => {
    runFullSync().catch((err) => console.error('[PG sync] 크론 실패:', (err as Error).message));
  });

  console.log(`[PG sync] 백업 크론 등록 완료 (${schedule})`);
}
