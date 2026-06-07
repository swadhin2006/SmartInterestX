import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/transaction_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleTransactionReminder({
    required LoanTransaction transaction,
    required int daysBefore,
  }) async {
    if (transaction.dueDate == null) return;

    final reminderDate =
        transaction.dueDate!.subtract(Duration(days: daysBefore));
    if (reminderDate.isBefore(DateTime.now())) return;

    final id = transaction.id.hashCode + daysBefore;
    final typeLabel =
        transaction.type == TransactionType.given ? 'receivable' : 'payable';

    await _plugin.zonedSchedule(
      id,
      'Payment Due Reminder',
      '${transaction.contactName} — ₹${transaction.amount.toStringAsFixed(0)} $typeLabel in $daysBefore day(s)',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'due_reminders',
          'Due Date Reminders',
          channelDescription: 'Reminders for upcoming loan due dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showOverdueNotification(LoanTransaction transaction) async {
    final typeLabel =
        transaction.type == TransactionType.given ? 'receivable' : 'payable';
    await _plugin.show(
      transaction.id.hashCode,
      'Overdue Payment',
      '${transaction.contactName} — ₹${transaction.amount.toStringAsFixed(0)} $typeLabel is overdue',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'overdue',
          'Overdue Payments',
          channelDescription: 'Notifications for overdue payments',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelTransactionReminders(String transactionId) async {
    for (final days in [1, 3, 7]) {
      await _plugin.cancel(transactionId.hashCode + days);
    }
    await _plugin.cancel(transactionId.hashCode);
  }

  Future<void> scheduleAllReminders(
      LoanTransaction transaction, List<int> daysBefore) async {
    for (final days in daysBefore) {
      await scheduleTransactionReminder(
          transaction: transaction, daysBefore: days);
    }
  }
}
