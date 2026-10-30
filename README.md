# ALLAH TALA Share (Android app, Flutter)

Black and gold app to track monthly earnings, the share due (default 10%),
every contribution, and months that were only partly paid.

## What the app does
- Add earnings: the 10% share is calculated and shown live as you type.
- Every month shows Earned / Share due / Paid / Remaining and a status
  (Unpaid, Partial, Paid in full).
- "Pay ALLAH TALA Share" is prefilled with the remaining amount. Enter less to
  record a partial payment; pay the rest later in as many parts as you like.
- Everything is editable later: earnings (amount, rate, date, note) and each
  payment (amount, date, note) via Edit, and deletable with confirmation.
- Settings (top bar): default rate and an optional currency symbol.
- Top bar copy button: copies all records as CSV for backup or a spreadsheet.
- Data is stored on the phone only. Uninstalling the app erases it, so use the
  copy button now and then to keep a backup.

## Get the APK without installing anything (GitHub Actions)
1. Make a free account at github.com and create a new repository
   (private is fine).
2. Click "uploading an existing file" and drag in everything from this
   folder, including the hidden-looking `.github` folder, then Commit.
3. Open the repository's "Actions" tab. "Build Android APK" starts by itself
   (about 5-10 minutes). If it does not, open it and press "Run workflow".
4. When it shows a green tick, open the repository's "Releases" section
   (right side of the main page) and download `app-release.apk`.
   The same file is also under the finished run as "ALLAH-TALA-Share-apk".

## Install on your Android phone
1. Get the APK onto the phone: open the Release page in the phone browser and
   tap `app-release.apk`, or download on a PC and send it by USB, WhatsApp or
   email.
2. Tap the downloaded file. If Android asks, allow "Install unknown apps" for
   your browser or Files app, then tap Install.
3. Open "ALLAH TALA Share" from the app list.
Updating later: build a new APK and install it over the old one. Data is kept.

## If you do have Flutter installed
    flutter create --platforms=android --org com.allahtala --project-name allah_tala_share .
    flutter pub get
    dart run flutter_launcher_icons
    flutter build apk --release
(then set android:label to "ALLAH TALA Share" in
android/app/src/main/AndroidManifest.xml)
