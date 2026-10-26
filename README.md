# MemoNest — Personal Knowledge & Study Organizer

MemoNest is an original Flutter mini-project for collecting study notes, ideas, project checklists, and personal thoughts in one calm workspace. It is designed for a college mini-project and runs as a Flutter Web app.

## Problem statement

Students often keep important learning points, project ideas, and reminders in scattered places. MemoNest provides one searchable, categorized workspace where notes can be created, read, edited, pinned, and deleted, with changes saved in the current browser.

## Features

- Responsive dashboard for desktop and smaller screens.
- Create and edit notes with form validation.
- Delete notes with a confirmation step.
- Pin and unpin important notes.
- Categories: Study, Ideas, Projects, and Personal.
- Search across title, body, category, and tags.
- Filter by category or pinned status.
- Sort by most recently updated, oldest first, or title A–Z.
- Optional comma-separated tags and five card colors.
- Starter notes for a meaningful first launch.
- Browser-local persistence through `shared_preferences` on Flutter Web.
- Restore demo data action for demonstration purposes.
- Empty-state messaging and user feedback.
- Widget tests for sample data and note JSON serialization.

## Technology

- Flutter and Dart
- Material 3 widgets
- `shared_preferences` for browser-local storage
- Git and GitHub for source control
- Vercel for hosting the built Flutter Web files

## Project structure

```text
memonest/
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── web/
│   ├── index.html
│   └── manifest.json
├── analysis_options.yaml
├── pubspec.yaml
├── vercel.json
├── .gitignore
└── README.md
```

## Requirements

- Flutter SDK with Dart included
- VS Code (recommended)
- Flutter and Dart extensions for VS Code
- Chrome or another supported browser

## Run locally in VS Code

1. Extract the ZIP file.
2. Open the extracted `memonest` folder in VS Code. Open the folder containing `pubspec.yaml`, not only the `lib` folder.
3. Open **Terminal → New Terminal**.
4. Check the installation:

   ```bash
   flutter --version
   dart --version
   flutter doctor
   ```

5. Resolve dependencies:

   ```bash
   flutter pub get
   ```

6. Check whether Chrome is available:

   ```bash
   flutter devices
   ```

7. Run the web app:

   ```bash
   flutter run -d chrome
   ```

If Chrome is not listed, install Chrome and make sure Flutter is on your PATH. Flutter Web is supported by current stable Flutter releases; if your SDK is old, update it with `flutter upgrade`.

## Verify the project

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Create a production web build:

```bash
flutter build web --release
```

The production files are generated in **`build/web/`**. The source ZIP intentionally does not include build output or machine-specific caches; generate these locally.

## GitHub workflow

Create an empty repository on GitHub, then open the terminal in the `memonest` folder and run:

```bash
git init
git add .
git commit -m "Build MemoNest Flutter mini-project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

Replace the example remote with the URL of your own GitHub repository. Do not paste credentials into source files.

## Deploy to Vercel

Vercel should host the **compiled Flutter Web output**, not the raw Dart source as a web app. Build the app first:

```bash
flutter pub get
flutter build web --release
```

Then deploy the contents of `build/web` as the static site. One direct CLI approach, after installing and signing into the Vercel CLI, is:

```bash
vercel deploy build/web
```

For a production deployment, use the Vercel CLI's production option when ready. Alternatively, connect the GitHub repository in the Vercel dashboard and configure the project so the Flutter build is produced before deployment. A standard Vercel build environment does not necessarily have Flutter installed by default, so do not assume that simply connecting the repository will compile Flutter automatically.

This project includes `vercel.json` with a catch-all rewrite to `index.html` for client-side route fallback. The current app uses a single main route and dialog-based editing, but the rewrite is ready if named routes are added later.

## Data and privacy notes

- Notes are stored in browser-local storage through `shared_preferences` on the same browser and site origin.
- There is no cloud sync, login, or remote database in this version.
- Clearing browser/site data can remove saved notes. Notes do not automatically move between browsers or devices.
- Use **Restore demo data** to replace the current collection with the sample notes.

## Flutter concepts demonstrated

- `StatelessWidget` and `StatefulWidget`
- Material widgets, `Row`, `Column`, `Stack`-compatible layout patterns, cards, chips, and forms
- Responsive layout using `MediaQuery` and `LayoutBuilder`
- State updates using `setState`
- Navigation/dialog workflows
- `TextFormField`, dropdowns, validation, and error feedback
- Custom reusable UI methods/widgets and theme styling
- JSON serialization and local persistence
- Filtering, searching, sorting, CRUD operations
- Widget tests and static analysis workflow

## Important verification note

The source package is prepared for a standard Flutter environment. A Flutter SDK was not available in the file-generation environment, so `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build web` have **not** been executed here. Run these commands locally and resolve any SDK-specific issues before submitting or deploying.
