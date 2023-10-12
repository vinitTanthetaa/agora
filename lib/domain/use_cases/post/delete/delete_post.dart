import 'package:agora/data/models/child_classes/post/post.dart';
import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/domain/repositories/post/post_repository.dart';

class DeletePostUseCase implements UseCase<void, Post> {
  final FireStorePostRepository _deletePostRepository;

  DeletePostUseCase(this._deletePostRepository);

  @override
  Future<void> call({required Post params}) {
    return _deletePostRepository.deletePost(postInfo: params);
  }
}
