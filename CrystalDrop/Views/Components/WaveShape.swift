import SwiftUI

/// 画面下部に表示する波状のレイヤーを描画するShape
struct WaveShape: Shape {
    /// 波の高さのオフセット（0.0 〜 1.0）
    var offset: CGFloat
    /// 波の振幅
    var amplitude: CGFloat = 20
    /// 波の周期（繰り返しの数）
    var frequency: CGFloat = 1.5
    
    // アニメーションをサポートするためのプロパティ
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * offset

        path.move(to: CGPoint(x: 0, y: midHeight))

        // ステップを大きくして（by: 5）計算量を削減
        for x in stride(from: 0, through: width, by: 5) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency * 2)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 最後の点を正確に結ぶ
        path.addLine(to: CGPoint(x: width, y: midHeight + sin(.pi * frequency * 2) * amplitude))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

/// 天気に応じた波レイヤーを描画する共通コンポーネント
struct WaveLayerView: View {
    var condition: WeatherCondition = .rainy

    var body: some View {
        ZStack {
            WaveShape(offset: 0.75, amplitude: 35, frequency: 0.8)
                .fill(condition == .sunny ? AppColors.sunnyWave1 : AppColors.rainyWave1)
            WaveShape(offset: 0.82, amplitude: 25, frequency: 1.2)
                .fill(condition == .sunny ? AppColors.sunnyWave2 : AppColors.rainyWave2)
            WaveShape(offset: 0.9, amplitude: 15, frequency: 1.5)
                .fill(condition == .sunny ? AppColors.sunnyWave3 : AppColors.rainyWave3)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        
        WaveShape(offset: 0.7, amplitude: 30, frequency: 1)
            .fill(Color.white.opacity(0.3))
        
        WaveShape(offset: 0.8, amplitude: 20, frequency: 1.5)
            .fill(Color.white.opacity(0.5))
            
        WaveShape(offset: 0.9, amplitude: 10, frequency: 2)
            .fill(Color.white)
    }
}
