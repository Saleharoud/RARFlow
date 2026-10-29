import SwiftUI

public enum RARFlowTheme {
    // Window & Backgrounds
    public static let bgWindow = Color(red: 0.051, green: 0.067, blue: 0.102)     // #0d111a
    public static let bgSidebar = Color(red: 0.043, green: 0.055, blue: 0.082)    // #0b0e15
    public static let bgHeader = Color(red: 0.059, green: 0.078, blue: 0.122)     // #0f141f
    public static let bgToolbar = Color(red: 0.055, green: 0.071, blue: 0.110)    // #0e121c
    public static let bgStatusBar = Color(red: 0.039, green: 0.051, blue: 0.078)  // #0a0d14
    public static let bgTable = Color(red: 0.047, green: 0.063, blue: 0.094)      // #0c1018
    public static let bgTableHeader = Color(red: 0.055, green: 0.071, blue: 0.110)
    public static let bgRowHover = Color.white.opacity(0.04)
    public static let bgRowSelected = Color(red: 0.059, green: 0.235, blue: 0.459) // #0f3c75
    public static let bgRowSelectedInactive = Color(red: 0.08, green: 0.18, blue: 0.32)

    // Interactive Pills & Inputs
    public static let bgPill = Color.white.opacity(0.06)
    public static let bgPillActive = Color.white.opacity(0.12)
    public static let bgInput = Color.white.opacity(0.05)
    public static let bgSidebarActive = Color(red: 0.0, green: 0.439, blue: 0.953).opacity(0.18)

    // Borders & Dividers
    public static let borderSubtle = Color.white.opacity(0.07)
    public static let borderMedium = Color.white.opacity(0.14)
    public static let borderActive = Color.white.opacity(0.24)
    public static let borderSidebarActive = Color(red: 0.0, green: 0.439, blue: 0.953).opacity(0.40)

    // Text Colors
    public static let textPrimary = Color(red: 0.945, green: 0.961, blue: 0.976)   // #f1f5f9
    public static let textSecondary = Color(red: 0.580, green: 0.639, blue: 0.722) // #94a3b8
    public static let textMuted = Color(red: 0.443, green: 0.518, blue: 0.627)     // #718096

    // Accents
    public static let accentBlue = Color(red: 0.0, green: 0.443, blue: 0.890)      // #0071e3
    public static let accentCyan = Color(red: 0.220, green: 0.741, blue: 0.973)     // #38bdf8
    public static let accentGreen = Color(red: 0.204, green: 0.827, blue: 0.600)    // #34d399
    public static let accentAmber = Color(red: 0.851, green: 0.467, blue: 0.051)    // #d97706
    public static let accentRed = Color(red: 0.957, green: 0.247, blue: 0.369)      // #f43f5e
    public static let accentPurple = Color(red: 0.659, green: 0.333, blue: 0.969)   // #a855f7
    public static let dotGreen = Color(red: 0.063, green: 0.725, blue: 0.506)      // #10b981
}
