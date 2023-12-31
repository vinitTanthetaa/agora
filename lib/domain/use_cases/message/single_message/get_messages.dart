import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:agora/domain/repositories/user_repository.dart';

class GetMessagesUseCase implements StreamUseCase<List<Message>, String> {
  final FirestoreUserRepository _addPostToUserRepository;

  GetMessagesUseCase(this._addPostToUserRepository);

  @override
  Stream<List<Message>> call({required String params}) {
    return _addPostToUserRepository.getMessages(receiverId: params);
  }
}
