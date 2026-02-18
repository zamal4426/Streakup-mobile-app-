import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'storage_service.dart';

class AuthService {
  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  static User? get currentUser =>
      _isDesktop ? null : FirebaseAuth.instance.currentUser;

  static bool get isSignedIn =>
      _isDesktop ? StorageService.isLoggedIn : FirebaseAuth.instance.currentUser != null;

  // --- Google Sign In ---
  static Future<User?> signInWithGoogle() async {
    if (_isDesktop) {
      await StorageService.setUserName('Desktop User');
      await StorageService.setLoggedIn(true);
      return null;
    }

    final googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await StorageService.setUserName(user.displayName ?? 'User');
      await StorageService.setUserEmail(user.email ?? '');
      await StorageService.setSignInMethod('Google');
      await StorageService.setLoggedIn(true);
    }

    return user;
  }

  // --- Email + Password Login ---
  static Future<User?> signInWithEmail(String email, String password) async {
    if (_isDesktop) {
      await StorageService.setUserName('Desktop User');
      await StorageService.setLoggedIn(true);
      return null;
    }

    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;

    if (user != null) {
      await StorageService.setUserName(user.displayName ?? 'User');
      await StorageService.setUserEmail(user.email ?? email);
      await StorageService.setSignInMethod('Email');
      await StorageService.setLoggedIn(true);
    }

    return user;
  }

  // --- Register with Email ---
  static Future<User?> registerWithEmail(
      String name, String email, String password) async {
    if (_isDesktop) {
      await StorageService.setUserName(name);
      await StorageService.setLoggedIn(true);
      return null;
    }

    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;

    if (user != null) {
      await user.updateDisplayName(name);
      await StorageService.setUserName(name);
      await StorageService.setUserEmail(user.email ?? email);
      await StorageService.setSignInMethod('Email');
      await StorageService.setLoggedIn(true);
    }

    return user;
  }

  // --- Profile Photo ---
  static Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<String?> uploadProfilePhoto(File imageFile) async {
    // Always save locally first so the photo shows immediately
    await StorageService.setProfilePhotoPath(imageFile.path);

    if (_isDesktop) return imageFile.path;

    final user = currentUser;
    if (user == null) return imageFile.path;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded-by': user.uid},
      );

      await ref.putFile(imageFile, metadata);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await StorageService.setProfilePhotoPath(url);
      return url;
    } catch (e) {
      debugPrint('Firebase Storage upload failed: $e');
      return imageFile.path;
    }
  }

  // --- Forgot Password ---
  static Future<void> sendPasswordResetEmail(String email) async {
    if (_isDesktop) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // --- Update Display Name ---
  static Future<void> updateDisplayName(String name) async {
    await StorageService.setUserName(name);
    if (!_isDesktop) {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
    }
  }

  // --- Sign Out ---
  static Future<void> signOut() async {
    if (!_isDesktop) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    }
    await StorageService.setLoggedIn(false);
    await StorageService.setUserName('');
    await StorageService.setUserEmail('');
    await StorageService.setSignInMethod('');
  }
}
