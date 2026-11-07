import SwiftUI

private enum NightPalette {
    static let background = Color(hex: 0x08080A)
    static let active = Color(hex: 0xC84B31)
    static let secondary = Color(hex: 0x4A3B32)
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone
    @Environment(\.calendar) private var calendar
    @AppStorage("clockLuminance") private var luminance = 0.5
    @AppStorage("clockTimeFormat") private var timeFormat = ClockTimeFormat.system.rawValue
    @AppStorage("clockUsageAcknowledged") private var usageAcknowledged = false
    @State private var showingSettings = false

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let time = ClockTime(
                    date: timeline.date,
                    format: ClockTimeFormat(rawValue: timeFormat) ?? .system,
                    locale: locale,
                    timeZone: timeZone,
                    calendar: calendar
                )
                VStack(spacing: 0) {
                    HeaderBar()
                        .opacity(luminance)

                    ClockDisplay(time: time, availableSize: geometry.size)
                        .opacity(luminance)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    FooterBar(luminance: luminance) {
                        showingSettings = true
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .background(NightPalette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showingSettings) {
            ClockSettingsView(luminance: $luminance, timeFormat: $timeFormat)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !usageAcknowledged },
            set: { if !$0 { usageAcknowledged = true } }
        )) {
            NavigationStack {
                ClockUsageView(isFirstLaunch: true) {
                    usageAcknowledged = true
                }
            }
            .preferredColorScheme(.dark)
            .interactiveDismissDisabled()
        }
        .onAppear { updateIdleTimer() }
        .onChange(of: scenePhase) { _ in updateIdleTimer() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = scenePhase == .active
    }
}

private struct HeaderBar: View {
    var body: some View {
        HStack {
            Text("1-BIT_SYS // 01")
            Spacer()
            Text("NIGHT_MODE: ACTIVE")
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(NightPalette.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
    }
}

private struct ClockDisplay: View {
    let time: ClockTime
    let availableSize: CGSize

    private var digitSize: CGFloat {
        min(availableSize.width * 0.25, availableSize.height * 0.67)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                DotDigits(value: time.hour, size: digitSize)
                BlinkingColon(isLit: time.secondNumber.isMultiple(of: 2), size: digitSize)
                DotDigits(value: time.minute, size: digitSize)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(time.accessibilityLabel)
            .accessibilityIdentifier("clock.time")

            VStack(alignment: .leading, spacing: 12) {
                if let period = time.period {
                    Text(period)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay(Rectangle().stroke(NightPalette.secondary, lineWidth: 1))
                        .accessibilityIdentifier("clock.period")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("SEC")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(NightPalette.secondary)
                    Text(time.second)
                        .font(.custom("ClockDots-Regular", size: min(digitSize * 0.23, 40)))
                        .accessibilityIdentifier("clock.seconds")
                }
            }
            .foregroundStyle(NightPalette.active)
            .padding(.leading, 14)
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DotDigits: View {
    let value: String
    let size: CGFloat

    private var inactiveDigits: AttributedString {
        var result = AttributedString()
        for character in value {
            var part = AttributedString(String(character))
            part.foregroundColor = character.isASCII && character.isNumber
                ? NightPalette.secondary.opacity(0.3) : .clear
            result += part
        }
        return result
    }

    var body: some View {
        ZStack {
            Text(inactiveDigits)
                .font(.custom("ClockDotsInactive-Regular", size: size))
            Text(value)
                .font(.custom("ClockDots-Regular", size: size))
                .foregroundStyle(NightPalette.active)
                .shadow(color: NightPalette.active.opacity(0.3), radius: 3)
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private struct BlinkingColon: View {
    let isLit: Bool
    let size: CGFloat

    var body: some View {
        let dotSize = size * 68 / 1024
        VStack(spacing: dotSize * 1.4) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: dotSize * 0.15)
                    .fill(isLit ? NightPalette.active : NightPalette.secondary.opacity(0.3))
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: isLit ? NightPalette.active.opacity(0.3) : .clear, radius: 3)
            }
        }
        .frame(width: size * 0.27)
        .accessibilityHidden(true)
    }
}

private struct FooterBar: View {
    let luminance: Double
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(NightPalette.secondary.opacity(0.6))
                .frame(height: 1)
            HStack {
                Text("LUM: \(Int((luminance * 100).rounded()))% (NIGHT)")
                    .foregroundStyle(NightPalette.secondary)
                    .opacity(luminance)
                    .accessibilityIdentifier("clock.luminance")
                Spacer()
                Button(action: openSettings) {
                    Text("[SETTINGS]")
                        .foregroundStyle(NightPalette.active)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier("clock.settings")
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
    }
}

private struct ClockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var luminance: Double
    @Binding var timeFormat: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Slider(value: $luminance, in: 0.1...1, step: 0.05) {
                        Text("Clock luminance")
                    } minimumValueLabel: {
                        Text("10%")
                    } maximumValueLabel: {
                        Text("100%")
                    }
                    .accessibilityIdentifier("settings.luminance")
                    Text("Clock luminance: \(Int((luminance * 100).rounded()))%")
                    Text("Dims the clock only; device brightness is unchanged.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Luminance")
                }

                Section("Time format") {
                    Picker("Time format", selection: $timeFormat) {
                        Text("System").tag(ClockTimeFormat.system.rawValue)
                        Text("12-hour").tag(ClockTimeFormat.twelveHour.rawValue)
                        Text("24-hour").tag(ClockTimeFormat.twentyFourHour.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.timeFormat")
                }

                Section {
                    NavigationLink("About & safe use") {
                        ClockUsageView(isFirstLaunch: false)
                    }
                    .accessibilityIdentifier("settings.about")
                }
            }
            .tint(NightPalette.active)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings.done")
                }
            }
        }
    }
}

private struct ClockUsageView: View {
    let isFirstLaunch: Bool
    var acknowledge: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("1-BIT_SYS // GUIDE")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(NightPalette.active)

                Text("A bedside clock")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white)

                UsageSection(title: "HOW IT WORKS", text: "Place your iPhone in landscape to show the time. The screen stays awake while the clock is active in the foreground. Locking the phone or leaving the app stops the clock display.")

                UsageSection(title: "POWER & BATTERY", text: "Keeping the screen on uses extra power. A connected charger may be useful for extended use. Batteries age over time; heat and charging patterns can affect their capacity and how long they last between charges. Apple says overnight charging is safe and recommends unplugging after a full charge when possible.")

                UsageSection(title: "SAFE CHARGING", text: "Keep the phone, dock, charger and adapter well ventilated and away from bedding. Don't use damaged charging equipment. Enable Optimized Battery Charging in iPhone settings.")

                UsageSection(title: "DISPLAY CARE", text: "A static image displayed for long periods at high brightness can contribute to OLED image retention or burn-in. Keep brightness comfortable and give the display breaks. The app's luminance control dims the clock, not the device brightness.")

                VStack(alignment: .leading, spacing: 12) {
                    Text("APPLE GUIDANCE")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(NightPalette.active)
                    Link("Battery charging and lifespan", destination: URL(string: "https://support.apple.com/en-us/105105")!)
                    Link("iPhone charging safety", destination: URL(string: "https://support.apple.com/guide/iphone/iph301fc905/ios")!)
                    Link("OLED display care", destination: URL(string: "https://support.apple.com/en-us/109039")!)
                }
                .font(.system(.subheadline, design: .monospaced))
                .tint(NightPalette.active)
            }
            .frame(maxWidth: 700, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .background(NightPalette.background.ignoresSafeArea())
        .navigationTitle(isFirstLaunch ? "Before you begin" : "About & safe use")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isFirstLaunch {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { acknowledge?() }
                        .accessibilityIdentifier("usage.continue")
                }
            }
        }
        .tint(NightPalette.active)
        .accessibilityIdentifier("usage.guide")
    }
}

private struct UsageSection: View {
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(NightPalette.active)
            Text(text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ContentView()
}
