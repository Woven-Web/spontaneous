import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spontaneous/src/survey/survey_view.dart';

class AuthenticateView extends StatefulWidget {
  const AuthenticateView({super.key});

  static const routeName = '/';

  @override
  State<AuthenticateView> createState() => _AuthenticateViewState();
}

class _AuthenticateViewState extends State<AuthenticateView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkForEmailLink();
  }

  void _checkForEmailLink() async {
    // Get the deep link from the email
    final Uri? deepLink = Uri.base;
    if (deepLink != null && _auth.isSignInWithEmailLink(deepLink.toString())) {
      // Prompt the user for their email address
      String? email = await _getEmailFromUser();
      if (email != null) {
        try {
          await _auth.signInWithEmailLink(
              email: email, emailLink: deepLink.toString());
          // Navigate to the home page on successful sign-in
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SurveyView()));
        } catch (error) {
          // Handle error
          print('Error signing in with email link: $error');
        }
      }
    }
  }

  Future<String?> _getEmailFromUser() async {
    // Prompt the user to enter their email
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String email = '';
        return AlertDialog(
          title: Text('Enter your email'),
          content: TextField(
            onChanged: (value) {
              email = value;
            },
            decoration: InputDecoration(hintText: "Email"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(email);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authenticate'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _sendSignInLinkToEmail,
              child: Text('Send Sign-In Link'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendSignInLinkToEmail() async {
    String email = 'ag@unforced.org'; // Replace with the user's email
    ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      url: 'https://spontaneous-bsw.web.app',
      handleCodeInApp: true,
      iOSBundleId: 'org.wovenweb.spontaneous',
      androidPackageName: 'org.wovenweb.spontaneous',
      androidInstallApp: true,
      androidMinimumVersion: '11',
    );

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      // Save the email locally for use when signing in with the link
      // Securely save the email here
      print('Sign-in link sent!');
    } catch (error) {
      print('Failed to send sign-in link: $error');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SurveyView()),
      );
    } catch (error) {
      print('Error signing in with Google: $error');
    }
  }
}
