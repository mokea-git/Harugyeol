import { useEffect, useMemo } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useJournalStore } from '@/store/journalStore';

const DAYS = ['월', '화', '수', '목', '금', '토', '일'];

export default function HabitsScreen() {
  const { journals, fetchJournals } = useJournalStore();

  useEffect(() => { fetchJournals(); }, []);

  // 습관별 날짜 집계
  const habitMap = useMemo(() => {
    const map: Record<string, Set<string>> = {};
    for (const j of journals) {
      for (const habit of j.analysis?.habits ?? []) {
        if (!map[habit]) map[habit] = new Set();
        map[habit].add(j.date);
      }
    }
    return map;
  }, [journals]);

  // 최근 4주 날짜 생성 (28일)
  const last28Days = useMemo(() => {
    return Array.from({ length: 28 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - (27 - i));
      return d.toISOString().split('T')[0];
    });
  }, []);

  return (
    <SafeAreaView className="flex-1 bg-bg">
      <View className="px-5 py-4">
        <Text className="text-2xl font-bold text-coach">습관 트래커</Text>
        <Text className="text-secondary text-sm mt-1">일기에서 자동으로 감지됩니다</Text>
      </View>

      <ScrollView contentContainerStyle={{ paddingHorizontal: 20 }}>
        {Object.keys(habitMap).length === 0 ? (
          <Text className="text-center text-secondary mt-20">
            일기를 쓰면 습관이 자동으로 감지돼요 🌱
          </Text>
        ) : (
          Object.entries(habitMap).map(([habit, dates]) => (
            <View key={habit} className="bg-white rounded-2xl p-4 mb-4">
              <View className="flex-row justify-between items-center mb-3">
                <Text className="font-semibold text-coach">{habit}</Text>
                <Text className="text-secondary text-sm">{dates.size}일 기록</Text>
              </View>
              {/* 히트맵: 4주 × 7일 */}
              <View className="flex-row flex-wrap gap-1">
                {last28Days.map((date) => (
                  <View
                    key={date}
                    className={`w-7 h-7 rounded-md ${dates.has(date) ? 'bg-primary' : 'bg-gray-100'}`}
                  />
                ))}
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </SafeAreaView>
  );
}
