import 'dart:io';
import 'dart:typed_data';

import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:agora/domain/repositories/user_repository.dart';

class AddMessageUseCase
    implements UseCaseThreeParams<Message, Message, Uint8List, File?> {
  final FirestoreUserRepository _addPostToUserRepository;

  AddMessageUseCase(this._addPostToUserRepository);

  @override
  Future<Message> call(
      {required Message paramsOne,
      Uint8List? paramsTwo,
      required File? paramsThree}) {
    return _addPostToUserRepository.sendMessage(
        messageInfo: paramsOne,
        pathOfPhoto: paramsTwo,
        recordFile: paramsThree);
  }
}
