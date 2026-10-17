# Private Android test signing

No private key is committed. For update-compatible CI test builds, configure repository secrets `THORNWAKE_TEST_KEYSTORE_BASE64` (base64 PKCS12 keystore) and `THORNWAKE_TEST_CERT_SHA256` (certificate digest). Use alias `androiddebugkey` and standard debug password `android`. The workflow verifies the exported APK against the expected digest when secrets are configured. Keep the key privately backed up; use a separate private upload key for store releases.

Without these secrets CI generates a disposable debug identity and records that fact in `Android-signing.txt`. Successive APKs may require uninstalling first; export your save beforehand. Repository secret setup and device migration have not been performed. No signing key is included in source or build artifacts.
