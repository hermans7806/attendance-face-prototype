import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/staff_account.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<StaffAccount?> getStaffAccount(String uid) async {
    final snapshot = await _firestore.collection('staffs').doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return StaffAccount.fromFirestore(snapshot.id, snapshot.data()!);
  }

  Future<StaffAccount?> syncStaffAccount(User user) async {
    final account = await getStaffAccount(user.uid);
    if (account == null) {
      await _firestore.collection('pending_users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'No Name',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    }

    return account;
  }

  Future<void> signOut() => _auth.signOut();
}
