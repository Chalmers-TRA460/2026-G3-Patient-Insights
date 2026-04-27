import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1069489323213-n3eknn6qc2rth0nrtecoptnk9t7nqh1i.apps.googleusercontent.com',
  );

  Rx<User?> firebaseUser = Rx<User?>(null);
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onReady() {
    super.onReady();
    ever(firebaseUser, _initialScreen);
  }

  void _initialScreen(User? user) {
    if (user == null) {
      Get.offAllNamed('/login');
    } else {
      Get.offAllNamed('/');
    }
  }

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  // ── Email + Password Register ──
  Future<void> registerWithEmail(String name, String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Set display name
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      firebaseUser.value = _auth.currentUser;
      Get.offAllNamed('/');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        errorMessage.value = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage.value = 'This email is already registered. Try logging in.';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Please enter a valid email address.';
      } else {
        errorMessage.value = e.message ?? 'Registration failed.';
      }
    } catch (e) {
      errorMessage.value = 'Registration error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Email + Password Login ──
  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      Get.offAllNamed('/');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage.value = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage.value = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'Please enter a valid email address.';
      } else if (e.code == 'invalid-credential') {
        errorMessage.value = 'Invalid email or password.';
      } else {
        errorMessage.value = e.message ?? 'Login failed.';
      }
    } catch (e) {
      errorMessage.value = 'Login error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Sign-In ──
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      Get.offAllNamed('/');
    } catch (e) {
      errorMessage.value = 'Google Sign-In failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Password Reset ──
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar('Email Sent', 'Check your email for a password reset link.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Could not send reset email. Check the address.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.offAllNamed('/login');
    }
  }
}
