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

  static Future<void> upsertHabit(Habit habit) async {
    final ref = _habitsRef();
    if (ref == null) return;
    await ref.doc(habit.id).set(habit.toJson());
  }

  static Future<void> deleteHabit(String habitId) async {
    final ref = _habitsRef();
    if (ref == null) return;
    await ref.doc(habitId).delete();
  }

  static Future<List<Habit>> fetchAllHabits() async {
    final ref = _habitsRef();
    if (ref == null) return [];
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => Habit.fromJson(doc.data()))
        .toList();
  }

  static Future<void> uploadAll(List<Habit> habits) async {
    final ref = _habitsRef();
    if (ref == null) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final habit in habits) {
      batch.set(ref.doc(habit.id), habit.toJson());
    }
    await batch.commit();
  }
}
