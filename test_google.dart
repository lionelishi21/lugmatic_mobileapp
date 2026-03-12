import 'package:google_sign_in/google_sign_in.dart';

void main() {
  try {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    print('GoogleSignIn initialized correctly');
  } catch (e) {
    print('Error: $e');
  }
}
