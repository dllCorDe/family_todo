import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _joinKeyController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _errorMessage;

  Future<void> _joinFamily() async {
    final joinKey = _joinKeyController.text.trim();
    if (joinKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a join key.';
      });
      return;
    }

    try {
      final invitationDoc = await _firestore.collection('invitations').doc(joinKey).get();
      if (!invitationDoc.exists) {
        setState(() {
          _errorMessage = 'Invalid join key.';
        });
        return;
      }

      final invitationData = invitationDoc.data()!;
      if (invitationData['used']) {
        setState(() {
          _errorMessage = 'This join key has already been used.';
        });
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please sign in again.';
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User data not found. Please sign up again.';
        });
        return;
      }

      if (userDoc.data()!['email'] != invitationData['email']) {
        setState(() {
          _errorMessage = 'This join key is not valid for your email address.';
        });
        return;
      }

      // Update the user's familyId
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': invitationData['familyId'],
      });

      // Mark the invitation as used
      await _firestore.collection('invitations').doc(joinKey).update({
        'used': true,
      });

      // Add the user to the family's members list
      await _firestore.collection('families').doc(invitationData['familyId']).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // Navigate to the ToDoHomePage (handled by the StreamBuilder in main.dart)
    } catch (e) {
      setState(() {
        _errorMessage = 'Error joining family: $e';
      });
    }
  }

  Future<void> _createFamily() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please sign in again.';
        });
        return;
      }

      // Create a new family
      final familyRef = await _firestore.collection('families').add({
        'createdBy': user.uid,
        'members': [user.uid],
      });

      // Update the user's familyId
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': familyRef.id,
      });

      // Navigation to ToDoHomePage will be handled by the StreamBuilder in main.dart
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating family: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join or Create a Family'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter a join key to join an existing family, or create a new one.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _joinKeyController,
              decoration: const InputDecoration(labelText: 'Join Key (Optional)'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _joinFamily,
                  child: const Text('Join Family'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _createFamily,
                  child: const Text('Create a New Family'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _joinKeyController.dispose();
    super.dispose();
  }
}