import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

type AuthState = {
  token: string | null;
  setToken: (token: string) => Promise<void>;
  logout: () => Promise<void>;
  hydrate: () => Promise<void>;
};

export const useAuthStore = create<AuthState>((set) => ({
  token: null,

  setToken: async (token) => {
    await AsyncStorage.setItem('auth_token', token);
    set({ token });
  },

  logout: async () => {
    await AsyncStorage.removeItem('auth_token');
    set({ token: null });
  },

  hydrate: async () => {
    const token = await AsyncStorage.getItem('auth_token');
    if (token) set({ token });
  },
}));
