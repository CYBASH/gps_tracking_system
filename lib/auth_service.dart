import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Sign Up with username, email, and password
  Future<UserCredential> signUp(
      String email, String password, String username) async {
    // Create user with email and password
    UserCredential userCredential =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("11111111111111111111111111111111111111111");
    // Store username in Firestore after successful sign-up
    try {
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'email': email,
      });
      print('✅ Username stored successfully in Firestore!');
    } catch (e) {
      print('❌ Failed to store username: $e');
    }

    print("22222222222222222222222222222222222222222222222");

    return userCredential;
  }

  // Sign in using email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign in using username and password
  Future<UserCredential> signInWithUsername(
      String username, String password) async {
    String email = "";
    // Query Firestore to get the email associated with the username
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this username.',
        );
      }

      // Get email from the query result
      email = query.docs.first['email'];
    } catch (e) {
      print("Firestore error: $e");
      throw FirebaseAuthException(
        code: 'firestore-error',
        message: 'Failed to connect to Firestore. Please try again later.',
      );
    }

    // Authenticate using the retrieved email and password
    return await signIn(email, password);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
