const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();

async function recalculateReviewStats(parentCollection, parentId) {
  const parentRef = db.collection(parentCollection).doc(parentId);
  const reviewsSnap = await parentRef
    .collection("reviews")
    .where("status", "==", "active")
    .get();

  let ratingCount = 0;
  let ratingSum = 0;

  for (const reviewDoc of reviewsSnap.docs) {
    const rating = Number(reviewDoc.get("rating"));
    if (!Number.isFinite(rating) || rating <= 0) continue;
    ratingCount += 1;
    ratingSum += rating;
  }

  const avgRating =
    ratingCount > 0 ? Number((ratingSum / ratingCount).toFixed(2)) : 0;

  await parentRef.set(
    {
      stats: {
        avgRating,
        ratingCount,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

exports.syncVenueReviewStats = onDocumentWritten(
  {
    document: "venues/{venueId}/reviews/{reviewId}",
    region: "us-central1",
    retry: true,
  },
  async (event) => {
    const { venueId, reviewId } = event.params;
    await recalculateReviewStats("venues", venueId);
    logger.info("syncVenueReviewStats completed", { venueId, reviewId });
  },
);

exports.syncShowReviewStats = onDocumentWritten(
  {
    document: "shows/{showId}/reviews/{reviewId}",
    region: "us-central1",
    retry: true,
  },
  async (event) => {
    const { showId, reviewId } = event.params;
    await recalculateReviewStats("shows", showId);
    logger.info("syncShowReviewStats completed", { showId, reviewId });
  },
);

exports.archivePastShowsDaily = onSchedule(
  {
    schedule: "every day 03:30",
    timeZone: "Etc/UTC",
    region: "us-central1",
    retryCount: 3,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const pageSize = 400;

    let totalScanned = 0;
    let totalArchived = 0;
    let lastDoc = null;

    while (true) {
      let query = db
        .collection("shows")
        .where("date", "<", now)
        .orderBy("date")
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      let pending = 0;

      for (const doc of snapshot.docs) {
        totalScanned += 1;
        const data = doc.data();
        if (data.isArchived === true) continue;

        batch.update(doc.ref, {
          isArchived: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        pending += 1;
      }

      if (pending > 0) {
        await batch.commit();
        totalArchived += pending;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < pageSize) break;
    }

    logger.info("archivePastShowsDaily completed", {
      scanned: totalScanned,
      archived: totalArchived,
      runAt: new Date().toISOString(),
    });
  }
);
