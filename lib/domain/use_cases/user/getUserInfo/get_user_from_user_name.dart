import 'package:agora/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:agora/domain/repositories/user_repository.dart';
import 'package:agora/core/use_case/use_case.dart';

class GetUserFromUserNameUseCase implements UseCase<UserPersonalInfo?, String> {
  final FirestoreUserRepository _getUserFromUserNameRepository;

  GetUserFromUserNameUseCase(this._getUserFromUserNameRepository);

  @override
  Future<UserPersonalInfo?> call({required String params}) {
    return _getUserFromUserNameRepository.getUserFromUserName(userName: params);
  }
}
