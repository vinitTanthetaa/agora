import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:agora/domain/repositories/story_repository.dart';

class GetSpecificStoriesInfoUseCase
    implements UseCase<UserPersonalInfo, UserPersonalInfo> {
  final FirestoreStoryRepository _getStoryRepository;

  GetSpecificStoriesInfoUseCase(this._getStoryRepository);

  @override
  Future<UserPersonalInfo> call({required UserPersonalInfo params}) {
    return _getStoryRepository.getSpecificStoriesInfo(userInfo: params);
  }
}
