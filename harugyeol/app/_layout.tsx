import { useEffect } from 'react';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useAuthStore } from '@/store/authStore';

export default function RootLayout() {
  const { token } = useAuthStore();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    const inAuthGroup = segments[0] === '(auth)';
    if (!token && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (token && inAuthGroup) {
      router.replace('/(tabs)');
    }
  }, [token, segments]);

  return (
    <>
      <StatusBar style="dark" backgroundColor="#F7F6F2" />
      <Stack screenOptions={{ headerShown: false }} />
    </>
  );
}
