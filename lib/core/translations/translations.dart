import 'package:get/get.dart';
import 'package:agora/core/translations/langs/ar.dart';
import 'package:agora/core/translations/langs/en.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en': en, 'ar': ar};
}
