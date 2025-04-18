const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Callable function to remove a family member
exports.removeFamilyMember = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to perform this action.'
    );
  }

  const callerUid = context.auth.uid;
  const { familyId, memberId } = data;

  // Validate input
  if (!familyId || !memberId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Family ID and member ID are required.'
    );
  }

  try {
    // Get the family document
    const familyRef = admin.firestore().collection('families').doc(familyId);
    const familyDoc = await familyRef.get();

    if (!familyDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Family not found.'
      );
    }

    const familyData = familyDoc.data();
    // Verify the caller is the family creator
    if (familyData.createdBy !== callerUid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only the family creator can remove members.'
      );
    }

    // Start a batch to perform atomic updates
    const batch = admin.firestore().batch();

    // Remove the member from the family's members list
    batch.update(familyRef, {
      members: admin.firestore.FieldValue.arrayRemove(memberId)
    });

    // Get the member's user document
    const userRef = admin.firestore().collection('users').doc(memberId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found.'
      );
    }

    const userData = userDoc.data();
    const familyIds = userData.familyIds || [];
    const currentFamilyId = userData.currentFamilyId;

    // Remove the familyId from the user's familyIds
    if (familyIds.includes(familyId)) {
      batch.update(userRef, {
        familyIds: admin.firestore.FieldValue.arrayRemove(familyId)
      });
    }

    // Update currentFamilyId if it matches the removed family
    if (currentFamilyId === familyId) {
      const remainingFamilyIds = familyIds.filter((id) => id !== familyId);
      const newCurrentFamilyId = remainingFamilyIds.length > 0 ? remainingFamilyIds[0] : null;
      batch.update(userRef, {
        currentFamilyId: newCurrentFamilyId
      });
    }

    // Commit the batch
    await batch.commit();

    return { success: true, message: 'Member removed successfully.' };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      `Failed to remove member: ${error.message}`
    );
  }
});
