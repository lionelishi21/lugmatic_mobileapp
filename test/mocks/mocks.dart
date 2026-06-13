// Run once to regenerate:
//   flutter pub run build_runner build --delete-conflicting-outputs

import 'package:mockito/annotations.dart';
import 'package:lugmatic_flutter/data/services/auth_service.dart';
import 'package:lugmatic_flutter/core/network/token_storage.dart';
import 'package:lugmatic_flutter/data/services/fcm_service.dart';

@GenerateMocks([AuthService, TokenStorage, FcmService])
void main() {}
