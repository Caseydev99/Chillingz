const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const nodemailer = require("nodemailer");

// Chillingz app theme (kept in sync with lib/core/constants/app_colors.dart).
const THEME = {
  background: "#2D0D47", // AppColors.darkBackgroundBase
  cardBackground: "#4A1574", // AppColors.darkInputFillBase
  buttonGradientStart: "#9F3AF2", // AppColors.primaryButtonGradient start
  buttonGradientEnd: "#7925C7", // AppColors.primaryButtonGradient end / primary
  textPrimary: "#FFFFFF",
  textSecondary: "rgba(255,255,255,0.8)",
  textMuted: "rgba(255,255,255,0.6)",
};

// Hosted on Firebase Hosting (public/logo.png) rather than embedded as a cid
// attachment or a base64 data URI — Gmail and most major webmail clients
// strip both cid inline images and data: URIs from received mail as an
// anti-tracking/spam measure, so a real HTTPS image URL is the only option
// that reliably renders.
const LOGO_URL = "https://chillingz-dca92.web.app/logo.png";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const auth = getAuth();

const gmailUser = defineSecret("GMAIL_USER");
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");

exports.sendPasswordReset = onCall(
  {
    region: "us-central1",
    secrets: [gmailUser, gmailAppPassword],
  },
  async (request) => {
    const email = (request.data && request.data.email || "").trim();
    if (!email) {
      throw new HttpsError("invalid-argument", "An email address is required.");
    }

    let link;
    try {
      link = await auth.generatePasswordResetLink(email);
    } catch (error) {
      logger.warn("generatePasswordResetLink failed", {
        email,
        code: error.code,
        message: error.message,
      });
      // Don't reveal whether the email exists; behave like the default
      // Firebase flow which succeeds silently either way.
      if (error.code === "auth/user-not-found") {
        return { success: true };
      }
      throw new HttpsError("internal", "Could not generate reset link.");
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailUser.value(),
        pass: gmailAppPassword.value(),
      },
    });

    const logoImg = `<img src="${LOGO_URL}" alt="Chillingz" width="160"
              style="display:block;max-width:160px;height:auto;border:0;outline:none;" />`;

    const html = `
      <!doctype html>
      <html>
        <body bgcolor="${THEME.background}"
              style="margin:0;padding:0;background-color:${THEME.background};">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                 bgcolor="${THEME.background}"
                 style="background-color:${THEME.background};margin:0;">
            <tr>
              <td align="center" style="padding:48px 20px;">
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                       bgcolor="${THEME.cardBackground}"
                       style="max-width:420px;background-color:${THEME.cardBackground};
                              border-radius:24px;font-family:'Inter',Arial,sans-serif;">
                  <tr>
                    <td align="center" style="padding:44px 32px 36px 32px;">
                      <table role="presentation" cellpadding="0" cellspacing="0">
                        <tr>
                          <td align="center" style="padding-bottom:32px;">
                            ${logoImg}
                          </td>
                        </tr>
                        <tr>
                          <td align="center" style="padding-bottom:14px;">
                            <h1 style="margin:0;color:${THEME.textPrimary};font-size:22px;
                                       font-weight:700;">
                              Reset your password
                            </h1>
                          </td>
                        </tr>
                        <tr>
                          <td align="center" style="padding-bottom:32px;">
                            <p style="margin:0;color:${THEME.textSecondary};font-size:14px;
                                      line-height:1.6;">
                              Tap the button below to choose a new password for your
                              Chillingz account.
                            </p>
                          </td>
                        </tr>
                        <tr>
                          <td align="center" style="padding-bottom:28px;">
                            <a href="${link}"
                               style="display:inline-block;min-width:200px;padding:16px 36px;
                                      background-color:${THEME.buttonGradientEnd};
                                      background-image:linear-gradient(90deg,
                                        ${THEME.buttonGradientStart},
                                        ${THEME.buttonGradientEnd});
                                      color:${THEME.textPrimary};text-decoration:none;
                                      font-weight:700;font-size:15px;border-radius:100px;
                                      font-family:'Inter',Arial,sans-serif;">
                              Reset Password
                            </a>
                          </td>
                        </tr>
                        <tr>
                          <td align="center">
                            <p style="margin:0;color:${THEME.textMuted};font-size:12px;
                                      line-height:1.6;">
                              If you didn't request this, you can safely ignore this email.
                            </p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
      </html>
    `;

    await transporter.sendMail({
      from: `"Chillingz" <${gmailUser.value()}>`,
      to: email,
      subject: "Reset your Chillingz password",
      html,
    });

    return { success: true };
  },
);

// Self-service account deletion, called from the "Delete my account" web page
// (public/delete-account.html) after the user signs in with their Chillingz
// credentials. onCall automatically verifies the caller's ID token, so
// request.auth.uid is trustworthy here — this can only ever delete the
// signed-in user's own account, never someone else's.
exports.deleteMyAccount = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to delete your account.",
      );
    }

    try {
      // Removes the user document and any subcollections (e.g. per-user
      // notifications) in one call.
      await db.recursiveDelete(db.collection("users").doc(uid));
    } catch (error) {
      logger.warn("Failed to delete Firestore data for user", {
        uid,
        message: error.message,
      });
      throw new HttpsError("internal", "Could not delete your account data.");
    }

    try {
      await auth.deleteUser(uid);
    } catch (error) {
      logger.warn("Failed to delete Auth user", {
        uid,
        message: error.message,
      });
      throw new HttpsError(
        "internal",
        "Your data was deleted, but we couldn't remove your sign-in "
          + "credentials. Please contact support.",
      );
    }

    return { success: true };
  },
);

exports.sendNotificationOnCreate = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const notification = snapshot.data() || {};
    const title = firstText([
      notification.title,
      notification.heading,
      notification.subject,
    ]) || "Chillingz";
    const body = firstText([
      notification.message,
      notification.body,
      notification.description,
      notification.text,
    ]);

    if (!body) {
      await markSkipped(snapshot.ref, "missing-message");
      return;
    }

    const usersSnapshot = await db.collection("users").get();
    const tokensByUserId = new Map();
    const tokenToUserId = new Map();

    for (const userDoc of usersSnapshot.docs) {
      const data = userDoc.data() || {};
      if (!isAudienceMatch(notification, data, userDoc.id)) {
        continue;
      }

      for (const token of userTokens(data)) {
        tokensByUserId.set(userDoc.id, [
          ...(tokensByUserId.get(userDoc.id) || []),
          token,
        ]);
        tokenToUserId.set(token, userDoc.id);
      }
    }

    const tokens = Array.from(tokenToUserId.keys());
    if (tokens.length === 0) {
      await markSkipped(snapshot.ref, "no-user-fcm-tokens");
      return;
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: notificationData(notification),
      android: {
        priority: "high",
        notification: {
          channelId: "chillingz_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
      tokens,
    };

    const response = await messaging.sendEachForMulticast(message);
    const invalidTokens = [];

    response.responses.forEach((result, index) => {
      if (result.success) {
        return;
      }

      const code = result.error && result.error.code;
      logger.warn("FCM send failed", {
        notificationId: event.params.notificationId,
        token: tokens[index],
        code,
        message: result.error && result.error.message,
      });

      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    await Promise.all([
      snapshot.ref.set(
        {
          fcmStatus: response.failureCount === tokens.length
            ? "failed"
            : "sent",
          fcmSuccessCount: response.successCount,
          fcmFailureCount: response.failureCount,
          fcmSentAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
      removeInvalidTokens(invalidTokens, tokenToUserId),
    ]);
  },
);

function firstText(values) {
  for (const value of values) {
    const text = value == null ? "" : String(value).trim();
    if (text) {
      return text;
    }
  }
  return "";
}

function userTokens(user) {
  const tokens = new Set();
  if (typeof user.fcmToken === "string" && user.fcmToken.trim()) {
    tokens.add(user.fcmToken.trim());
  }
  if (Array.isArray(user.fcmTokens)) {
    for (const token of user.fcmTokens) {
      if (typeof token === "string" && token.trim()) {
        tokens.add(token.trim());
      }
    }
  }
  return Array.from(tokens);
}

function isAudienceMatch(notification, user, userId) {
  const targetUserId = firstText([
    notification.userId,
    notification.uid,
    notification.authUid,
    notification.recipientId,
    notification.recipientUid,
    notification.targetUserId,
  ]);
  if (targetUserId) {
    return targetUserId === userId || targetUserId === firstText([user.id]);
  }

  if (Array.isArray(notification.recipients)) {
    return notification.recipients.includes(userId) ||
      notification.recipients.includes(firstText([user.id]));
  }

  const audience = firstText([
    notification.audience,
    notification.targetAudience,
    notification.audienceType,
  ]).toLowerCase();

  if (!audience || isAllUsersAudience(audience)) {
    return true;
  }
  if (isNewUsersAudience(audience)) {
    return isNewUser(user);
  }

  return false;
}

function isAllUsersAudience(audience) {
  return [
    "all",
    "all users",
    "all-users",
    "all_users",
    "everyone",
  ].includes(audience);
}

function isNewUsersAudience(audience) {
  return [
    "new",
    "new users",
    "new-users",
    "new_users",
  ].includes(audience);
}

function isNewUser(user) {
  const createdAt = dateValue(user.createdAt);
  if (!createdAt) {
    return false;
  }
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  return Date.now() - createdAt.getTime() <= sevenDaysMs;
}

function dateValue(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function notificationData(notification) {
  const data = {
    route: "notifications",
    type: firstText([notification.type, notification.targetType]),
    target: firstText([notification.target]),
    targetCollection: firstText([notification.targetCollection]),
    targetTitle: firstText([notification.targetTitle]),
  };

  return Object.fromEntries(
    Object.entries(data).filter(([, value]) => value !== ""),
  );
}

async function markSkipped(ref, reason) {
  await ref.set(
    {
      fcmStatus: "skipped",
      fcmSkipReason: reason,
      fcmSentAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function removeInvalidTokens(tokens, tokenToUserId) {
  if (tokens.length === 0) {
    return;
  }

  const updates = tokens.map((token) => {
    const userId = tokenToUserId.get(token);
    if (!userId) {
      return Promise.resolve();
    }

    return db.collection("users").doc(userId).set(
      {
        fcmTokens: FieldValue.arrayRemove(token),
      },
      { merge: true },
    );
  });

  await Promise.all(updates);
}
