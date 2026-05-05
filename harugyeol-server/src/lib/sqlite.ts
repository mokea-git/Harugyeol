import { randomUUID } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { DatabaseSync } from 'node:sqlite';

type SqliteAnalysisRow = {
  id: string;
  journal_id: string;
  user_id: string;
  emotions_json: string;
  habits_json: string;
  feedback: string;
  summary: string | null;
  created_at: string;
};

type SqliteJournalRow = {
  id: string;
  user_id: string;
  content: string;
  date: string;
  created_at: string;
};

type SqliteCoachMessageRow = {
  id: number;
  role: string;
  content: string;
  created_at: string;
};

type SqliteProfileRow = {
  user_id: string;
  email: string;
  name: string | null;
  image_url: string | null;
  plan: string;
  trial_started_at: string | null;
  created_at: string;
  updated_at: string;
};

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

export type SubscriptionStatus = {
  plan: 'free' | 'trial' | 'pro';
  isPro: boolean;
  isInTrial: boolean;
  trialDaysLeft: number; // 0 if expired/not in trial
};

const sqlitePath = resolve(process.env.SQLITE_PATH ?? './data/harugyeol.sqlite');
mkdirSync(dirname(sqlitePath), { recursive: true });

const db = new DatabaseSync(sqlitePath);
db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA foreign_keys = ON;

  CREATE TABLE IF NOT EXISTS analyses (
    id TEXT PRIMARY KEY,
    journal_id TEXT NOT NULL UNIQUE,
    user_id TEXT NOT NULL,
    emotions_json TEXT NOT NULL,
    habits_json TEXT NOT NULL,
    feedback TEXT NOT NULL,
    summary TEXT,
    created_at TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_analyses_user_created
    ON analyses(user_id, created_at);

  CREATE TABLE IF NOT EXISTS journals (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    content TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_journals_user_date
    ON journals(user_id, date DESC, created_at DESC);

  CREATE TABLE IF NOT EXISTS coach_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_coach_messages_user_created
    ON coach_messages(user_id, created_at);

  CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT,
    image_url TEXT,
    plan TEXT NOT NULL DEFAULT 'free',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
`);

// 안전한 컬럼 추가 (이미 있으면 무시)
for (const sql of [
  `ALTER TABLE profiles ADD COLUMN plan TEXT NOT NULL DEFAULT 'free';`,
  `ALTER TABLE profiles ADD COLUMN trial_started_at TEXT;`,
]) {
  try { db.exec(sql); } catch { /* already exists */ }
}

function parseJsonArray(value: string): string[] {
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((v): v is string => typeof v === 'string') : [];
  } catch {
    return [];
  }
}

function toAnalysisRecord(row: SqliteAnalysisRow): AnalysisRecord {
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

function toJournalRecord(row: SqliteJournalRow): JournalRecord {
  return {
    id: row.id,
    user_id: row.user_id,
    content: row.content,
    date: row.date,
    created_at: row.created_at,
  };
}

function dateOnlyIso(now: Date): string {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function createJournal(input: {
  userId: string;
  content: string;
  date?: string;
}): JournalRecord {
  const id = randomUUID();
  const createdAt = new Date().toISOString();
  const journalDate = input.date ?? dateOnlyIso(new Date());

  db.prepare(
    `INSERT INTO journals (id, user_id, content, date, created_at)
     VALUES (?, ?, ?, ?, ?)`,
  ).run(id, input.userId, input.content, journalDate, createdAt);

  return {
    id,
    user_id: input.userId,
    content: input.content,
    date: journalDate,
    created_at: createdAt,
  };
}

export function listJournalsByUser(userId: string, limit = 100): JournalRecord[] {
  const rows = db
    .prepare(
      `SELECT id, user_id, content, date, created_at
       FROM journals
       WHERE user_id = ?
       ORDER BY date DESC, created_at DESC
       LIMIT ?`,
    )
    .all(userId, limit) as SqliteJournalRow[];

  return rows.map(toJournalRecord);
}

export function getJournalById(userId: string, journalId: string): JournalRecord | null {
  const row = db
    .prepare(
      `SELECT id, user_id, content, date, created_at
       FROM journals
       WHERE user_id = ? AND id = ?`,
    )
    .get(userId, journalId) as SqliteJournalRow | undefined;

  return row ? toJournalRecord(row) : null;
}

export function findAnalysisByJournalId(journalId: string): AnalysisRecord | null {
  const row = db
    .prepare(
      `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
       FROM analyses
       WHERE journal_id = ?`,
    )
    .get(journalId) as SqliteAnalysisRow | undefined;

  return row ? toAnalysisRecord(row) : null;
}

export function findAnalysisByUserAndJournalId(
  userId: string,
  journalId: string,
): AnalysisRecord | null {
  const row = db
    .prepare(
      `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
       FROM analyses
       WHERE user_id = ? AND journal_id = ?`,
    )
    .get(userId, journalId) as SqliteAnalysisRow | undefined;

  return row ? toAnalysisRecord(row) : null;
}

export function createAnalysis(input: {
  journalId: string;
  userId: string;
  emotions: string[];
  habits: string[];
  feedback: string;
  summary: string | null;
}): AnalysisRecord {
  const id = randomUUID();
  const createdAt = new Date().toISOString();

  db.prepare(
    `INSERT INTO analyses (id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  ).run(
    id,
    input.journalId,
    input.userId,
    JSON.stringify(input.emotions),
    JSON.stringify(input.habits),
    input.feedback,
    input.summary,
    createdAt,
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

export function listWeeklyAnalyses(userId: string, sinceIso: string): AnalysisRecord[] {
  const rows = db
    .prepare(
      `SELECT id, journal_id, user_id, emotions_json, habits_json, feedback, summary, created_at
       FROM analyses
       WHERE user_id = ? AND created_at >= ?
       ORDER BY created_at ASC`,
    )
    .all(userId, sinceIso) as SqliteAnalysisRow[];

  return rows.map(toAnalysisRecord);
}

export function listRecentAnalyses(
  userId: string,
  limit: number,
): Pick<AnalysisRecord, 'emotions' | 'habits' | 'feedback'>[] {
  const rows = db
    .prepare(
      `SELECT emotions_json, habits_json, feedback
       FROM analyses
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT ?`,
    )
    .all(userId, limit) as Array<{
    emotions_json: string;
    habits_json: string;
    feedback: string;
  }>;

  return rows.map((row) => ({
    emotions: parseJsonArray(row.emotions_json),
    habits: parseJsonArray(row.habits_json),
    feedback: row.feedback,
  }));
}

export function insertCoachMessage(
  userId: string,
  role: 'user' | 'assistant',
  content: string,
): CoachMessageRecord {
  const createdAt = new Date().toISOString();
  const result = db
    .prepare(
      `INSERT INTO coach_messages (user_id, role, content, created_at)
       VALUES (?, ?, ?, ?)`,
    )
    .run(userId, role, content, createdAt);

  return {
    id: Number(result.lastInsertRowid),
    role,
    content,
    created_at: createdAt,
  };
}

export function listCoachMessages(
  userId: string,
  limit: number,
  ascending: boolean,
): CoachMessageRecord[] {
  const rows = db
    .prepare(
      `SELECT id, role, content, created_at
       FROM coach_messages
       WHERE user_id = ?
       ORDER BY created_at ${ascending ? 'ASC' : 'DESC'}
       LIMIT ?`,
    )
    .all(userId, limit) as SqliteCoachMessageRow[];

  return rows.map((row) => ({
    id: row.id,
    role: row.role as 'user' | 'assistant',
    content: row.content,
    created_at: row.created_at,
  }));
}

export function clearCoachMessages(userId: string): void {
  db.prepare(`DELETE FROM coach_messages WHERE user_id = ?`).run(userId);
}

function toProfileRecord(row: SqliteProfileRow): ProfileRecord {
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

function asStringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.trim() !== '' ? value : null;
}

function pickMetaName(meta: Record<string, unknown>): string | null {
  return (
    asStringOrNull(meta.full_name) ??
    asStringOrNull(meta.name) ??
    asStringOrNull(meta.preferred_username)
  );
}

function pickMetaImage(meta: Record<string, unknown>): string | null {
  return asStringOrNull(meta.avatar_url) ?? asStringOrNull(meta.picture);
}

export function getProfileByUserId(userId: string): ProfileRecord | null {
  const row = db
    .prepare(
      `SELECT user_id, email, name, image_url, plan, created_at, updated_at
       FROM profiles
       WHERE user_id = ?`,
    )
    .get(userId) as SqliteProfileRow | undefined;

  return row ? toProfileRecord(row) : null;
}

export function ensureProfileFromAuthUser(authUser: {
  id: string;
  email?: string | null;
  user_metadata?: unknown;
}): ProfileRecord {
  const now = new Date().toISOString();
  const meta =
    authUser.user_metadata && typeof authUser.user_metadata === 'object'
      ? (authUser.user_metadata as Record<string, unknown>)
      : {};
  const fallbackName = pickMetaName(meta);
  const fallbackImage = pickMetaImage(meta);
  const fallbackEmail = authUser.email ?? '';
  const existing = getProfileByUserId(authUser.id);

  if (!existing) {
    db.prepare(
      `INSERT INTO profiles (user_id, email, name, image_url, plan, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    ).run(
      authUser.id,
      fallbackEmail,
      fallbackName,
      fallbackImage,
      'free',
      now,
      now,
    );
    return getProfileByUserId(authUser.id)!;
  }

  const nextEmail = fallbackEmail || existing.email;
  const nextName = existing.name && existing.name.trim() !== '' ? existing.name : fallbackName;
  const nextImage =
    existing.image_url && existing.image_url.trim() !== '' ? existing.image_url : fallbackImage;

  db.prepare(
    `UPDATE profiles
     SET email = ?, name = ?, image_url = ?, updated_at = ?
     WHERE user_id = ?`,
  ).run(nextEmail, nextName, nextImage, now, authUser.id);

  return getProfileByUserId(authUser.id)!;
}

// ── Subscription helpers ────────────────────────────────────────────────────

const TRIAL_DAYS = 7;

export function getSubscriptionStatus(userId: string): SubscriptionStatus {
  const profile = getProfileByUserId(userId);
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
    return {
      plan: 'trial',
      isPro: isActive,
      isInTrial: isActive,
      trialDaysLeft: daysLeft,
    };
  }

  return { plan: 'free', isPro: false, isInTrial: false, trialDaysLeft: 0 };
}

export function startTrial(userId: string): SubscriptionStatus {
  const now = new Date().toISOString();
  db.prepare(
    `UPDATE profiles SET plan = 'trial', trial_started_at = ?, updated_at = ? WHERE user_id = ?`,
  ).run(now, now, userId);
  return getSubscriptionStatus(userId);
}

export function upgradeToPro(userId: string): SubscriptionStatus {
  const now = new Date().toISOString();
  db.prepare(
    `UPDATE profiles SET plan = 'pro', updated_at = ? WHERE user_id = ?`,
  ).run(now, userId);
  return getSubscriptionStatus(userId);
}

export function downgradePlan(userId: string, plan: 'free'): void {
  const now = new Date().toISOString();
  db.prepare(
    `UPDATE profiles SET plan = ?, updated_at = ? WHERE user_id = ?`,
  ).run(plan, now, userId);
}

/** 이번 달 일기 작성 횟수 */
export function countJournalsThisMonth(userId: string): number {
  const now = new Date();
  const monthStart = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
  const result = db
    .prepare(`SELECT COUNT(*) as cnt FROM journals WHERE user_id = ? AND date >= ?`)
    .get(userId, monthStart) as { cnt: number };
  return result?.cnt ?? 0;
}

/** 오늘 코치 메시지(user 발송) 횟수 */
export function countCoachMessagesToday(userId: string): number {
  const today = dateOnlyIso(new Date());
  const result = db
    .prepare(
      `SELECT COUNT(*) as cnt FROM coach_messages
       WHERE user_id = ? AND role = 'user' AND created_at >= ?`,
    )
    .get(userId, today + 'T00:00:00.000Z') as { cnt: number };
  return result?.cnt ?? 0;
}

export function updateProfileFields(
  userId: string,
  updates: { nickname?: string; avatarUrl?: string },
): ProfileRecord {
  const existing = getProfileByUserId(userId);
  if (!existing) {
    throw new Error('Profile not found');
  }

  const now = new Date().toISOString();
  const nextName = updates.nickname ?? existing.name;
  const nextAvatar = updates.avatarUrl ?? existing.image_url;

  db.prepare(
    `UPDATE profiles
     SET name = ?, image_url = ?, updated_at = ?
     WHERE user_id = ?`,
  ).run(nextName, nextAvatar, now, userId);

  return getProfileByUserId(userId)!;
}
