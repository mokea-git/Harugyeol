import { pgTable, uuid, text, date, timestamp } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').unique().notNull(),
  passwordHash: text('password_hash').notNull(),
  plan: text('plan').default('free').notNull(), // 'free' | 'pro'
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const journals = pgTable('journals', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  content: text('content').notNull(),
  date: date('date').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const analyses = pgTable('analyses', {
  id: uuid('id').primaryKey().defaultRandom(),
  journalId: uuid('journal_id').references(() => journals.id, { onDelete: 'cascade' }).notNull(),
  emotions: text('emotions').array().notNull(),
  habits: text('habits').array().notNull(),
  feedback: text('feedback').notNull(),
  summary: text('summary'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  rcCustomerId: text('rc_customer_id'),
  status: text('status').default('inactive').notNull(), // 'active' | 'inactive' | 'expired'
  expiresAt: timestamp('expires_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const coachMessages = pgTable('coach_messages', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  role: text('role').notNull(), // 'user' | 'assistant'
  content: text('content').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

// ── Relations ──────────────────────────────────────────────
export const journalsRelations = relations(journals, ({ one, many }) => ({
  user: one(users, { fields: [journals.userId], references: [users.id] }),
  analyses: many(analyses),
}));

export const analysesRelations = relations(analyses, ({ one }) => ({
  journal: one(journals, { fields: [analyses.journalId], references: [journals.id] }),
}));
