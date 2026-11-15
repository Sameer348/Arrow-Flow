# Arrow Flow: store listing

## Identity
| | |
|---|---|
| App name (both stores) | **Arrow Flow: Arrow Puzzle** (24 chars, fits Play's 30 and Apple's 30) |
| Package / Bundle ID | `com.qurat.arrowpuzzle.game` (Android and iOS) |
| Version | 1.0.0 (build 1) |
| Default language | English (US) |

## Category
| Store | Primary | Secondary / tags |
|---|---|---|
| Google Play | **Game › Puzzle** | Tags: Puzzle, Logic, Brain games, Casual, Offline |
| Apple App Store | **Games › Puzzle** | Secondary: Games › Casual |

## Age rating
- **Google Play (IARC questionnaire):** answer *No* to violence, fear, gambling, user-generated content, purchases with real money and location. Expected rating is **Everyone / PEGI 3**. Answer *Yes* to "Contains ads".
- **App Store:** answer *None* to every content descriptor. Expected rating is **4+**. Answer *No* to "Made for Kids" (the AdMob ads aren't configured for children's apps).

## App Store subtitle (30 chars)
Tap arrows. Clear the board.

## Google Play short description (80 chars)
Tap arrows with a clear path to escape the board. 1,200+ relaxing logic puzzles.

## App Store promotional text (170 chars)
Over 1,200 handcrafted and generated puzzles, a fresh Daily Challenge every day, and a rotating 2.5D Tower mode. Tap, escape, and clear the board!

## App Store keywords (100 chars, comma-separated, no spaces)
arrow,escape,puzzle,logic,brain,maze,unblock,relax,offline,daily,tap,clear,board,iq,mind,casual

## Full description (both stores, under 4,000 chars)

**Find the way out.**

Arrow Flow is a calm, clever puzzle game built on one simple rule: an arrow can only leave the board when its path is clear. Spot the arrow that's free, tap it, and watch it fly away. Then find the next one. Every move opens new paths, until the whole board is clear.

It's easy to learn in seconds, and the later levels will keep your brain busy.

**WHY YOU'LL LOVE IT**
• 1,200+ puzzles. Every single level is checked by a solver, so every board is solvable.
• Difficulty that grows steadily, from gentle 3×3 tutorials to expert boards shaped like hearts, stars, diamonds, crowns and butterflies.
• Satisfying feel: smooth arrow flights, glowing trails, sparks, haptics and soft sound design.
• Combos. Clear arrows quickly in a row for x2, x3 and x5 score multipliers.
• Earn up to 3 stars per level. Play cleanly for a perfect score.

**GAME MODES**
• Classic: the full campaign at your own pace.
• Daily Challenge: one new puzzle every day, the same for everyone.
• Timed: race the clock.
• Limited Moves: every tap counts.
• Perfect: one wrong tap and it's over.
• Endless: infinite generated puzzles.
• Tower 2.5D: rotate a tilted board and clear stacked layers.

**HELPFUL BOOSTERS**
Stuck? Use a Hint to reveal the smartest move, Undo a mistake, smash a blocker with the Hammer, or Shuffle the board. Shuffle always keeps it solvable.

**MAKE IT YOURS**
Unlock 10 arrow skins (Crystal, Neon, Fire, Ice, Galaxy, Gold, Rainbow and more) and 9 board themes. They are purely cosmetic and never pay-to-win.

**PLAY ANYWHERE**
Arrow Flow works fully offline: levels, progress, the daily challenge and rewards all work without internet.

Collect daily login rewards, unlock 13 achievements and climb the level map. How far can you flow?

---

## Google Play: Data safety form
The game itself collects no personal data, has no accounts and stores progress only on the device. The AdMob SDK does collect data, so declare:

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Device or other IDs (advertising ID) | Yes | Yes | Advertising or marketing, Analytics, Fraud prevention |
| App interactions | Yes | Yes | Advertising, Analytics |
| Crash logs / Diagnostics | Yes | Yes | Analytics |
| Approximate location (from IP, via ads SDK) | Yes | Yes | Advertising |

Answer the remaining questions as follows:
- Data is encrypted in transit: **Yes**.
- Users can request data deletion: **No**. No account data is stored. Users reset local progress in Settings.
- Ads: **Yes, contains ads**.

## App Store: App Privacy ("nutrition label")
- **Data Used to Track You:** Identifiers › Device ID, which applies only if the user allows tracking. Usage Data › Advertising Data.
- **Data Linked to You:** none.
- **Data Not Linked to You:** Usage Data (product interaction), Diagnostics (crash data), Location (coarse, via ads SDK).

## Required URLs (you must host these)
- **Privacy policy URL**: required on both stores because the app shows ads. It must mention Google AdMob and the advertising ID.
- **Support URL** (App Store) and a **support email**: required on both stores.
- **Marketing URL**: optional.

## Assets in this folder
| File | Use |
|---|---|
| `branding/app_icon_1024.png` | App Store icon (1024×1024, no alpha) |
| `branding/play_store_icon_512.png` | Play Store hi-res icon (512×512) |
| `google_play/feature_graphic_1024x500.png` | Play feature graphic |
| `google_play/screenshots/*.png` | Play phone screenshots (1080×1920) |
| `app_store/screenshots_6.9/*.png` | App Store iPhone 6.9" (1320×2868) |
| `app_store/screenshots_6.5/*.png` | App Store iPhone 6.5" (1284×2778) |

## Before you submit
1. **AdMob:** create the AdMob apps and ad units. Replace the test App IDs in `AndroidManifest.xml` and `ios/Runner/Info.plist`. Put the real unit IDs in `lib/services/ads/ad_config.dart` and set `isTestMode = false`.
2. **Android signing:** create an upload keystore and fill in `android/key.properties` (see `android/key.properties.example`). Then build:
   ```bash
   flutter build appbundle --release
   ```
3. **iOS:** in Xcode, open `ios/Runner.xcworkspace`, select your Team under Signing & Capabilities, then build:
   ```bash
   flutter build ipa --release
   ```
   Upload with Transporter or Xcode Organizer.
4. **Privacy:** in the AdMob console, configure the GDPR / US-states privacy messages. The app already shows them through UMP.
