// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class ProfilePictureUpdateDialog extends StatefulWidget {
  final User? user;

  const ProfilePictureUpdateDialog({Key? key, required this.user}) : super(key: key);

  @override
  _ProfilePictureUpdateDialogState createState() => _ProfilePictureUpdateDialogState();
}

class _ProfilePictureUpdateDialogState extends State<ProfilePictureUpdateDialog> {
  File? _imageFile;
  final Logger logger = Logger();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        logger.i('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      logger.w('No image selected for upload.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
      return;
    }

    try {
      logger.i('Uploading image to Firebase Storage...');
      final Reference ref = FirebaseStorage.instance.ref().child('profile_pictures/${widget.user?.uid}.jpg');
      await ref.putFile(_imageFile!);

      String downloadURL = await ref.getDownloadURL();
      logger.i('Image uploaded successfully, download URL: $downloadURL');

      await widget.user?.updatePhotoURL(downloadURL);
      logger.i('User profile photo URL updated.');

      // Update user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({
        'profilePictureUrl': downloadURL,
      });
      logger.i('User document updated in Firestore.');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );

      Navigator.of(context).pop(downloadURL);
    } catch (e) {
      logger.e('Failed to update profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Profile Picture'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                fit: BoxFit.cover,
                height: 200,
              )
            else
              Image.asset(
                'assets/images/profilepicture.png',
                height: 50,
                width: 70,
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Choose from Gallery'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text('Take a Photo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: _uploadImage,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
