import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/data/models/parent_classes/without_sub_classes/comment.dart';
import 'package:agora/domain/repositories/post/comment/comment_repository.dart';

class GetSpecificCommentsUseCase implements UseCase<List<Comment>, String> {
  final FirestoreCommentRepository _getAllCommentsRepository;

  GetSpecificCommentsUseCase(this._getAllCommentsRepository);

  @override
  Future<List<Comment>> call({required String params}) {
    return _getAllCommentsRepository.getSpecificComments(postId: params);
  }
}
