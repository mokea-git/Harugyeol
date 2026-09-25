/**
 * PostgreSQL 프라이머리 DB 레이어
 */
import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';

if (!process.env.POSTGRES_URL) {
  throw new Error('[DB] POSTGRES_URL 환경변수가 설정되지 않았습니다');
}

// ── Types ─────────────────────────────────────────────────────────────────────

export type AnalysisRecord = {
  id: string;
  journal_id: string;
  user_id: string;
  emotions: string[];
  habits: string[];
  feedback: string;
  summary: string | null;
  created_at: string;
};

export type JournalRecord = {
  id: string;
  user_id: string;
  content: string;
  date: string;
  created_at: string;
};

export type CoachMessageRecord = {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  created_at: string;
};

export type ProfileRecord = {
  user_id: string;
  email: string;
  name: string | null;
  image_url: string | null;
  plan: string;
  trial_started_at: string | null;
  created_at: string;
  updated_at: string;
};

export type PetKind = 'dog' | 'cat';

export type PetRecord = {
  id: string;
  user_id: string;
  name: string;
  kind: PetKind;
  breed: string;
  enabled: Record<string, boolean>;
  created_at: string;
  updated_at: string;
};

export type SubscriptionStatus = {
  plan: 'free' | 'trial' | 'pro';
  isPro: boolean;
  isInTrial: boolean;
  trialDaysLeft: number;
};

// ── Pool ──────────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.POSTGRES_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  console.error('[DB] pool error:', err.message);
});

async function q<T = Record<string, unknown>>(sql: string, values: unknown[] = []): Promise<T[]> {
  const result = await pool.query(sql, values);
  return result.rows as T[];
}

async function qOne<T = Record<string, unknown>>(sql: string, values: unknown[] = []): Promise<T | null> {
  const result = await pool.query(sql, values);
  return (result.rows[0] as T) ?? null;
}

// ── Schema init ───────────────────────────────────────────────────────────────

export async function initSchema(): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS journals (
      id         TEXT PRIMARY KEY,
      user_id    TEXT NOT NULL,
      content    TEXT NOT NULL,
      date       TEXT NOT NULL,
      created_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_journals_user_date
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

    CREATE INDEX IF NOT EXISTS idx_analyses_user_created
      ON analyses (user_id, created_at);

    CREATE TABLE IF NOT EXISTS coach_messages (
      id         SERIAL PRIMARY KEY,
      user_id    TEXT NOT NULL,
      role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
      content    TEXT NOT NULL,
      created_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_coach_user_created
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

    CREATE TABLE IF NOT EXISTS pets (
      id           TEXT PRIMARY KEY,
      user_id      TEXT NOT NULL,
      name         TEXT NOT NULL,
      kind         TEXT NOT NULL CHECK (kind IN ('dog', 'cat')),
      breed        TEXT NOT NULL DEFAULT '',
      enabled_json TEXT NOT NULL DEFAULT '{}',
      created_at   TEXT NOT NULL,
      updated_at   TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_pets_user_created
      ON pets (user_id, created_at ASC);
  `);
  console.log('[DB] 스키마 초기화 완료');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function parseJsonArray(value: string): string[] {
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((v): v is string => typeof v === 'string') : [];
  } catch {
    return [];
  }
}

function dateOnlyIso(now: Date): string {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function asStringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.trim() !== '' ? value : null;
}

function parseBooleanMap(value: string): Record<string, boolean> {
  try {
    const parsed = JSON.parse(value);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return {};
    }

    return Object.fromEntries(
      Object.entries(parsed).filter((entry): entry is [string, boolean] => typeof entry[1] === 'boolean'),
    );
  } catch {
    return {};
  }
}

type DbJournalRow = { id: string; user_id: string; content: string; date: string; created_at: string };
type DbAnalysisRow = {
  id: string; journal_id: string; user_id: string;
  emotions_json: string; habits_json: string;
  feedback: string; summary: string | null; created_at: string;
};
type DbCoachRow = { id: number; role: string; content: string; created_at: string };
type DbProfileRow = {
  user_id: string; email: string; name: string | null; image_url: string | null;
  plan: string; trial_started_at: string | null; created_at: string; updated_at: string;
};
type DbPetRow = {
  id: string; user_id: string; name: string; kind: string; breed: string;
  enabled_json: string; created_at: string; updated_at: string;
};

function toJournalRecord(row: DbJournalRow): JournalRecord {
  return { id: row.id, user_id: row.user_id, content: row.content, date: row.date, created_at: row.created_at };
}

function toAnalysisRecord(row: DbAnalysisRow): AnalysisRecord {
  return {
    id: row.id,
    journal_id: row.journal_id,
    user_id: row.user_id,
    emotions: parseJsonArray(row.emotions_json),
    habits: parseJsonArray(row.habits_json),
    feedback: row.feedback,
    summary: row.summary,
    created_at: row.created_at,
  };
}

function toProfileRecord(row: DbProfileRow): ProfileRecord {
  return {
    user_id: row.user_id,
    email: row.email,
    name: row.name,
    image_url: row.image_url,
    plan: row.plan,
    trial_started_at: row.trial_started_at ?? null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function toPetRecord(row: DbPetRow): PetRecord {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    kind: row.kind as PetKind,
    breed: row.breed,
    enabled: parseBooleanMap(row.enabled_json),
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

// ── Journals ──────────────────────────────────────────────────────────────────

export async function createJournal(input: {
  userId: string;
  content: string;
  date?: string;
}): Promise<JournalRecord> {
  const id = randomUUID();
  const createdAt = new Date().toISOString();
  const journalDate = input.date ?? dateOnlyIso(new Date());

  await q(
    `INSERT INTO journals (id, user_id, content, date, created_at) VALUES ($1, $2, $3, $4, $5)`,
    [id, input.userId, input.content, journalDate, createdAt],
  );

  return { id, user_id: input.userId, content: input.content, date: journalDate, created_at: createdAt };
}

export async function listJournalsByUser(userId: string, limit = 100): Promise<JournalRecord[]> {
  const rows = await q<DbJournalRow>(
    `SELECT id, user_id, content, date, created_at FROM journals
     WHERE user_id = $1 ORDER BY date DESC, created_at DESC LIMIT $2`,
    [userId, limit],
  );
  return rows.map(toJournalRecord);
}

export async function getJournalById(userId: string, journalId: string): Promise<JournalRecord | null> {
  const row = await qOne<DbJournalRow>(
    `SELECT id, user_id, content, date, created_at FROM journals WHERE user_id = $1 AND id = $2`,
    [userId, journalId],
  );
  return row ? toJournalRecord(row) : null;
}

// ── Analyses ──────────────────────────────────────────────────────────────────

export async function findAnalysisByJournalId(journalId: string): Promise<AnalysisRecord | null> {
  const row = await qOne<DbAnalysisRow>(
    `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
     FROM analyses WHERE journal_id = $1`,
    [journalId],
  );
  return row ? toAnalysisRecord(row) : null;
}

export async function findAnalysisByUserAndJournalId(
  userId: string,
  journalId: string,
): Promise<AnalysisRecord | null> {
  const row = await qOne<DbAnalysisRow>(
    `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
     FROM analyses WHERE user_id = $1 AND journal_id = $2`,
    [userId, journalId],
  );
  return row ? toAnalysisRecord(row) : null;
}

export async function createAnalysis(input: {
  journalId: string;
  userId: string;
  emotions: string[];
  habits: string[];
  feedback: string;
  summary: string | null;
}): Promise<AnalysisRecord> {
  const id = randomUUID();
  const createdAt = new Date().toISOString();
  const emotionsJson = JSON.stringify(input.emotions);
  const habitsJson = JSON.stringify(input.habits);

  await q(
    `INSERT INTO analyses (id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [id, input.journalId, input.userId, emotionsJson, habitsJson, input.feedback, input.summary, createdAt],
  );

  return {
    id,
    journal_id: input.journalId,
    user_id: input.userId,
    emotions: input.emotions,
    habits: input.habits,
    feedback: input.feedback,
    summary: input.summary,
    created_at: createdAt,
  };
}

export async function listWeeklyAnalyses(userId: string, sinceIso: string): Promise<AnalysisRecord[]> {
  const rows = await q<DbAnalysisRow>(
    `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
     FROM analyses WHERE user_id = $1 AND created_at >= $2 ORDER BY created_at ASC`,
    [userId, sinceIso],
  );
  return rows.map(toAnalysisRecord);
}

export async function listRecentAnalyses(
  userId: string,
  limit: number,
): Promise<Pick<AnalysisRecord, 'emotions' | 'habits' | 'feedback'>[]> {
  const rows = await q<{ emotions_json: string; habits_json: string; feedback: string }>(
    `SELECT emotions_json, habits_json, feedback FROM analyses
     WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2`,
    [userId, limit],
  );
  return rows.map((row) => ({
    emotions: parseJsonArray(row.emotions_json),
    habits: parseJsonArray(row.habits_json),
    feedback: row.feedback,
  }));
}

// ── Coach messages ────────────────────────────────────────────────────────────

export async function insertCoachMessage(
  userId: string,
  role: 'user' | 'assistant',
  content: string,
): Promise<CoachMessageRecord> {
  const createdAt = new Date().toISOString();
  const row = await qOne<{ id: number }>(
    `INSERT INTO coach_messages (user_id, role, content, created_at) VALUES ($1, $2, $3, $4) RETURNING id`,
    [userId, role, content, createdAt],
  );
  return { id: row!.id, role, content, created_at: createdAt };
}

export async function listCoachMessages(
  userId: string,
  limit: number,
  ascending: boolean,
): Promise<CoachMessageRecord[]> {
  const rows = await q<DbCoachRow>(
    `SELECT id, role, content, created_at FROM coach_messages
     WHERE user_id = $1 ORDER BY created_at ${ascending ? 'ASC' : 'DESC'} LIMIT $2`,
    [userId, limit],
  );
  return rows.map((row) => ({
    id: row.id,
    role: row.role as 'user' | 'assistant',
    content: row.content,
    created_at: row.created_at,
  }));
}

export async function clearCoachMessages(userId: string): Promise<void> {
  await q(`DELETE FROM coach_messages WHERE user_id = $1`, [userId]);
}

// ── Profiles ──────────────────────────────────────────────────────────────────

export async function getProfileByUserId(userId: string): Promise<ProfileRecord | null> {
  const row = await qOne<DbProfileRow>(
    `SELECT user_id, email, name, image_url, plan, trial_started_at, created_at, updated_at
     FROM profiles WHERE user_id = $1`,
    [userId],
  );
  return row ? toProfileRecord(row) : null;
}

export async function ensureProfileFromAuthUser(authUser: {
  id: string;
  email?: string | null;
  user_metadata?: unknown;
}): Promise<ProfileRecord> {
  const now = new Date().toISOString();
  const meta =
    authUser.user_metadata && typeof authUser.user_metadata === 'object'
      ? (authUser.user_metadata as Record<string, unknown>)
      : {};

  const name =
    asStringOrNull(meta.full_name) ??
    asStringOrNull(meta.name) ??
    asStringOrNull(meta.preferred_username);
  const image_url = asStringOrNull(meta.avatar_url) ?? asStringOrNull(meta.picture);
  const email = authUser.email ?? '';

  await q(
    `INSERT INTO profiles (user_id, email, name, image_url, plan, created_at, updated_at)
     VALUES ($1, $2, $3, $4, 'free', $5, $5)
     ON CONFLICT (user_id) DO UPDATE
       SET email     = CASE WHEN EXCLUDED.email != '' THEN EXCLUDED.email ELSE profiles.email END,
           name      = COALESCE(NULLIF(profiles.name, ''), EXCLUDED.name),
           image_url = COALESCE(NULLIF(profiles.image_url, ''), EXCLUDED.image_url),
           updated_at = $5`,
    [authUser.id, email, name, image_url, now],
  );

  return (await getProfileByUserId(authUser.id))!;
}

export async function updateProfileFields(
  userId: string,
  updates: { nickname?: string; avatarUrl?: string },
): Promise<ProfileRecord> {
  const existing = await getProfileByUserId(userId);
  if (!existing) throw new Error('Profile not found');

  const now = new Date().toISOString();
  const nextName = updates.nickname ?? existing.name;
  const nextAvatar = updates.avatarUrl ?? existing.image_url;

  await q(
    `UPDATE profiles SET name = $1, image_url = $2, updated_at = $3 WHERE user_id = $4`,
    [nextName, nextAvatar, now, userId],
  );

  return (await getProfileByUserId(userId))!;
}

// ── Pets ──────────────────────────────────────────────────────────────────────

export async function listPetsByUser(userId: string): Promise<PetRecord[]> {
  const rows = await q<DbPetRow>(
    `SELECT id, user_id, name, kind, breed, enabled_json, created_at, updated_at
     FROM pets WHERE user_id = $1 ORDER BY created_at ASC`,
    [userId],
  );
  return rows.map(toPetRecord);
}

export async function getPetById(userId: string, petId: string): Promise<PetRecord | null> {
  const row = await qOne<DbPetRow>(
    `SELECT id, user_id, name, kind, breed, enabled_json, created_at, updated_at
     FROM pets WHERE user_id = $1 AND id = $2`,
    [userId, petId],
  );
  return row ? toPetRecord(row) : null;
}

export async function createPet(input: {
  userId: string;
  name: string;
  kind: PetKind;
  breed?: string;
  enabled?: Record<string, boolean>;
}): Promise<PetRecord> {
  const id = randomUUID();
  const now = new Date().toISOString();
  const breed = input.breed ?? '';
  const enabledJson = JSON.stringify(input.enabled ?? {});

  await q(
    `INSERT INTO pets (id, user_id, name, kind, breed, enabled_json, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $7)`,
    [id, input.userId, input.name, input.kind, breed, enabledJson, now],
  );

  return (await getPetById(input.userId, id))!;
}

export async function updatePet(
  userId: string,
  petId: string,
  updates: { name?: string; breed?: string; enabled?: Record<string, boolean> },
): Promise<PetRecord | null> {
  const existing = await getPetById(userId, petId);
  if (!existing) return null;

  const now = new Date().toISOString();
  const name = updates.name ?? existing.name;
  const breed = updates.breed ?? existing.breed;
  const enabledJson = JSON.stringify(updates.enabled ?? existing.enabled);

  await q(
    `UPDATE pets
     SET name = $1, breed = $2, enabled_json = $3, updated_at = $4
     WHERE user_id = $5 AND id = $6`,
    [name, breed, enabledJson, now, userId, petId],
  );

  return getPetById(userId, petId);
}

export async function deletePet(userId: string, petId: string): Promise<boolean> {
  const row = await qOne<{ id: string }>(
    `DELETE FROM pets WHERE user_id = $1 AND id = $2 RETURNING id`,
    [userId, petId],
  );
  return Boolean(row);
}

// ── Subscriptions ─────────────────────────────────────────────────────────────

const TRIAL_DAYS = 7;

export async function getSubscriptionStatus(userId: string): Promise<SubscriptionStatus> {
  const profile = await getProfileByUserId(userId);
  if (!profile) return { plan: 'free', isPro: false, isInTrial: false, trialDaysLeft: 0 };

  const plan = profile.plan as 'free' | 'trial' | 'pro';

  if (plan === 'pro') {
    return { plan: 'pro', isPro: true, isInTrial: false, trialDaysLeft: 0 };
  }

  if (plan === 'trial' && profile.trial_started_at) {
    const start = new Date(profile.trial_started_at).getTime();
    const now = Date.now();
    const elapsedDays = (now - start) / (1000 * 60 * 60 * 24);
    const daysLeft = Math.max(0, Math.ceil(TRIAL_DAYS - elapsedDays));
    const isActive = daysLeft > 0;
    return { plan: 'trial', isPro: isActive, isInTrial: isActive, trialDaysLeft: daysLeft };
  }

  return { plan: 'free', isPro: false, isInTrial: false, trialDaysLeft: 0 };
}

export async function startTrial(userId: string): Promise<SubscriptionStatus> {
  const now = new Date().toISOString();
  await q(
    `UPDATE profiles SET plan = 'trial', trial_started_at = $1, updated_at = $1 WHERE user_id = $2`,
    [now, userId],
  );
  return getSubscriptionStatus(userId);
}

export async function upgradeToPro(userId: string): Promise<SubscriptionStatus> {
  const now = new Date().toISOString();
  await q(
    `UPDATE profiles SET plan = 'pro', updated_at = $1 WHERE user_id = $2`,
    [now, userId],
  );
  return getSubscriptionStatus(userId);
}

export async function downgradePlan(userId: string, plan: 'free'): Promise<void> {
  const now = new Date().toISOString();
  await q(
    `UPDATE profiles SET plan = $1, updated_at = $2 WHERE user_id = $3`,
    [plan, now, userId],
  );
}

export async function countJournalsThisMonth(userId: string): Promise<number> {
  const now = new Date();
  const monthStart = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
  const row = await qOne<{ cnt: string }>(
    `SELECT COUNT(*) as cnt FROM journals WHERE user_id = $1 AND date >= $2`,
    [userId, monthStart],
  );
  return parseInt(row?.cnt ?? '0', 10);
}

export async function countCoachMessagesToday(userId: string): Promise<number> {
  const today = dateOnlyIso(new Date());
  const row = await qOne<{ cnt: string }>(
    `SELECT COUNT(*) as cnt FROM coach_messages
     WHERE user_id = $1 AND role = 'user' AND created_at >= $2`,
    [userId, today + 'T00:00:00.000Z'],
  );
  return parseInt(row?.cnt ?? '0', 10);
}
