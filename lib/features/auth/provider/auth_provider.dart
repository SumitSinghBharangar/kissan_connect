import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  // Add these two instance declarations:
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _verificationId = '';
  int? _resendToken;
  bool _isLoading = false;
  int _timerSeconds = 60;
  Timer? _timer;

  bool get isLoading => _isLoading;
  int get timerSeconds => _timerSeconds;
  String get verificationId => _verificationId;

  void startResendTimer() {
    _timer?.cancel();
    _timerSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  // Send OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        _isLoading = false;
        notifyListeners();
        onError(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _isLoading = false;
        startResendTimer();
        notifyListeners();
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
    );
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String otp,
    required Function(String) onError,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Create user document in Firestore if it doesn't exist
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'phone': userCredential.user!.phoneNumber,
                'createdAt': FieldValue.serverTimestamp(),
                'role': 'Farmer',
              });
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError('Invalid OTP. Please try again.');
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}