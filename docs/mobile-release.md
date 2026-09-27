# Mobiele release

## Android

De releaseworkflow verwacht deze GitHub Actions Secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-inhoud van de upload-keystore
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

De keystore en wachtwoorden mogen nooit in de repository worden opgeslagen. Na het instellen van de secrets kan via **Actions → Build Android release bundle → Run workflow** een ondertekende `.aab` worden gemaakt. Die bundle kan daarna in Google Play Console naar een interne of gesloten test-track.

## iOS

Voor iOS is een macOS-runner met Xcode nodig. Daarvoor moeten in Apple Developer/App Store Connect nog worden ingericht:

- Bundle ID: `nl.verstobbertje.app`
- Distribution certificate
- App Store provisioning profile
- App Store Connect API key of veilige signing-configuratie
- TestFlight-build

## Nog vóór store-indiening

- Definitief app-icon en screenshots
- Privacybeleid met GPS- en backendverwerking
- Google Play Data safety-formulier
- Apple privacyvragen en locatiegebruik
- Leeftijdsclassificatie
- Testaccount of review-instructies
