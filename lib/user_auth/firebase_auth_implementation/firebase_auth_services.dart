// ignore_for_file: prefer_final_fields, avoid_print

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthServices{

  FirebaseAuth _auth = FirebaseAuth.instance;


  Future<User?> signupwithemailandpassword(String email, String password) async{

    try {
      UserCredential credential =await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    }catch(e){
      print("Some error Occurred");
    }
    return null;
  }Future<User?> signinwithemailandpassword(String email, String password) async{

    try {
      UserCredential credential =await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    }catch(e){
      print("Some error Occurred");
    }
    return null;
  }
  
  

}