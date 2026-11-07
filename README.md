# Always On Clock

A minimal bedside clock for iPhone, built with SwiftUI. The app displays the
current time and seconds in amber on a near-black background, using the device's
locale and time zone. It supports both landscape orientations and iOS 16 or later.

The original Clock Dots font is a monospaced, rounded-dot design with Latin
letters, digits, and common punctuation. A matching font supplies faint unlit
dots behind the time's ASCII digits; iOS supplies fallback glyphs without
unlit dots for other writing systems. To regenerate both fonts, install `fonttools` and run
`python3 tools/generate_clock_font.py`.

Open `always_on_clock.xcodeproj` in Xcode, select a signing team and an iPhone,
and run the `always_on_clock` scheme. The screen stays awake while the clock is
active in the foreground; normal auto-lock behavior is restored when it is not.
The app cannot keep the display on when the device is locked, another app is
foregrounded, or iOS suspends it. Use Settings in the app to choose the time
format and clock luminance. Luminance dims the clock UI only (10–100%), not the
device display; adjust the device brightness in Control Center. The clock
defaults to 50% luminance and follows the system time format.

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
