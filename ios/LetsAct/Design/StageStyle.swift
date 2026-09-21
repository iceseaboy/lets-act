import SwiftUI

enum StageStyle {
    static let ivory = Color(hex: 0xFAF7F2)
    static let red = Color(hex: 0xE65D5D)
    static let ink = Color(hex: 0x29292E)
    static let muted = Color(hex: 0x68646A)
    static let paper = Color.white
    static let cast: [Color] = [Color(hex: 0xE7DFF3), Color(hex: 0xDDEBE1), Color(hex: 0xDFEAF2), Color(hex: 0xF5E1D3), Color(hex: 0xF1E8C7), Color(hex: 0xF3DEE2)]
    static func color(_ index: Int) -> Color { cast[abs(index) % cast.count] }
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

struct StageButtonStyle: ButtonStyle {
    var primary = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .padding(.horizontal, 24).frame(minHeight: 56)
            .foregroundStyle(primary ? Color.white : StageStyle.ink)
            .background(primary ? StageStyle.red : StageStyle.paper, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct RoleAvatar: View {
    let character: CastMember
    var size: CGFloat = 56
    var active = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.33).fill(StageStyle.color(character.colorIndex))
            Text(String(character.name.prefix(1))).font(.system(size: size * 0.43, weight: .medium, design: .rounded)).foregroundStyle(StageStyle.ink)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.33).stroke(active ? StageStyle.red : .clear, lineWidth: 3))
        .accessibilityHidden(true)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(.caption, design: .rounded).weight(.semibold)).tracking(2).foregroundStyle(StageStyle.muted) }
}

struct StageCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(24).background(StageStyle.paper, in: RoundedRectangle(cornerRadius: 24)) }
}

struct SpotlightArtwork: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                Ellipse().fill(StageStyle.ink.opacity(0.06)).frame(width: w * 0.83, height: h * 0.18).offset(y: h * 0.36)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.50, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.82))
                    path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.82), control: CGPoint(x: w * 0.5, y: h))
                    path.closeSubpath()
                }.fill(LinearGradient(colors: [Color(hex: 0xEFE2BE).opacity(0.12), Color(hex: 0xEFE2BE).opacity(0.68)], startPoint: .top, endPoint: .bottom))
                Image(systemName: "star.fill").font(.system(size: min(w, h) * 0.36, weight: .ultraLight)).foregroundStyle(Color(hex: 0xCEAD65)).rotationEffect(.degrees(-10)).offset(y: h * 0.1)
                Image(systemName: "moon.fill").font(.system(size: 22)).foregroundStyle(StageStyle.muted.opacity(0.45)).offset(x: w * 0.26, y: -h * 0.21)
                Circle().fill(StageStyle.red.opacity(0.65)).frame(width: 7, height: 7).offset(x: -w * 0.27, y: -h * 0.03)
            }
        }.accessibilityHidden(true)
    }
}
