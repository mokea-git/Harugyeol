import { create } from 'zustand';
import { api } from '@/services/api';

type Analysis = {
  emotions: string[];
  habits: string[];
  feedback: string;
};

type Journal = {
  id: string;
  content: string;
  date: string;
  createdAt: string;
  analysis?: Analysis;
};

type JournalState = {
  journals: Journal[];
  loading: boolean;
  fetchJournals: () => Promise<void>;
  createJournal: (content: string, date: string) => Promise<void>;
  deleteJournal: (id: string) => Promise<void>;
};

export const useJournalStore = create<JournalState>((set, get) => ({
  journals: [],
  loading: false,

  fetchJournals: async () => {
    set({ loading: true });
    try {
      const journals = await api.get<Journal[]>('/journals');
      // 각 일기의 분석 결과도 함께 조회
      const withAnalyses = await Promise.all(
        journals.map(async (j) => {
          try {
            const analysis = await api.get<Analysis>(`/analyses/${j.id}`);
            return { ...j, analysis };
          } catch {
            return j;
          }
        })
      );
      set({ journals: withAnalyses });
    } finally {
      set({ loading: false });
    }
  },

  createJournal: async (content, date) => {
    const journal = await api.post<Journal>('/journals', { content, date });
    set((s) => ({ journals: [journal, ...s.journals] }));
  },

  deleteJournal: async (id) => {
    await api.delete(`/journals/${id}`);
    set((s) => ({ journals: s.journals.filter((j) => j.id !== id) }));
  },
}));
