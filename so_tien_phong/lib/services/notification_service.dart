import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nhắc nhở đóng tiền hàng tháng bằng thông báo tại máy (không cần server).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _monthlyId = 1001;
  static const String _channelId = 'monthly_reminder';

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      // Nếu không lấy được múi giờ VN thì dùng mặc định của máy.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );
    _ready = true;
  }

  /// Xin quyền hiện thông báo (Android 13+ bắt buộc).
  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(alert: true, sound: true);
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Không xin được quyền thông báo: $e');
    }
    return false;
  }

  Future<void> cancelMonthly() async {
    await init();
    await _plugin.cancel(_monthlyId);
  }

  /// Đặt lịch nhắc vào ngày [dayOfMonth] hàng tháng, lúc [hour]:[minute].
  Future<void> scheduleMonthly({
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    await init();
    await cancelMonthly();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Nhắc đóng tiền hàng tháng',
        channelDescription:
            'Nhắc bạn kiểm tra tiền điện, tiền phòng và phí quản lý.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        _monthlyId,
        'Đã đóng tiền tháng này chưa?',
        'Kiểm tra tiền điện, tiền phòng và phí quản lý trong sổ.',
        _nextInstance(dayOfMonth, hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e) {
      debugPrint('Không đặt được lịch nhắc: $e');
    }
  }

  /// Bắn thử một thông báo ngay để người dùng kiểm tra.
  Future<void> showTest() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Nhắc đóng tiền hàng tháng',
        channelDescription:
            'Nhắc bạn kiểm tra tiền điện, tiền phòng và phí quản lý.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      _monthlyId + 1,
      'Thông báo thử',
      'Nhắc nhở sẽ hiện giống như thế này.',
      details,
    );
  }

  tz.TZDateTime _nextInstance(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final int safeDay = day < 1 ? 1 : (day > 28 ? 28 : day);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, safeDay, hour, minute);
    if (!scheduled.isAfter(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      scheduled =
          tz.TZDateTime(tz.local, nextYear, nextMonth, safeDay, hour, minute);
    }
    return scheduled;
  }
}
