import 'dart:typed_data';
import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/child_classes/post/story.dart';
import 'package:agora/domain/repositories/story_repository.dart';

class CreateStoryUseCase implements UseCaseTwoParams<String, Story, Uint8List> {
  final FirestoreStoryRepository _createStoryRepository;

  CreateStoryUseCase(this._createStoryRepository);

  @override
  Future<String> call(
      {required Story paramsOne, required Uint8List paramsTwo}) {
    return _createStoryRepository.createStory(
        storyInfo: paramsOne, file: paramsTwo);
  }
}
