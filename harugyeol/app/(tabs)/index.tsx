import { useEffect, useState } from 'react';
import {
  View, Text, FlatList, TouchableOpacity,
  Modal, TextInput, Alert, ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useJournalStore } from '@/store/journalStore';

export default function HomeScreen() {
  const { journals, fetchJournals, createJournal, loading } = useJournalStore();
  const [modalVisible, setModalVisible] = useState(false);
  const [content, setContent] = useState('');

  useEffect(() => { fetchJournals(); }, []);

  const handleSave = async () => {
    if (!content.trim()) return;
    const today = new Date().toISOString().split('T')[0];
    await createJournal(content.trim(), today);
    setContent('');
    setModalVisible(false);
  };

  return (
    <SafeAreaView className="flex-1 bg-bg">
      <View className="flex-row justify-between items-center px-5 py-4">
        <Text className="text-2xl font-bold text-coach">하루결</Text>
        <TouchableOpacity
          className="bg-primary rounded-full w-10 h-10 items-center justify-center"
          onPress={() => setModalVisible(true)}
        >
          <Text className="text-white text-2xl leading-none">+</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator className="mt-10" color="#659b5e" />
      ) : (
        <FlatList
          data={journals}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ paddingHorizontal: 20 }}
          renderItem={({ item }) => (
            <View className="bg-white rounded-2xl p-4 mb-3 shadow-sm">
              <Text className="text-xs text-secondary mb-1">{item.date}</Text>
              <Text className="text-base text-gray-800" numberOfLines={3}>
                {item.content}
              </Text>
              {item.analysis && (
                <View className="flex-row flex-wrap gap-1 mt-2">
                  {item.analysis.emotions.map((e) => (
                    <View key={e} className="bg-primary/10 rounded-full px-2 py-0.5">
                      <Text className="text-xs text-primary">{e}</Text>
                    </View>
                  ))}
                </View>
              )}
              {item.analysis?.feedback && (
                <Text className="text-xs text-secondary mt-2 italic">
                  {item.analysis.feedback}
                </Text>
              )}
            </View>
          )}
          ListEmptyComponent={
            <Text className="text-center text-secondary mt-20">
              첫 번째 일기를 써보세요 ✍️
            </Text>
          }
        />
      )}

      {/* 일기 작성 모달 */}
      <Modal visible={modalVisible} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView className="flex-1 bg-bg">
          <View className="flex-row justify-between items-center px-5 py-4">
            <TouchableOpacity onPress={() => setModalVisible(false)}>
              <Text className="text-secondary text-base">취소</Text>
            </TouchableOpacity>
            <Text className="font-semibold text-coach">오늘의 일기</Text>
            <TouchableOpacity onPress={handleSave}>
              <Text className="text-primary font-semibold text-base">저장</Text>
            </TouchableOpacity>
          </View>
          <TextInput
            className="flex-1 px-5 text-base text-gray-800"
            placeholder="오늘 하루 어땠나요?"
            multiline
            textAlignVertical="top"
            value={content}
            onChangeText={setContent}
            autoFocus
          />
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}
