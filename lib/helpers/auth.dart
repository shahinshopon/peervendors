import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth authInstance = FirebaseAuth.instance;
  final String pASSWORD = '2_hE*Llo|wOR9rldS=!-Z';

  Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await authInstance.signInWithEmailAndPassword(
          email: email, password: pASSWORD);
      return result.user.uid;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signInWithEmailAndPasswordToLinkAccount(
      String email, String password) async {
    try {
      UserCredential result = await authInstance.signInWithEmailAndPassword(
          email: email, password: pASSWORD);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<String> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await authInstance.createUserWithEmailAndPassword(
          email: email.toLowerCase(), password: pASSWORD);
      User authenticatedUser = result.user;
      return authenticatedUser.uid;
    } catch (e) {
      return null;
    }
  }

  Future<User> signInWithCreds(PhoneAuthCredential credential) async {
    try {
      UserCredential result =
          await authInstance.signInWithCredential(credential);
      User authenticatedUser = result.user;
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future resetPass(String email) async {
    try {
      return await authInstance.sendPasswordResetEmail(email: email);
    } catch (e) {
      return null;
    }
  }

  AuthCredential getPhoneAuthCredentials(
      {String firebaseVerificationId, String otpCode}) {
    return PhoneAuthProvider.credential(
        verificationId: firebaseVerificationId, smsCode: otpCode);
  }

  Future<bool> signOut() async {
    try {
      await authInstance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}
