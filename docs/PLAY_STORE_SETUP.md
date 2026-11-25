# Google Play setup: automatic updates for testers

When this is done, every change merged into `main` is built, signed and uploaded to
Google Play **Internal testing** automatically. Testers' phones update RS Ludo through
the Play Store; nobody downloads or installs files by hand.

| | |
| --- | --- |
| App name | RS Ludo |
| Package ID | `com.rsludo.game` (permanent once uploaded) |
| Track | Internal testing (up to 100 invited testers, no review wait) |
| Cost | US$25 once, for the Google Play developer account |

The steps marked **(you)** need your Google account; nobody else can do them.
Never paste passwords, key files or the service-account JSON into chat or into the code.

---

## 1. Developer account (you, once)

1. Go to https://play.google.com/console/signup and sign in with the Google account that will own the game.
2. Choose a **personal** account (an organisation account needs a D-U-N-S number).
3. Pay the US$25 fee and complete identity verification. Verification can take a few days.

## 2. Create the app (you, once)

1. Play Console > **Create app**.
2. App name **RS Ludo**, language, **Game**, **Free**. Accept the declarations.
3. Leave **Play App Signing** on (the default). Google keeps the final signing key; you
   sign uploads with your own *upload key* (next step). If the upload key is ever lost,
   Google support can reset it.

## 3. Make the upload key (you, once, on a computer)

1. Install a free Java (it includes `keytool`): https://adoptium.net (Temurin 17), or use Android Studio.
2. In a terminal, run:

   ```sh
   keytool -genkeypair -v -keystore rsludo-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

   Choose a strong password and answer the name questions (any values are fine).
3. Store `rsludo-upload.keystore` and its password safely (password manager and a backup).
   Do not commit the file.
4. Turn the file into one line of text (base64) and copy it:
   - Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("rsludo-upload.keystore")) | Set-Clipboard`
   - macOS: `base64 -i rsludo-upload.keystore | pbcopy`
   - Linux: `base64 -w0 rsludo-upload.keystore`

## 4. Add the key to GitHub (you, once)

On GitHub: **RsLUDO > Settings > Secrets and variables > Actions**.

**Secrets** tab, **New repository secret**, three times:

| Name | Value |
| --- | --- |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | the base64 text from step 3.4 |
| `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_UPLOAD_KEY_ALIAS` | `upload` |

**Variables** tab, **New repository variable**: `PLAY_RELEASE_STATUS` = `draft`
(Google only accepts draft uploads until the app's first release has been rolled out).

GitHub never shows secrets again after saving them, and they are hidden in logs.

## 5. First release by hand (you, once)

Google requires the very first bundle to be uploaded in the Play Console.

1. Once a change is in `main`, open **Actions > Google Play internal testing**, pick the
   latest run and download the artifact `RSLudo-release-aab-...`. Unzip it to get
   `RSLudo-release.aab`. (You can also start a run with **Run workflow**.)
2. Play Console > RS Ludo > **Test and release > Testing > Internal testing > Create new release**.
3. Upload `RSLudo-release.aab`, keep the suggested release name, **Next**, **Save and publish**
   (or **Start rollout to Internal testing**).
4. **Testers** tab: create an email list and add each tester's Gmail address. Copy the
   **join link** and send it to the testers. Each tester opens it on their phone, taps
   **Accept**, then installs RS Ludo from the Play Store.

Play Console may first ask you to fill in **App content** items. For the current offline
game the honest answers are: no ads; no data collected or shared; no login needed;
target age group 13 and over (choosing younger ages adds Google's Families requirements);
content rating questionnaire: no violence, gambling or user interaction yet. A privacy
policy link may be required: ask Claude to write one and publish it free on GitHub Pages.

## 6. Automatic uploads (you, once)

1. Google Cloud console: https://console.cloud.google.com > create a project (e.g. `rs-ludo-release`).
2. **APIs & Services > Enable APIs** > enable **Google Play Android Developer API**.
3. **IAM & Admin > Service accounts > Create service account**, name `play-uploader`,
   no roles needed. Open it > **Keys > Add key > JSON**. A `.json` file downloads.
4. Play Console > **Users and permissions > Invite new users**: paste the service account's
   email (ends in `iam.gserviceaccount.com`), **App permissions** > add RS Ludo > allow
   **Release apps to testing tracks** (and view app information) > **Invite**.
5. GitHub secret `PLAY_SERVICE_ACCOUNT_JSON` = the whole contents of the `.json` file.
   Then delete the downloaded file from your computer.
6. After the first release (step 5) is rolled out, delete the `PLAY_RELEASE_STATUS`
   variable so uploads go live for testers straight away. If a later run fails with
   "Only releases with status draft may be created on draft app", put the variable back
   to `draft`; uploads then wait as drafts and need one click (**Review > Roll out**).

## How updates reach phones

1. A change is merged into `main`.
2. GitHub builds and uploads a new version (about 10 minutes). Each build gets a higher version code automatically.
3. Google processes it (minutes, sometimes a few hours).
4. Phones update in the background like any Play Store app. To update right away:
   Play Store > profile picture > **Manage apps & device** > **Update**.

## Later: public release

New personal developer accounts must run a **closed test with at least 12 testers for
14 days** before Google allows a production (public) release. That is part of Phase 5.

## Test APK

The debug APK built on every push is now **RS Ludo Test** (`com.rsludo.game.debug`), so it
can be installed next to the Play Store version. The older test app (package
`com.rsludo.ludosocial`, named "Ludo Social") can be uninstalled.
