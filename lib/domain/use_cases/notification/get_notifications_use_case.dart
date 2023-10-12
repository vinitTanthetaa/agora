import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/child_classes/notification.dart';
import 'package:agora/domain/repositories/firestore_notification.dart';

class GetNotificationsUseCase
    implements UseCase<List<CustomNotification>, String> {
  final FireStoreNotificationRepository _notificationRepository;
  GetNotificationsUseCase(this._notificationRepository);
  @override
  Future<List<CustomNotification>> call({required String params}) {
    return _notificationRepository.getNotifications(userId: params);
  }
}
