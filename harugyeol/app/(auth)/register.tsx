import { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';
import { Link } from 'expo-router';
import { useAuthStore } from '@/store/authStore';
import { api } from '@/services/api';

export default function RegisterScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { setToken } = useAuthStore();

  const handleRegister = async () => {
    if (!email || !password) return Alert.alert('입력 오류', '이메일과 비밀번호를 입력해주세요.');
    if (password.length < 8) return Alert.alert('입력 오류', '비밀번호는 8자 이상이어야 합니다.');
    setLoading(true);
    try {
      const { token } = await api.post<{ token: string }>('/auth/register', { email, password });
      setToken(token);
    } catch (e: any) {
      Alert.alert('회원가입 실패', e.message ?? '다시 시도해주세요.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View className="flex-1 bg-bg justify-center px-6">
      <Text className="text-3xl font-bold text-coach mb-2">회원가입</Text>
      <Text className="text-secondary mb-10">7일 무료 체험을 시작하세요</Text>

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
        placeholder="비밀번호 (8자 이상)"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      <TouchableOpacity
        className="bg-primary rounded-xl py-4 items-center mb-4"
        onPress={handleRegister}
        disabled={loading}
      >
        <Text className="text-white font-semibold text-base">
          {loading ? '가입 중...' : '시작하기'}
        </Text>
      </TouchableOpacity>

      <Link href="/(auth)/login" asChild>
        <TouchableOpacity className="items-center">
          <Text className="text-secondary">이미 계정이 있으신가요? <Text className="font-semibold">로그인</Text></Text>
        </TouchableOpacity>
      </Link>
    </View>
  );
}
