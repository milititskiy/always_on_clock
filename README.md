# Always On Clock

A minimal bedside clock for iPhone, built with SwiftUI. The app displays the
current time and seconds on a near-black background, using the device's
locale and time zone. It supports both landscape orientations and iOS 16 or later.

The original Clock Dots font is a monospaced, circular-dot design with Latin
letters, digits, and common punctuation. A matching font supplies faint unlit
dots behind the time's ASCII digits; iOS supplies fallback glyphs without
unlit dots for other writing systems. To regenerate both fonts, install `fonttools` and run
`python3 tools/generate_clock_font.py`.

Open `always_on_clock.xcodeproj` in Xcode, select a signing team and an iPhone,
and run the `always_on_clock` scheme. The app asks iOS to keep the screen awake
while the clock is active in the foreground; normal auto-lock behavior is restored when it is not.
The app cannot keep the display on when the device is locked, another app is
foregrounded, or iOS suspends it. Use Settings in the app to choose the time
format and clock luminance. Luminance dims the clock screen, including its
controls (10–100%), not the device display; adjust the device brightness in Control Center. The clock
defaults to 50% luminance and follows the system time format.

Settings offer an optional automatic day/night luminance schedule. It is off
by default; when enabled, it uses local time, with night from 22:00 to 07:00,
50% day luminance and 15% night luminance until changed. Set both start times
and luminance levels independently. If the start times match, day luminance
applies all day. Disabling the schedule restores the separate manual setting.
The schedule changes only the app's appearance, not device brightness.

If the iPhone switches to Apple's StandBy screen, turn off StandBy in the
iPhone's **Settings > StandBy**, unlock the phone, and reopen the clock. The
app cannot disable StandBy itself or prevent manual locking, interruptions, or
system-imposed sleep. Check the behavior on the actual device after changing
the setting.

Tap **[THEME]** to cycle between Amber / Rust, Cyberpunk 2077, Blade Runner
1982, and Blade Runner 2049. The selected palette persists between launches.
Tap **[CRT]** to toggle subtle scanlines over the clock; the choice is saved
between launches and is off by default. This is a visual effect, not a way to
prevent OLED burn-in.
The bright cyan palette can be more conspicuous in a dark room; use the
luminance control to suit your surroundings.
Settings also offer an optional date, battery and charging indicator, and
periodic movement of the clock. Movement shifts the central clock by up to
four points every five minutes; it does not guarantee protection against
OLED burn-in. Other interface elements do not move.
The battery indicator shows `--%` when iOS cannot provide a level; the iOS
simulator does not provide a real iPhone battery reading.

The first launch explains power, charging, and OLED display considerations;
reopen it from Settings > About & safe use. Keeping the screen on uses extra
power. Battery capacity decreases with chemical age, affected by factors
including temperature and charging patterns. Apple says overnight charging is
safe, and recommends unplugging after a full charge when possible. Keep the
phone and charging equipment well ventilated and away from bedding. Continuous
high-brightness static images can contribute to OLED image retention or burn-in.
Use a comfortable low brightness and give the display breaks.

Apple references: [battery charging and lifespan](https://support.apple.com/en-us/105105),
[iPhone safety](https://support.apple.com/guide/iphone/iph301fc905/ios),
[OLED display care](https://support.apple.com/en-us/109039), and
[idle timer use](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled).

## Publishing

The app uses no accounts, analytics, network requests, or background modes.
App Store submission still requires an Apple Developer membership, signing and
an available bundle identifier, App Store Connect metadata and screenshots,
privacy disclosures, and review against the current App Store guidelines.
In particular, describe the foreground-only behavior accurately, supply a
working support URL, and consider the minimum functionality guideline for a
simple clock. Review decisions are at Apple's discretion; the guide and warnings
do not establish compliance.
Apple requires uploads to be built with Xcode 26 or later and the iOS 26 SDK
as of April 28, 2026; see [Apple's current SDK requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).
Approval cannot be guaranteed.
