import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../models/app_user.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authChanges => _auth.authStateChanges();

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      uid: credential.user!.uid,
      name: name.trim(),
      email: email.trim(),
    );
    await _userDoc(user.uid).set(user.toMap());
    return user;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser?> getUser() async {
    final id = uid;
    if (id == null) return null;
    final doc = await _userDoc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Stream<AppUser?> watchUser() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _userDoc(id)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);
  }

  Future<void> updateName(String name) async {
    await _userDoc(uid!).update({'name': name.trim()});
  }

  Future<void> updateTheme(String themeMode) async {
    await _userDoc(uid!).update({'themeMode': themeMode});
  }

  Future<void> updateWatch(Map<String, dynamic>? watch) async {
    await _userDoc(uid!).update({'watch': watch});
  }
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // Re-authenticate the user first.
    await user.reauthenticateWithCredential(credential);

    // Send verification email to the new address.
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);
  }
}
