import { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';
import { Link } from 'expo-router';
import { useAuthStore } from '@/store/authStore';
import { api } from '@/services/api';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { setToken } = useAuthStore();

  const handleLogin = async () => {
    if (!email || !password) return Alert.alert('입력 오류', '이메일과 비밀번호를 입력해주세요.');
    setLoading(true);
    try {
      const { token } = await api.post<{ token: string }>('/auth/login', { email, password });
      setToken(token);
    } catch (e: any) {
      Alert.alert('로그인 실패', e.message ?? '다시 시도해주세요.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View className="flex-1 bg-bg justify-center px-6">
      <Text className="text-3xl font-bold text-coach mb-2">하루결</Text>
      <Text className="text-secondary mb-10">오늘 하루의 결을 읽어드립니다</Text>

      <TextInput
        className="bg-white border border-gray-200 rounded-xl px-4 py-3 mb-3 text-base"
        placeholder="이메일"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        autoCapitalize="none"
      />
      <TextInput
        className="bg-white border border-gray-200 rounded-xl px-4 py-3 mb-6 text-base"
        placeholder="비밀번호"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      <TouchableOpacity
        className="bg-primary rounded-xl py-4 items-center mb-4"
        onPress={handleLogin}
        disabled={loading}
      >
        <Text className="text-white font-semibold text-base">
          {loading ? '로그인 중...' : '로그인'}
        </Text>
      </TouchableOpacity>

      <Link href="/(auth)/register" asChild>
        <TouchableOpacity className="items-center">
          <Text className="text-secondary">계정이 없으신가요? <Text className="font-semibold">회원가입</Text></Text>
        </TouchableOpacity>
      </Link>
    </View>
  );
}
