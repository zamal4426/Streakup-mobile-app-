import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/habit.dart';

class FirestoreService {
  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  static CollectionReference<Map<String, dynamic>>? _habitsRef() {
    final user = AuthService.currentUser;
    if (user == null || _isDesktop) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits');
  }

  /// Upserts a habit to Firestore. Throws on failure so callers can handle it.
  static Future<void> upsertHabit(Habit habit) async {
    final ref = _habitsRef();
    if (ref == null) return;
    try {
      await ref.doc(habit.id).set(habit.toJson());
    } catch (e) {
      debugPrint('FirestoreService.upsertHabit failed for ${habit.id}: $e');
      rethrow;
    }
  }

  /// Deletes a habit document from Firestore. Throws on failure.
  static Future<void> deleteHabit(String habitId) async {
    final ref = _habitsRef();
    if (ref == null) return;
    try {
      await ref.doc(habitId).delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteHabit failed for $habitId: $e');
      rethrow;
    }
  }

  /// Fetches all habits from Firestore. Throws on failure.
  static Future<List<Habit>> fetchAllHabits() async {
    final ref = _habitsRef();
    if (ref == null) return [];
    try {
      final snapshot = await ref.get();
      return snapshot.docs
          .map((doc) => Habit.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('FirestoreService.fetchAllHabits failed: $e');
      rethrow;
    }
  }

  /// Uploads all habits to Firestore in a batch. Throws on failure.
  static Future<void> uploadAll(List<Habit> habits) async {
    final ref = _habitsRef();
    if (ref == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final habit in habits) {
        batch.set(ref.doc(habit.id), habit.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.uploadAll failed: $e');
      rethrow;
    }
  }
}
