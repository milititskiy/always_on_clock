import SwiftUI

enum ThemeMode: String, CaseIterable {
    case amber
    case cyberpunk
    case bladeRunner1982
    case bladeRunner2049

    var title: String {
        switch self {
        case .amber: return "AMBER / RUST"
        case .cyberpunk: return "CYBERPUNK 2077"
        case .bladeRunner1982: return "BLADE RUNNER 1982"
        case .bladeRunner2049: return "BLADE RUNNER 2049"
        }
    }

    var backgroundHex: UInt32 {
        switch self {
        case .amber: return 0x08080A
        case .cyberpunk: return 0x05050A
        case .bladeRunner1982: return 0x0A0908
        case .bladeRunner2049: return 0x0D0B0A
        }
    }

    var activeHex: UInt32 {
        switch self {
        case .amber: return 0xC84B31
        case .cyberpunk: return 0x00F0FF
        case .bladeRunner1982: return 0xE2A03F
        case .bladeRunner2049: return 0xFF5722
        }
    }

    var secondaryHex: UInt32 {
        switch self {
        case .amber: return 0x4A3B32
        case .cyberpunk: return 0x4A2E4B
        case .bladeRunner1982: return 0x3D332A
        case .bladeRunner2049: return 0x4D322A
        }
    }

    var background: Color { Color(hex: backgroundHex) }
    var active: Color { Color(hex: activeHex) }
    var secondary: Color { Color(hex: secondaryHex) }

    var next: ThemeMode {
        switch self {
        case .amber: return .cyberpunk
        case .cyberpunk: return .bladeRunner1982
        case .bladeRunner1982: return .bladeRunner2049
        case .bladeRunner2049: return .amber
        }
    }
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

private struct ClockThemeKey: EnvironmentKey {
    static let defaultValue = ThemeMode.amber
}

extension EnvironmentValues {
    var clockTheme: ThemeMode {
        get { self[ClockThemeKey.self] }
        set { self[ClockThemeKey.self] = newValue }
    }
}
