import { useEffect, useRef, useState } from 'react';
import {
  View, Text, FlatList, TextInput, TouchableOpacity,
  KeyboardAvoidingView, Platform, ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuthStore } from '@/store/authStore';
import { api } from '@/services/api';

type Message = { id: string; role: 'user' | 'assistant'; content: string };

export default function CoachScreen() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const flatRef = useRef<FlatList>(null);

  useEffect(() => {
    api.get<Message[]>('/coach/history').then(setMessages).catch(() => {});
  }, []);

  const sendMessage = async () => {
    const text = input.trim();
    if (!text || sending) return;
    setInput('');
    setSending(true);

    const userMsg: Message = { id: Date.now().toString(), role: 'user', content: text };
    setMessages((prev) => [...prev, userMsg]);

    try {
      const saved = await api.post<Message>('/coach/message', { content: text });
      setMessages((prev) => [...prev, saved]);
    } catch {
      setMessages((prev) => [
        ...prev,
        { id: Date.now().toString(), role: 'assistant', content: '잠시 후 다시 시도해주세요.' },
      ]);
    } finally {
      setSending(false);
      setTimeout(() => flatRef.current?.scrollToEnd(), 100);
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-bg">
      <View className="px-5 py-4 border-b border-gray-100">
        <Text className="text-2xl font-bold text-coach">AI 코치</Text>
        <Text className="text-secondary text-sm">감정 패턴을 바탕으로 대화해요</Text>
      </View>

      <KeyboardAvoidingView
        className="flex-1"
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={90}
      >
        <FlatList
          ref={flatRef}
          data={messages}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16 }}
          renderItem={({ item }) => (
            <View
              className={`max-w-[80%] rounded-2xl px-4 py-3 mb-2 ${
                item.role === 'user'
                  ? 'self-end bg-primary'
                  : 'self-start bg-coach'
              }`}
            >
              <Text className="text-white text-base">{item.content}</Text>
            </View>
          )}
          ListEmptyComponent={
            <Text className="text-center text-secondary mt-20">
              무엇이든 편하게 이야기해보세요 💚
            </Text>
          }
        />

        <View className="flex-row items-end px-4 py-3 bg-white border-t border-gray-100">
          <TextInput
            className="flex-1 bg-bg rounded-2xl px-4 py-2 text-base mr-2 max-h-24"
            placeholder="메시지를 입력하세요..."
            value={input}
            onChangeText={setInput}
            multiline
          />
          <TouchableOpacity
            className="bg-primary rounded-full w-10 h-10 items-center justify-center"
            onPress={sendMessage}
            disabled={sending}
          >
            {sending ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <Text className="text-white text-lg">↑</Text>
            )}
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
