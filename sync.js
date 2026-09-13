const admin = require("firebase-admin");
const serviceAccount = require("C:/src/aiaprtd_member/aiaprtd-member-firebase-adminsdk-jntls-cd2ef97669.json");
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function syncCollections() {
    console.log("Starting sync...");
    
    // Sync Members
    const membersSnap = await db.collection("web_sync_member").get();
    let memberCount = 0;
    for (const doc of membersSnap.docs) {
        await db.collection("member").doc(doc.id).set(doc.data(), { merge: true });
        memberCount++;
    }
    console.log(`Synced ${memberCount} members.`);

    // Sync Vehicles
    const vehiclesSnap = await db.collection("web_sync_vehicles").get();
    let vehicleCount = 0;
    for (const doc of vehiclesSnap.docs) {
        await db.collection("vehicles").doc(doc.id).set(doc.data(), { merge: true });
        vehicleCount++;
    }
    console.log(`Synced ${vehicleCount} vehicles.`);
    
    console.log("Done!");
}

syncCollections().catch(console.error);
