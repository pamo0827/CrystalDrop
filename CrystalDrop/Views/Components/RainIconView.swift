import SwiftUI

// MARK: - 案A: Aurora Rain（オーロラ雨）
// 深宇宙のような暗い円に、オーロラ状のグラデーションと白い雨粒が光る

struct AuroraRainIcon: View {
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // ベース円（深夜ブルー）
            Circle()
                .fill(Color(red: 0.04, green: 0.04, blue: 0.18))
                .frame(width: size, height: size)

            // オーロラ層1 - パープル
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.55, green: 0.1, blue: 0.95).opacity(0.75), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.42
                    )
                )
                .frame(width: size * 0.88, height: size * 0.48)
                .offset(y: -size * 0.06)
                .blur(radius: size * 0.08)

            // オーロラ層2 - エレクトリックブルー
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.1, green: 0.45, blue: 1.0).opacity(0.65), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.36
                    )
                )
                .frame(width: size * 0.75, height: size * 0.42)
                .offset(x: size * 0.1, y: size * 0.1)
                .blur(radius: size * 0.06)

            // オーロラ層3 - シアン
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.0, green: 0.85, blue: 0.85).opacity(0.5), .clear],
                        center: .center, startRadius: 0, endRadius: size * 0.28
                    )
                )
                .frame(width: size * 0.55, height: size * 0.38)
                .offset(x: -size * 0.08, y: size * 0.06)
                .blur(radius: size * 0.05)

            // 雨のストライプ（Canvas描画）
            Canvas { ctx, cs in
                let streaks: [(CGFloat, CGFloat, CGFloat)] = [
                    (cs.width * 0.33, cs.height * 0.28, cs.height * 0.3),
                    (cs.width * 0.47, cs.height * 0.22, cs.height * 0.38),
                    (cs.width * 0.60, cs.height * 0.26, cs.height * 0.28),
                    (cs.width * 0.72, cs.height * 0.30, cs.height * 0.22),
                ]
                for (x, startY, len) in streaks {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: startY))
                    p.addLine(to: CGPoint(x: x - len * 0.12, y: startY + len))
                    ctx.stroke(p, with: .color(.white.opacity(0.88)),
                               style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round))
                }
            }
            .frame(width: size * 0.78, height: size * 0.78)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: Color(red: 0.4, green: 0.15, blue: 0.85).opacity(0.55), radius: size * 0.18)
    }
}

// MARK: - 案B: Crystal Drop（クリスタル雫）
// ディープネイビーの背景に幾何学的な波と白→ライトブルーの雫

struct CrystalDropIcon: View {
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // ベース背景（ディープインディゴ）
            Rectangle()
                .fill(Color(red: 0.102, green: 0.137, blue: 0.494))
                .frame(width: size, height: size)

            // 背景ブロブ1（左上）
            Circle()
                .fill(Color(red: 0.247, green: 0.318, blue: 0.710).opacity(0.3))
                .frame(width: size * 0.59, height: size * 0.59)
                .offset(x: -size * 0.3, y: -size * 0.3)

            // 背景ブロブ2（右下）
            Circle()
                .fill(Color(red: 0.157, green: 0.204, blue: 0.576).opacity(0.5))
                .frame(width: size * 0.78, height: size * 0.78)
                .offset(x: size * 0.3, y: size * 0.3)

            // 波レイヤー1
            CrystalWaveShape(topLeftY: 0.78, topRightY: 0.59)
                .fill(Color(red: 0.224, green: 0.286, blue: 0.671).opacity(0.6))
                .frame(width: size, height: size)

            // 波レイヤー2
            CrystalWaveShape(topLeftY: 0.88, topRightY: 0.73)
                .fill(Color(red: 0.361, green: 0.420, blue: 0.753).opacity(0.8))
                .frame(width: size, height: size)

            // 中央の雫
            CrystalDropShape()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.702, green: 0.898, blue: 0.988)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.39, height: size * 0.63)

            // 雫のハイライト（中心線）
            CrystalDropHighlight()
                .fill(.white.opacity(0.3))
                .frame(width: size * 0.39, height: size * 0.63)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

private struct CrystalWaveShape: Shape {
    var topLeftY: CGFloat
    var topRightY: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height * topLeftY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height * topRightY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

private struct CrystalDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // SVG: M512 200 C512 200 712 500 712 650 A200 200 0 0 1 312 650 C312 500 512 200 512 200
        // 正規化（viewBox 1024, drop 200→650 → y:0.195→0.635, x:0.305→0.695）
        let top   = CGPoint(x: w * 0.5, y: 0)
        let rCtrl = CGPoint(x: w * 0.97, y: h * 0.48)
        let rBot  = CGPoint(x: w * 0.97, y: h * 0.69)
        let lBot  = CGPoint(x: w * 0.03, y: h * 0.69)
        let lCtrl = CGPoint(x: w * 0.03, y: h * 0.48)
        p.move(to: top)
        p.addCurve(to: rBot, control1: rCtrl, control2: rBot)
        p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.69),
                 radius: w * 0.47,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: top, control1: lBot, control2: lCtrl)
        p.closeSubpath()
        return p
    }
}

private struct CrystalDropHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // SVG: M512 200 C512 200 612 400 512 650 Z
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.69),
                   control1: CGPoint(x: w * 0.7, y: h * 0.3),
                   control2: CGPoint(x: w * 0.5, y: h * 0.69))
        p.closeSubpath()
        return p
    }
}

private struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.62),
            control1: CGPoint(x: w * 0.92, y: h * 0.18),
            control2: CGPoint(x: w, y: h * 0.42)
        )
        path.addArc(
            center: CGPoint(x: w / 2, y: h * 0.62),
            radius: w / 2,
            startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: w / 2, y: 0),
            control1: CGPoint(x: 0, y: h * 0.42),
            control2: CGPoint(x: w * 0.08, y: h * 0.18)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 案C: Neon Splash（ネオンスプラッシュ）
// 水面に水滴が落ちた瞬間を捉えた同心円デザイン

struct NeonSplashIcon: View {
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // リップル（同心円）
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.2, blue: 1.0).opacity(0.9 - Double(i) * 0.2),
                                Color(red: 0.1, green: 0.6, blue: 1.0).opacity(0.7 - Double(i) * 0.15),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1, size * 0.025 - CGFloat(i) * 0.5)
                    )
                    .frame(
                        width: size * (0.3 + Double(i) * 0.22),
                        height: size * (0.3 + Double(i) * 0.22)
                    )
            }

            // 中心の雫
            ZStack {
                DropShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.65, green: 0.3, blue: 1.0),
                                Color(red: 0.15, green: 0.55, blue: 1.0),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                DropShape()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.45), .clear],
                            startPoint: .topLeading, endPoint: UnitPoint(x: 0.5, y: 0.5)
                        )
                    )
            }
            .frame(width: size * 0.26, height: size * 0.32)
            .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.9), radius: size * 0.07)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview（3案並べて確認）

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.3, green: 0.45, blue: 0.85), Color(red: 0.5, green: 0.6, blue: 0.95)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("案A: Aurora Rain").foregroundStyle(.white).font(.headline)
            AuroraRainIcon(size: 110)

            Text("案B: Crystal Drop").foregroundStyle(.white).font(.headline)
            CrystalDropIcon(size: 110)

            Text("案C: Neon Splash").foregroundStyle(.white).font(.headline)
            NeonSplashIcon(size: 110)
        }
    }
}
