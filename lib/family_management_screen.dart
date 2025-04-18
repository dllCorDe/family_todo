import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _acceptInvitation(String invitationId, String familyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update the user's familyIds and set currentFamilyId
      await _firestore.collection('users').doc(user.uid).set(
        {
          'familyIds': FieldValue.arrayUnion([familyId]),
          'currentFamilyId': familyId,
        },
        SetOptions(merge: true),
      );

      // Mark the invitation as used
      await _firestore.collection('invitations').doc(invitationId).update({
        'used': true,
      });

      // Add the user to the family's members list
      await _firestore.collection('families').doc(familyId).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined family successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept invitation: $e')),
        );
      }
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    try {
      // Mark the invitation as used (declined)
      await _firestore.collection('invitations').doc(invitationId).update({
        'used': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline invitation: $e')),
        );
      }
    }
  }

  Future<void> _switchFamily(String familyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set(
        {
          'currentFamilyId': familyId,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch family: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String familyId, String memberId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated. Please sign in again.')),
          );
        }
        return;
      }

      // Force refresh the user's token to ensure it's valid
      await user.getIdToken(true);
      print('Token refreshed for user: ${user.uid}');

      // Check if the current user is the creator of the family
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (familyDoc.data()!['createdBy'] != user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only the family creator can remove members.')),
          );
        }
        return;
      }

      // Remove the member from the family
      await _firestore.collection('families').doc(familyId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });
      print('Removed $memberId from family $familyId members list');

      // Get the user's document to check their familyIds and currentFamilyId
      final memberDoc = await _firestore.collection('users').doc(memberId).get();
      if (!memberDoc.exists) {
        print('Member document for $memberId not found');
        return;
      }

      final memberData = memberDoc.data() as Map<String, dynamic>;
      final List<String> memberFamilyIds = List<String>.from(memberData['familyIds'] ?? []);
      final String? currentFamilyId = memberData['currentFamilyId'];

      // Remove the family from the member's familyIds
      await _firestore.collection('users').doc(memberId).set(
        {
          'familyIds': FieldValue.arrayRemove([familyId]),
        },
        SetOptions(merge: true),
      );
      print('Removed $familyId from $memberId\'s familyIds: $memberFamilyIds');

      // Update currentFamilyId if it matches the removed family
      if (currentFamilyId == familyId) {
        memberFamilyIds.remove(familyId); // Update local copy after removal
        String? newCurrentFamilyId;
        if (memberFamilyIds.isNotEmpty) {
          newCurrentFamilyId = memberFamilyIds.first; // Set to the first remaining family
        } else {
          newCurrentFamilyId = null; // No families left
        }
        await _firestore.collection('users').doc(memberId).set(
          {
            'currentFamilyId': newCurrentFamilyId,
          },
          SetOptions(merge: true),
        );
        print('Updated $memberId\'s currentFamilyId from $familyId to $newCurrentFamilyId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully.')),
        );
      }
    } catch (e) {
      print('Error removing member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final List<String> familyIds = List<String>.from(userData['familyIds'] ?? []);
          final String? currentFamilyId = userData['currentFamilyId'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Your Families',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (familyIds.isEmpty)
                const Text('You are not part of any families yet.')
              else
                ...familyIds.map((familyId) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('families').doc(familyId).snapshots(),
                    builder: (context, familySnapshot) {
                      if (familySnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading family...'),
                        );
                      }
                      if (!familySnapshot.hasData || !familySnapshot.data!.exists) {
                        return const ListTile(
                          title: Text('Family not found'),
                        );
                      }

                      final familyData = familySnapshot.data!.data() as Map<String, dynamic>;
                      final List<String> members = List<String>.from(familyData['members'] ?? []);
                      final String creatorId = familyData['createdBy'];
                      final bool isCreator = creatorId == user.uid;
                      final bool isCurrentFamily = familyId == currentFamilyId;

                      return Card(
                        child: ExpansionTile(
                          title: Text('Family ID: $familyId'),
                          subtitle: Text(isCurrentFamily ? 'Current Family' : 'Tap to switch'),
                          onExpansionChanged: (expanded) {
                            if (!expanded && !isCurrentFamily) {
                              _switchFamily(familyId);
                            }
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Members:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  ...members.map((memberId) {
                                    return ListTile(
                                      title: Text('User ID: $memberId'),
                                      trailing: isCreator && memberId != user.uid
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                                              onPressed: () => _removeMember(familyId, memberId),
                                              tooltip: 'Remove Member',
                                            )
                                          : null,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              const SizedBox(height: 16),
              const Text(
                'Pending Invitations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('invitations')
                    .where('email', isEqualTo: userData['email'])
                    .where('used', isEqualTo: false)
                    .snapshots(),
                builder: (context, inviteSnapshot) {
                  if (inviteSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!inviteSnapshot.hasData || inviteSnapshot.data!.docs.isEmpty) {
                    return const Text('No pending invitations.');
                  }

                  final invites = inviteSnapshot.data!.docs;
                  return Column(
                    children: invites.map((inviteDoc) {
                      final inviteData = inviteDoc.data() as Map<String, dynamic>;
                      final String familyId = inviteData['familyId'];
                      return ListTile(
                        title: Text('Invitation to Family: $familyId'),
                        subtitle: Text('Created at: ${inviteData['createdAt']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptInvitation(inviteDoc.id, familyId),
                              tooltip: 'Accept',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _declineInvitation(inviteDoc.id),
                              tooltip: 'Decline',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}