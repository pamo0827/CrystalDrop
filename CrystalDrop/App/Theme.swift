import SwiftUI

/// アプリ全体のカラーテーマを管理する名前空間
struct AppColors {
    /// アクセントブルー（ボタン・アイコン等）
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    
    // MARK: - 背景グラデーション
    
    /// 晴れの日のグラデーション（オレンジ・ピンク・パープル）
    static let sunnyGradients: [Color] = [
        Color(red: 1.0, green: 0.7, blue: 0.3),
        Color(red: 0.9, green: 0.4, blue: 0.6),
        Color(red: 0.4, green: 0.2, blue: 0.7)
    ]
    
    /// 雨の日のグラデーション（ネイビー・ディープブルー・パープル）
    static let rainyGradients: [Color] = [
        Color(red: 0.2, green: 0.4, blue: 0.8),
        Color(red: 0.1, green: 0.2, blue: 0.6),
        Color(red: 0.05, green: 0.05, blue: 0.3)
    ]
    
    // MARK: - 波のレイヤー色
    
    static let sunnyWave1 = Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.4)
    static let sunnyWave2 = Color(red: 0.95, green: 0.6, blue: 0.4).opacity(0.6)
    static let sunnyWave3 = Color(red: 0.6, green: 0.2, blue: 0.6).opacity(0.8)
    
    static let rainyWave1 = Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.4)
    static let rainyWave2 = Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.6)
    static let rainyWave3 = Color(red: 0.05, green: 0.1, blue: 0.4).opacity(0.8)
}

// 既存のColorエクステンションも維持（古いコードへの影響を最小限にするため）
extension Color {
    static let appAccent = AppColors.accent
    static let appGradientBottom = Color(red: 202 / 255, green: 221 / 255, blue: 1.0)
    static let appGradientBottomSearch = Color(red: 215 / 255, green: 230 / 255, blue: 215 / 255)
    static let appSuggestionBackground = Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
}

extension Font {
    static func appBold(_ size: CGFloat) -> Font {
        .custom("InstrumentSans-Bold", size: size)
    }
}
