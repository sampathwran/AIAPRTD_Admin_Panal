const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, updateDoc, doc } = require('firebase/firestore');
const firebaseConfig = {
  apiKey: 'AIzaSyCDBGrVPwHFh3gNs_AXY7o1lFfsBw_1B00',
  authDomain: 'aiaprtd-member.firebaseapp.com',
  projectId: 'aiaprtd-member'
};
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
async function run() {
  const snapshot = await getDocs(collection(db, 'member'));
  let count = 0;
  for (const document of snapshot.docs) {
    const data = document.data();
    if (data.user_email && data.user_email !== data.user_email.toLowerCase()) {
      await updateDoc(doc(db, 'member', document.id), { user_email: data.user_email.toLowerCase() });
      count++;
    }
  }
  console.log('Reverted ' + count + ' emails to lowercase!');
  process.exit(0);
}
run();