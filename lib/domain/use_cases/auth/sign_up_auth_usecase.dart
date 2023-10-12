import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora/core/use_case/use_case.dart';
import 'package:agora/domain/entities/registered_user.dart';
import '../../repositories/auth_repository.dart';

class SignUpAuthUseCase implements UseCase<User, RegisteredUser> {
  final FirebaseAuthRepository _firebaseAuthRepository;

  SignUpAuthUseCase(this._firebaseAuthRepository);

  @override
  Future<User> call({required RegisteredUser params}) {
    return _firebaseAuthRepository.signUp(params);
  }
}
