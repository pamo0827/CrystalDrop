import SwiftUI

struct RainfallView: View {
    let count = 100
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // すべての雨粒を1つのパスにまとめて描画負荷を軽減
                var combinedPath = Path()
                
                for i in 0..<count {
                    let seed = Double(i)
                    // 計算を簡略化
                    let x = (abs(sin(seed * 0.5 + now * 0.05))) * size.width
                    let speed = 600.0 + (sin(seed) * 200.0)
                    // y座標の計算を最適化
                    let y = (now * speed + seed * 100).truncatingRemainder(dividingBy: size.height + 40) - 20
                    
                    combinedPath.move(to: CGPoint(x: x, y: y))
                    combinedPath.addLine(to: CGPoint(x: x - 1, y: y + 8))
                }
                
                context.stroke(
                    combinedPath,
                    with: .color(.white.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }
        }
        .drawingGroup() // Metalを使用して描画を高速化
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.blue
        RainfallView()
    }
}
