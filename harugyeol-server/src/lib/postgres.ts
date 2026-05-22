/**
 * PostgreSQL 백업 레이어
 *
 * - SQLite가 Primary, PostgreSQL은 Backup (비동기 미러)
 * - POSTGRES_URL 미설정 시 전체 기능 무음 skip
 * - 모든 write는 ON CONFLICT DO UPDATE (upsert) — 멱등 보장
 */
import { Pool, PoolClient } from 'pg';

// ── 연결 풀 ──────────────────────────────────────────────────────────────────

let pool: Pool | null = null;

export function getPgPool(): Pool | null {
  if (!process.env.POSTGRES_URL) return null;
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.POSTGRES_URL,
      max: 5,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
    });
    pool.on('error', (err) => {
      console.error('[PG] pool error:', err.message);
    });
  }
  return pool;
}

/** 연결 가능 여부 확인 */
export async function isPgAvailable(): Promise<boolean> {
  const p = getPgPool();
  if (!p) return false;
  try {
    const client = await p.connect();
    client.release();
    return true;
  } catch {
    return false;
  }
}

// ── 스키마 초기화 ─────────────────────────────────────────────────────────────

export async function initPgSchema(): Promise<void> {
  const p = getPgPool();
  if (!p) return;

  const client: PoolClient = await p.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS journals (
        id         TEXT PRIMARY KEY,
        user_id    TEXT NOT NULL,
        content    TEXT NOT NULL,
        date       TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_pg_journals_user_date
        ON journals (user_id, date DESC, created_at DESC);

      CREATE TABLE IF NOT EXISTS analyses (
        id             TEXT PRIMARY KEY,
        journal_id     TEXT NOT NULL UNIQUE,
        user_id        TEXT NOT NULL,
        emotions_json  TEXT NOT NULL,
        habits_json    TEXT NOT NULL,
        feedback       TEXT NOT NULL,
        summary        TEXT,
        created_at     TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_pg_analyses_user_created
        ON analyses (user_id, created_at);

      CREATE TABLE IF NOT EXISTS coach_messages (
        id         BIGINT PRIMARY KEY,
        user_id    TEXT NOT NULL,
        role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
        content    TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_pg_coach_user_created
        ON coach_messages (user_id, created_at);

      CREATE TABLE IF NOT EXISTS profiles (
        user_id          TEXT PRIMARY KEY,
        email            TEXT NOT NULL,
        name             TEXT,
        image_url        TEXT,
        plan             TEXT NOT NULL DEFAULT 'free',
        trial_started_at TEXT,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL
      );
    `);
    console.log('[PG] 스키마 초기화 완료');
  } finally {
    client.release();
  }
}

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

async function run(sql: string, values: unknown[]): Promise<void> {
  const p = getPgPool();
  if (!p) return;
  try {
    await p.query(sql, values);
  } catch (err) {
    console.error('[PG] backup write 실패:', (err as Error).message);
  }
}

// ── journals ─────────────────────────────────────────────────────────────────

export async function pgUpsertJournal(j: {
  id: string;
  user_id: string;
  content: string;
  date: string;
  created_at: string;
}): Promise<void> {
  await run(
    `INSERT INTO journals (id, user_id, content, date, created_at)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (id) DO UPDATE
       SET content = EXCLUDED.content,
           date = EXCLUDED.date`,
    [j.id, j.user_id, j.content, j.date, j.created_at],
  );
}

export async function pgDeleteJournal(id: string): Promise<void> {
  await run(`DELETE FROM journals WHERE id = $1`, [id]);
}

export async function pgUpdateJournal(id: string, content: string): Promise<void> {
  await run(`UPDATE journals SET content = $1 WHERE id = $2`, [content, id]);
}

// ── analyses ─────────────────────────────────────────────────────────────────

export async function pgUpsertAnalysis(a: {
  id: string;
  journal_id: string;
  user_id: string;
  emotions_json: string;
  habits_json: string;
  feedback: string;
  summary: string | null;
  created_at: string;
}): Promise<void> {
  await run(
    `INSERT INTO analyses (id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (id) DO UPDATE
       SET emotions_json = EXCLUDED.emotions_json,
           habits_json   = EXCLUDED.habits_json,
           feedback      = EXCLUDED.feedback,
           summary       = EXCLUDED.summary`,
    [a.id, a.journal_id, a.user_id, a.emotions_json, a.habits_json, a.feedback, a.summary, a.created_at],
  );
}

// ── coach_messages ────────────────────────────────────────────────────────────

export async function pgUpsertCoachMessage(m: {
  id: number;
  user_id: string;
  role: string;
  content: string;
  created_at: string;
}): Promise<void> {
  await run(
    `INSERT INTO coach_messages (id, user_id, role, content, created_at)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (id) DO NOTHING`,
    [m.id, m.user_id, m.role, m.content, m.created_at],
  );
}

export async function pgDeleteCoachMessages(userId: string): Promise<void> {
  await run(`DELETE FROM coach_messages WHERE user_id = $1`, [userId]);
}

// ── profiles ─────────────────────────────────────────────────────────────────

export async function pgUpsertProfile(p: {
  user_id: string;
  email: string;
  name: string | null;
  image_url: string | null;
  plan: string;
  trial_started_at: string | null;
  created_at: string;
  updated_at: string;
}): Promise<void> {
  await run(
    `INSERT INTO profiles (user_id, email, name, image_url, plan, trial_started_at, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (user_id) DO UPDATE
       SET email            = EXCLUDED.email,
           name             = EXCLUDED.name,
           image_url        = EXCLUDED.image_url,
           plan             = EXCLUDED.plan,
           trial_started_at = EXCLUDED.trial_started_at,
           updated_at       = EXCLUDED.updated_at`,
    [p.user_id, p.email, p.name, p.image_url, p.plan, p.trial_started_at, p.created_at, p.updated_at],
  );
}
