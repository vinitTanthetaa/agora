import 'package:agora/data/models/child_classes/post/post.dart';
import 'package:agora/domain/repositories/post/post_repository.dart';
import 'package:agora/core/use_case/use_case.dart';

class GetAllPostsInfoUseCase
    implements UseCaseTwoParams<List<Post>, bool, String> {
  final FireStorePostRepository _getPostRepository;

  GetAllPostsInfoUseCase(this._getPostRepository);

  @override
  Future<List<Post>> call(
      {required bool paramsOne, required String paramsTwo}) {
    return _getPostRepository.getAllPostsInfo(
        isVideosWantedOnly: paramsOne, skippedVideoUid: paramsTwo);
  }
}
