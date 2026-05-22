# PhotoApp / Family Picks

Family Picks is an iOS SwiftUI app for slowly turning family photos into printable memory books. It uses months as a calm way to browse the camera roll, but there is no deadline or pressure to keep up every month.

## Current MVP

- Photo library permission flow
- Month-based photo list
- Swipe decisions with gentle labels: keep, later, skip this time
- Decision persistence
- Similar-photo grouping with a lightweight hash/time/location score
- Review screen for photos to keep or revisit later
- Album export into iOS Photos
- A4 landscape family photobook PDF export with cover and 4 photos per page
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

## Simulator Sample Photos

`SamplePhotos/` contains generated test images for checking the swipe comparison flow. They are grouped as six similar scenes with six variations each.

To load them into the iOS Simulator:

1. Pull the latest repo on the Mac.
2. Open the Simulator.
3. Open `SamplePhotos/` in Finder.
4. Select all `.jpg` files and drag them onto the Simulator window.
5. Open Family Picks and tap `まとめ直す` for the target month.
