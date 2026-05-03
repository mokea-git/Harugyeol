import { Tabs } from 'expo-router';
import { Text } from 'react-native';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#659b5e',
        tabBarInactiveTintColor: '#999',
        tabBarStyle: { backgroundColor: '#fff', borderTopColor: '#eee' },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: '일기',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>📓</Text>,
        }}
      />
      <Tabs.Screen
        name="habits"
        options={{
          title: '습관',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>📊</Text>,
        }}
      />
      <Tabs.Screen
        name="coach"
        options={{
          title: 'AI 코치',
          tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>💬</Text>,
        }}
      />
    </Tabs>
  );
}
