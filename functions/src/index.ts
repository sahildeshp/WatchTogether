import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();

// Invite code alphabet — excludes ambiguous characters (0/O, 1/I/L)
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 6;
const INVITE_TTL_MS = 48 * 60 * 60 * 1000; // 48 hours

function randomCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

/**
 * Creates a new couple document and an invite code for the calling user.
 * Returns { coupleId: string, inviteCode: string }.
 */
export const createCouple = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  const userId = request.auth.uid;

  // Guard: user must not already be in a couple
  const userSnap = await db.collection("users").doc(userId).get();
  if (userSnap.data()?.coupleId) {
    throw new HttpsError("already-exists", "You are already in a couple.");
  }

  // Generate a unique invite code (retry on collision, max 10 attempts)
  let inviteCode = "";
  for (let attempt = 0; attempt < 10; attempt++) {
    const candidate = randomCode();
    const collision = await db
      .collection("couples")
      .where("inviteCode", "==", candidate)
      .limit(1)
      .get();
    if (collision.empty) {
      inviteCode = candidate;
      break;
    }
  }
  if (!inviteCode) {
    throw new HttpsError("internal", "Could not generate a unique code. Please try again.");
  }

  const inviteExpiresAt = new Date(Date.now() + INVITE_TTL_MS);
  const coupleRef = db.collection("couples").doc();

  await db.runTransaction(async (tx) => {
    tx.set(coupleRef, {
      memberIds: [userId],
      inviteCode,
      inviteExpiresAt,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(db.collection("users").doc(userId), {
      coupleId: coupleRef.id,
    });
  });

  return { coupleId: coupleRef.id, inviteCode };
});

/**
 * Joins an existing couple using an invite code.
 * Returns { coupleId: string }.
 */
export const joinCouple = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  const userId = request.auth.uid;
  const { inviteCode } = request.data as { inviteCode?: string };

  if (!inviteCode || typeof inviteCode !== "string") {
    throw new HttpsError("invalid-argument", "inviteCode is required.");
  }
  const code = inviteCode.trim().toUpperCase();

  // Guard: calling user must not already be in a couple
  const userSnap = await db.collection("users").doc(userId).get();
  if (userSnap.data()?.coupleId) {
    throw new HttpsError("already-exists", "You are already in a couple.");
  }

  // Find the couple document with this invite code
  const snap = await db
    .collection("couples")
    .where("inviteCode", "==", code)
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError("not-found", "Invalid or expired invite code.");
  }

  const coupleDoc = snap.docs[0];
  const coupleData = coupleDoc.data();

  // Check expiry
  const expiresAt: Date | undefined = coupleData.inviteExpiresAt?.toDate();
  if (expiresAt && expiresAt < new Date()) {
    throw new HttpsError("deadline-exceeded", "This invite code has expired.");
  }

  const memberIds = coupleData.memberIds as string[];

  // Guard: couple must not be full
  if (memberIds.length >= 2) {
    throw new HttpsError("resource-exhausted", "This couple already has two members.");
  }

  // Guard: user cannot join their own couple
  if (memberIds.includes(userId)) {
    throw new HttpsError("already-exists", "You created this couple — share the code with your partner.");
  }

  await db.runTransaction(async (tx) => {
    tx.update(coupleDoc.ref, {
      memberIds: FieldValue.arrayUnion(userId),
      // Invalidate the code after it's used
      inviteCode: FieldValue.delete(),
      inviteExpiresAt: FieldValue.delete(),
    });
    tx.update(db.collection("users").doc(userId), {
      coupleId: coupleDoc.id,
    });
  });

  // Notify the couple creator that their partner has joined
  const creatorId = memberIds[0];
  const joinerSnap = await db.collection("users").doc(userId).get();
  const joinerName: string = joinerSnap.data()?.displayName ?? "Your partner";
  const creatorSnap = await db.collection("users").doc(creatorId).get();
  const fcmToken: string | undefined = creatorSnap.data()?.fcmToken;
  if (fcmToken) {
    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "Partner joined! 🎉",
          body: `${joinerName} just joined using your invite code.`,
        },
      });
    } catch (e) {
      // Non-fatal — don't fail the join if the notification can't be sent
      console.error("FCM notification failed:", e);
    }
  }

  return { coupleId: coupleDoc.id };
});
