import 'package:astina/features/fcm/data/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment notification opens the payment detail feature', () {
    final notification = AppNotification(
      id: 1,
      type: 'payment_approved',
      title: 'Pembayaran disetujui',
      body: 'Pembayaran Anda telah disetujui.',
      data: const {'payment_id': '7'},
      createdAt: DateTime(2026, 9, 11),
    );

    expect(notification.routePath, '/finance/payments/7');
  });
}
