import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/api_client.dart';
import 'features/subscription/purchase_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드
  await dotenv.load(fileName: '.env');

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // API 클라이언트 초기화
  ApiClient.instance.init();

  // RevenueCat 초기화
  await PurchaseService.instance.configure();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const HarugyeolApp());
}
