importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBP26iBMwbwk_i1Ew49oioMnZugzSFfKm4",
    authDomain: "senagromarket-d25ea.firebaseapp.com",
    databaseURL: "https://senagromarket-d25ea-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "senagromarket-d25ea",
    storageBucket: "senagromarket-d25ea.appspot.com",
    messagingSenderId: "240718836142",
    appId: "1:240718836142:web:936d7456a9aa776d44583f",
    measurementId: "G-3ERCN4P7XB"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});