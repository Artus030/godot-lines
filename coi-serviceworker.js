let coepCredentialless = false;
if (typeof window !== 'undefined') {
    coepCredentialless = window.crossOriginEmbedderPolicy === 'credentialless';
}

const n = navigator;
if (n.serviceWorker) {
    n.serviceWorker.register(document.currentScript.src).then(
        (registration) => {
            console.log('COOP/COEP Service Worker registered', registration.scope);
            registration.addEventListener('updatefound', () => {
                window.location.reload();
            });
            if (registration.active && !n.serviceWorker.controller) {
                window.location.reload();
            }
        },
        (err) => {
            console.error('COOP/COEP Service Worker failed: ', err);
        }
    );
}