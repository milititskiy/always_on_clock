import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone
    @Environment(\.calendar) private var calendar
    @AppStorage("clockLuminance") private var luminance = 0.5
    @AppStorage("clockScheduleEnabled") private var scheduleEnabled = false
    @AppStorage("clockNightStart") private var nightStart = 22 * 60
    @AppStorage("clockDayStart") private var dayStart = 7 * 60
    @AppStorage("clockDayLuminance") private var dayLuminance = 0.5
    @AppStorage("clockNightLuminance") private var nightLuminance = 0.15
    @AppStorage("clockTimeFormat") private var timeFormat = ClockTimeFormat.system.rawValue
    @AppStorage("clockUsageAcknowledged") private var usageAcknowledged = false
    @AppStorage("clockShowDate") private var showDate = false
    @AppStorage("clockShowBattery") private var showBattery = false
    @AppStorage("clockDisplayMovement") private var displayMovement = false
    @AppStorage("clockTheme") private var themeName = ThemeMode.amber.rawValue
    @AppStorage("clockCRTEnabled") private var crtEnabled = false
    @AppStorage("clockSizeScale") private var sizeScale = 1.0
    @State private var showingSettings = false
    @State private var batteryLevel: Float = -1
    @State private var batteryState: UIDevice.BatteryState = .unknown

    private var theme: ThemeMode {
        ThemeMode(rawValue: themeName) ?? .amber
    }

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
                let schedule = ClockLuminanceSchedule(
                    enabled: scheduleEnabled, nightStart: nightStart, dayStart: dayStart,
                    manualLuminance: luminance, dayLuminance: dayLuminance, nightLuminance: nightLuminance
                )
                let mode = schedule.mode(at: timeline.date, calendar: calendar, timeZone: timeZone)
                let effectiveLuminance = schedule.luminance(for: mode)
                VStack(spacing: 0) {
                    HeaderBar(showBattery: showBattery, batteryLevel: batteryLevel, batteryState: batteryState, mode: mode)
                        .opacity(effectiveLuminance)

                    ClockDisplay(time: time, date: timeline.date, showDate: showDate, availableSize: geometry.size, scale: sizeScale)
                        .offset(clockMovement(for: timeline.date, enabled: displayMovement))
                        .opacity(effectiveLuminance)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            if crtEnabled {
                                CRTScanlines()
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }

                    FooterBar(luminance: effectiveLuminance, mode: mode, crtEnabled: crtEnabled, cycleTheme: {
                        themeName = theme.next.rawValue
                    }, toggleCRT: {
                        crtEnabled.toggle()
                    }, openSettings: {
                        showingSettings = true
                    })
                    .opacity(effectiveLuminance)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay {
                    CornerBrackets()
                        .stroke(theme.secondary.opacity(0.65), lineWidth: 1)
                        .opacity(effectiveLuminance)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .background(theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showingSettings) {
            ClockSettingsView(luminance: $luminance, timeFormat: $timeFormat,
                              showDate: $showDate, showBattery: $showBattery,
                              displayMovement: $displayMovement)
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
        .onAppear { updateDeviceState(showBattery: showBattery, phase: scenePhase) }
        .onChange(of: scenePhase) { phase in updateDeviceState(showBattery: showBattery, phase: phase) }
        .onChange(of: showBattery) { enabled in updateDeviceState(showBattery: enabled, phase: scenePhase) }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            refreshBattery()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in
            refreshBattery()
        }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            if showBattery && scenePhase == .active && batteryLevel < 0 {
                refreshBattery()
            }
        }
        .environment(\.clockTheme, theme)
    }

    private func updateDeviceState(showBattery: Bool, phase: ScenePhase) {
        UIDevice.current.isBatteryMonitoringEnabled = showBattery && phase != .background
        if UIDevice.current.isBatteryMonitoringEnabled {
            refreshBattery()
        }
    }

    private func refreshBattery() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }
}

private struct HeaderBar: View {
    @Environment(\.clockTheme) private var theme
    let showBattery: Bool
    let batteryLevel: Float
    let batteryState: UIDevice.BatteryState
    let mode: ClockLuminanceMode

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(theme.active)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text("1-BIT_SYS // \(theme.title)")
                    .accessibilityIdentifier("clock.themeName")
                Spacer(minLength: 4)
                if showBattery {
                    BatteryIndicator(level: batteryLevel, state: batteryState)
                }
                Text("\(mode.title)_MODE: ACTIVE")
            }
            Rectangle().fill(theme.secondary.opacity(0.6)).frame(height: 1)
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(theme.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

private struct BatteryIndicator: View {
    let level: Float
    let state: UIDevice.BatteryState

    var body: some View {
        HStack(spacing: 4) {
            Text("BAT")
            if level >= 0 {
                Text("\(Int((level * 100).rounded()))%")
            } else {
                Text("--%")
            }
            if state == .charging || state == .full {
                Image(systemName: "bolt.fill")
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("clock.battery")
    }

    private var accessibilityLabel: Text {
        guard level >= 0 else { return Text("Battery level unavailable") }
        let percent = Int((level * 100).rounded())
        switch state {
        case .charging: return Text("Battery \(percent) percent, charging")
        case .full: return Text("Battery \(percent) percent, full")
        case .unplugged: return Text("Battery \(percent) percent, unplugged")
        default: return Text("Battery \(percent) percent")
        }
    }
}

private struct ClockDisplay: View {
    @Environment(\.clockTheme) private var theme
    let time: ClockTime
    let date: Date
    let showDate: Bool
    let availableSize: CGSize
    let scale: Double

    // Capped so the digits, colon and seconds box never exceed the screen.
    private var digitSize: CGFloat {
        min(availableSize.width * 0.25 * scale, availableSize.height * 0.67 * scale, availableSize.width * 0.3)
    }

    var body: some View {
        VStack(spacing: 2) {
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
                    VStack(alignment: .center, spacing: 4) {
                        Text("SEC")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.secondary)
                        DotDigits(value: time.second, size: min(digitSize * 0.23, 40))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(time.second)
                            .accessibilityIdentifier("clock.seconds")
                    }
                    .padding(6)
                    .overlay(Rectangle().stroke(theme.secondary.opacity(0.8), lineWidth: 1))
                    if let period = time.period {
                        Text(period)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .overlay(Rectangle().stroke(theme.secondary.opacity(0.8), lineWidth: 1))
                            .accessibilityIdentifier("clock.period")
                    }
                }
                .foregroundStyle(theme.active)
                .padding(.leading, 14)
                .fixedSize()
            }
            .frame(maxWidth: .infinity)
            if showDate {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.active)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityIdentifier("clock.date")
            }
        }
    }
}

private struct DotDigits: View {
    @Environment(\.clockTheme) private var theme
    let value: String
    let size: CGFloat

    private var inactiveDigits: AttributedString {
        var result = AttributedString()
        for character in value {
            var part = AttributedString(String(character))
            part.foregroundColor = character.isASCII && character.isNumber
                ? theme.secondary.opacity(0.3) : .clear
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
                .foregroundStyle(theme.active)
                .shadow(color: theme.active.opacity(0.3), radius: 3)
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private struct BlinkingColon: View {
    @Environment(\.clockTheme) private var theme
    let isLit: Bool
    let size: CGFloat

    var body: some View {
        let dotSize = size * 68 / 1024
        VStack(spacing: dotSize * 1.4) {
            ForEach(0..<2, id: \.self) { _ in
                Circle()
                    .fill(isLit ? theme.active : theme.secondary.opacity(0.3))
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: isLit ? theme.active.opacity(0.3) : .clear, radius: 3)
            }
        }
        .frame(width: size * 0.27)
        .accessibilityHidden(true)
    }
}

private struct FooterBar: View {
    @Environment(\.clockTheme) private var theme
    let luminance: Double
    let mode: ClockLuminanceMode
    let crtEnabled: Bool
    let cycleTheme: () -> Void
    let toggleCRT: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(theme.secondary.opacity(0.6))
                .frame(height: 1)
            HStack {
                Text("LUM: \(Int((luminance * 100).rounded()))% (\(mode.title))")
                    .foregroundStyle(theme.secondary)
                    .accessibilityIdentifier("clock.luminance")
                Spacer()
                Button(action: cycleTheme) {
                    Text("[THEME]")
                        .foregroundStyle(theme.active)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .overlay(Rectangle().stroke(theme.secondary.opacity(0.8), lineWidth: 1))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Change theme")
                .accessibilityValue(theme.title)
                .accessibilityIdentifier("clock.theme")
                Button(action: toggleCRT) {
                    Text("[CRT]")
                        .foregroundStyle(theme.active)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .overlay(Rectangle().stroke(crtEnabled ? theme.active : theme.secondary.opacity(0.8), lineWidth: 1))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("CRT filter")
                .accessibilityValue(crtEnabled ? Text("On") : Text("Off"))
                .accessibilityIdentifier("clock.crt")
                Button(action: openSettings) {
                    Text("[SETTINGS]")
                        .foregroundStyle(theme.active)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .overlay(Rectangle().stroke(theme.secondary.opacity(0.8), lineWidth: 1))
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

private struct CRTScanlines: View {
    var body: some View {
        Canvas { context, size in
            var lines = Path()
            for y in stride(from: CGFloat.zero, to: size.height, by: 4) {
                lines.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
            }
            context.fill(lines, with: .color(.black.opacity(0.3)))
        }
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(10, rect.width / 4, rect.height / 4)
        let inset = CGFloat(0.5)
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: rect.minX + inset, y: rect.minY + inset), 1, 1),
            (CGPoint(x: rect.maxX - inset, y: rect.minY + inset), -1, 1),
            (CGPoint(x: rect.minX + inset, y: rect.maxY - inset), 1, -1),
            (CGPoint(x: rect.maxX - inset, y: rect.maxY - inset), -1, -1)
        ]
        var path = Path()
        for (corner, dx, dy) in corners {
            path.move(to: CGPoint(x: corner.x + dx * length, y: corner.y))
            path.addLine(to: corner)
            path.addLine(to: CGPoint(x: corner.x, y: corner.y + dy * length))
        }
        return path
    }
}

private struct ClockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.clockTheme) private var theme
    @Environment(\.calendar) private var calendar
    @AppStorage("clockScheduleEnabled") private var scheduleEnabled = false
    @AppStorage("clockNightStart") private var nightStart = 22 * 60
    @AppStorage("clockDayStart") private var dayStart = 7 * 60
    @AppStorage("clockDayLuminance") private var dayLuminance = 0.5
    @AppStorage("clockNightLuminance") private var nightLuminance = 0.15
    @AppStorage("clockSizeScale") private var sizeScale = 1.0
    @Binding var luminance: Double
    @Binding var timeFormat: String
    @Binding var showDate: Bool
    @Binding var showBattery: Bool
    @Binding var displayMovement: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Automatic day/night schedule", isOn: $scheduleEnabled)
                        .accessibilityIdentifier("settings.scheduleEnabled")
                    if scheduleEnabled {
                        DatePicker("Night starts", selection: timeBinding($nightStart), displayedComponents: .hourAndMinute)
                            .environment(\.timeZone, .gmt)
                            .accessibilityIdentifier("settings.nightStart")
                        DatePicker("Day starts", selection: timeBinding($dayStart), displayedComponents: .hourAndMinute)
                            .environment(\.timeZone, .gmt)
                            .accessibilityIdentifier("settings.dayStart")
                        if nightStart == dayStart {
                            Text("Start times match, so day luminance is used all day.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        LuminanceSlider(title: "Day luminance", value: $dayLuminance, identifier: "settings.dayLuminance")
                        LuminanceSlider(title: "Night luminance", value: $nightLuminance, identifier: "settings.nightLuminance")
                    } else {
                        LuminanceSlider(title: "Clock luminance", value: $luminance, identifier: "settings.luminance")
                    }
                    Text("The schedule uses local time. Luminance dims the clock screen and controls; device brightness is unchanged.")
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

                Section("Clock size") {
                    Slider(value: $sizeScale, in: 0.5...1.5, step: 0.05) {
                        Text("Clock size")
                    } minimumValueLabel: {
                        Text("50%")
                    } maximumValueLabel: {
                        Text("150%")
                    }
                    .accessibilityIdentifier("settings.clockSize")
                    Text("Clock size: \(Int((sizeScale * 100).rounded()))%")
                }

                Section("Clock display") {
                    Toggle("Show date", isOn: $showDate)
                        .accessibilityIdentifier("settings.showDate")
                    Toggle("Show battery and charging status", isOn: $showBattery)
                        .accessibilityIdentifier("settings.showBattery")
                    Toggle("Move clock periodically", isOn: $displayMovement)
                        .accessibilityIdentifier("settings.displayMovement")
                    Text("Moves the clock slightly every five minutes. This does not guarantee protection from OLED burn-in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    NavigationLink("About & safe use") {
                        ClockUsageView(isFirstLaunch: false)
                    }
                    .accessibilityIdentifier("settings.about")
                }
            }
            .tint(theme.active)
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

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        var calendar = calendar
        // A fixed UTC day lets the picker represent every wall-clock time, even on DST transition days.
        calendar.timeZone = .gmt
        return Binding(
            get: {
                Date(timeIntervalSince1970: Double(minutes.wrappedValue * 60))
            },
            set: { date in
                let components = calendar.dateComponents([.hour, .minute], from: date)
                if let hour = components.hour, let minute = components.minute {
                    minutes.wrappedValue = hour * 60 + minute
                }
            }
        )
    }
}

private struct LuminanceSlider: View {
    let title: String
    @Binding var value: Double
    let identifier: String

    var body: some View {
        Slider(value: $value, in: 0.1...1, step: 0.05) {
            Text(title)
        } minimumValueLabel: {
            Text("10%")
        } maximumValueLabel: {
            Text("100%")
        }
        .accessibilityIdentifier(identifier)
        Text("\(title): \(Int((value * 100).rounded()))%")
    }
}

private struct ClockUsageView: View {
    @Environment(\.clockTheme) private var theme
    let isFirstLaunch: Bool
    var acknowledge: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("1-BIT_SYS // GUIDE")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(theme.active)

                Text("A bedside clock")
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white)

                UsageSection(title: "HOW IT WORKS", text: "Place your iPhone in landscape to show the time. The app asks iOS to keep the screen awake while it is active in the foreground. Locking the phone or leaving the app stops the clock display.")

                UsageSection(title: "IF STANDBY APPEARS", text: "If iPhone shows Apple's StandBy screen instead, turn off StandBy in Settings > StandBy, then unlock the iPhone and reopen the clock. iOS may still lock the screen or interrupt the app.")

                UsageSection(title: "POWER & BATTERY", text: "Keeping the screen on uses extra power. A connected charger may be useful for extended use. Batteries age over time; heat and charging patterns can affect their capacity and how long they last between charges. Apple says overnight charging is safe and recommends unplugging after a full charge when possible.")

                UsageSection(title: "SAFE CHARGING", text: "Keep the phone, dock, charger and adapter well ventilated and away from bedding. Don't use damaged charging equipment. Enable Optimized Battery Charging in iPhone settings.")

                UsageSection(title: "DISPLAY CARE", text: "A static image displayed for long periods at high brightness can contribute to OLED image retention or burn-in. Keep brightness comfortable and give the display breaks. The app's luminance control dims the clock, not the device brightness.")

                VStack(alignment: .leading, spacing: 12) {
                    Text("APPLE GUIDANCE")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(theme.active)
                    Link("Battery charging and lifespan", destination: URL(string: "https://support.apple.com/en-us/105105")!)
                    Link("iPhone charging safety", destination: URL(string: "https://support.apple.com/guide/iphone/iph301fc905/ios")!)
                    Link("OLED display care", destination: URL(string: "https://support.apple.com/en-us/109039")!)
                }
                .font(.system(.subheadline, design: .monospaced))
                .tint(theme.active)
            }
            .frame(maxWidth: 700, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .background(theme.background.ignoresSafeArea())
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
        .tint(theme.active)
        .accessibilityIdentifier("usage.guide")
    }
}

private struct UsageSection: View {
    @Environment(\.clockTheme) private var theme
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(theme.active)
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
