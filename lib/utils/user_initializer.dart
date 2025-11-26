import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInitializer {
    static Future<void> ensureUserDocumentExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('⚠️ UserDocumentNoSaveAt，Creating...');

                await docRef.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'userType': 'producer',           'companyName': '',
          'city': '',
          'contact': '',
          'photoURL': '',
          'isAdmin': false,
          'verified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': '',
          'averageRating': 0.0,
          'ratingCount': 0,
          'subscriptionPlan': 'free',
        });

        print('[Check] User doc created');
      } else {
        print('[Check] User doc exists');
      }
    } catch (e) {
      print('[Error] Init failed: $e');
    }
  }

    static Future<void> fixUserDocument(String userId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};

                Map<String, dynamic> updates = {};

        if (!data.containsKey('averageRating')) {
          updates['averageRating'] = 0.0;
        }
        if (!data.containsKey('ratingCount')) {
          updates['ratingCount'] = 0;
        }
        if (!data.containsKey('subscriptionPlan')) {
          updates['subscriptionPlan'] = 'free';
        }
        if (!data.containsKey('fcmToken')) {
          updates['fcmToken'] = '';
        }
        if (!data.containsKey('displayName') || data['displayName'] == null || data['displayName'] == '') {
          updates['displayName'] = data['email']?.split('@')[0] ?? 'User';
        }
        if (!data.containsKey('photoURL')) {
          updates['photoURL'] = '';
        }

        if (updates.isNotEmpty) {
          await docRef.update(updates);
          print('[Update] User doc fixed');
        }
      }
    } catch (e) {
      print('�?Fix UserDocumentFailure: $e');
    }
  }
}
