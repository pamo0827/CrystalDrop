import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            // 背景グラデーション (AppColors 名前空間を使用)
            LinearGradient(
                colors: AppColors.rainyGradients, 
                startPoint: .top, 
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("CrystalDropLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 20)

                VStack(spacing: 4) {
                    Text("Rain Alert")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("雨アラート")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .kerning(4)
                }
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
