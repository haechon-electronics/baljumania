import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 로컬 알림 서비스
/// - 폰에 알림이 울리면 갤럭시워치/애플워치에 자동으로 미러링됩니다.
/// - 웹 미리보기에서는 동작하지 않고 조용히 무시됩니다.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const _channelId = 'baljumania_alerts';
  static const _channelName = '발주매니아 알림';
  static const _channelDesc = '발주일 · 미입고 · 재고부족 알림';

  Future<void> init() async {
    if (kIsWeb) return; // 웹에서는 미지원
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } catch (_) {}

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);

      // Android 13+ 알림 권한 요청
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('알림 초기화 실패: $e');
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  /// 즉시 알림 (테스트용)
  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        title,
        body,
        _details,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('알림 표시 실패: $e');
    }
  }

  /// 특정 시각에 1회 알림 예약
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready) return;
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('알림 예약 실패: $e');
    }
  }

  /// 예약된 알림 전체 취소
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
