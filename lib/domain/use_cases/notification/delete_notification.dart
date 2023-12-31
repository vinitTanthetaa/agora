import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/domain/entities/notification_check.dart';
import 'package:agora/domain/repositories/firestore_notification.dart';

class DeleteNotificationUseCase implements UseCase<void, NotificationCheck> {
  final FireStoreNotificationRepository _notificationRepository;
  DeleteNotificationUseCase(this._notificationRepository);
  @override
  Future<void> call({required NotificationCheck params}) {
    return _notificationRepository.deleteNotification(
        notificationCheck: params);
  }
}
