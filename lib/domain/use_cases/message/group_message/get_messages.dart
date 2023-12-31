import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:agora/domain/repositories/group_message.dart';

class GetMessagesGroGroupChatUseCase
    implements StreamUseCase<List<Message>, String> {
  final FireStoreGroupMessageRepository _addPostToUserRepository;

  GetMessagesGroGroupChatUseCase(this._addPostToUserRepository);

  @override
  Stream<List<Message>> call({required String params}) {
    return _addPostToUserRepository.getMessages(groupChatUid: params);
  }
}
