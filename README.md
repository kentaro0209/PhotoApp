# PhotoApp / Monthly Picks

Monthly Picks is an iOS SwiftUI app for choosing representative photos from each month, then exporting them as an iOS Photos album or a printable PDF draft.

## Current MVP

- Photo library permission flow
- Monthly photo list
- Swipe decisions: keep, reject, hold
- Decision persistence
- Similar-photo grouping with a lightweight hash/time/location score
- Review screen for keep/hold photos
- Album export into iOS Photos
- A4 landscape PDF export with cover and 4 photos per page
- GitHub Actions build on a macOS runner

## Development Flow From Windows/Linux

Use WSL/Linux for editing and Git operations:

```bash
cd /home/kentaro/PhotoApp
git status
git add .
git commit -m "Describe the change"
git push
```

Every push runs `.github/workflows/ios-build.yml` on GitHub's macOS runner:

```text
Windows/Linux edit
-> git push
-> GitHub Actions macOS runner
-> xcodebuild for iOS Simulator
```

This verifies that the iOS project compiles without needing local Xcode on Windows/Linux.

## Limits Of CI

GitHub Actions can compile the app, but it cannot verify the real iPhone photo library experience. These still need an iPhone/iPad or Mac later:

- Real Photos permission behavior
- iCloud Photos download behavior
- Album creation in the user's Photos library
- PDF sharing sheet UX
- Performance with a large real library

## Project

Open this on macOS when needed:

```text
MonthlyPicks/MonthlyPicks.xcodeproj
```

The app currently uses generated Info.plist settings in the Xcode project, including the photo library permission descriptions.
