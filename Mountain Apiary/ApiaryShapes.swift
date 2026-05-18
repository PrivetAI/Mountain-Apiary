import SwiftUI

// MARK: - Hexagon (used as honeycomb/cell)
struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        let r = min(w, h) / 2.0
        for i in 0..<6 {
            let angle = (Double(i) * 60.0 - 30.0) * .pi / 180.0
            let x = cx + CGFloat(cos(angle)) * r
            let y = cy + CGFloat(sin(angle)) * r
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Hive (stacked boxes, custom)
struct HiveBoxShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Roof
        p.move(to: CGPoint(x: w*0.05, y: h*0.18))
        p.addLine(to: CGPoint(x: w*0.5, y: h*0.02))
        p.addLine(to: CGPoint(x: w*0.95, y: h*0.18))
        p.addLine(to: CGPoint(x: w*0.88, y: h*0.22))
        p.addLine(to: CGPoint(x: w*0.12, y: h*0.22))
        p.closeSubpath()
        // Box 1
        p.addRect(CGRect(x: w*0.12, y: h*0.24, width: w*0.76, height: h*0.22))
        // Box 2
        p.addRect(CGRect(x: w*0.12, y: h*0.48, width: w*0.76, height: h*0.22))
        // Box 3 entrance band
        p.addRect(CGRect(x: w*0.12, y: h*0.72, width: w*0.76, height: h*0.20))
        return p
    }
}

struct HiveEntranceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let slot = CGRect(x: w*0.3, y: h*0.78, width: w*0.4, height: h*0.06)
        p.addRoundedRect(in: slot, cornerSize: CGSize(width: 2, height: 2))
        return p
    }
}

struct HiveIcon: View {
    var size: CGFloat = 44
    var roofColor: Color = ApiaryTheme.walnut
    var bodyColor: Color = ApiaryTheme.amber
    var bandColor: Color = ApiaryTheme.walnut
    var body: some View {
        ZStack {
            // Roof triangle
            Path { p in
                p.move(to: CGPoint(x: size*0.05, y: size*0.22))
                p.addLine(to: CGPoint(x: size*0.5, y: size*0.04))
                p.addLine(to: CGPoint(x: size*0.95, y: size*0.22))
                p.closeSubpath()
            }.fill(roofColor)
            // Boxes
            RoundedRectangle(cornerRadius: 2)
                .fill(bodyColor)
                .frame(width: size*0.76, height: size*0.22)
                .offset(y: size*0.34 - size/2)
            RoundedRectangle(cornerRadius: 2)
                .fill(bodyColor.opacity(0.85))
                .frame(width: size*0.76, height: size*0.22)
                .offset(y: size*0.58 - size/2)
            // Bottom band with entrance
            RoundedRectangle(cornerRadius: 2)
                .fill(bandColor.opacity(0.85))
                .frame(width: size*0.76, height: size*0.20)
                .offset(y: size*0.82 - size/2)
            RoundedRectangle(cornerRadius: 1)
                .fill(ApiaryTheme.cream)
                .frame(width: size*0.35, height: size*0.05)
                .offset(y: size*0.82 - size/2)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Frame (rectangle with comb cells inside)
struct FrameIcon: View {
    var size: CGFloat = 36
    var color: Color = ApiaryTheme.walnut
    var fillColor: Color = ApiaryTheme.amber
    var fillLevel: Double = 0.5 // 0..1
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1.5)
            // Honey fill from bottom
            GeometryReader { geo in
                let h = geo.size.height
                Rectangle()
                    .fill(fillColor.opacity(0.7))
                    .frame(width: geo.size.width-4, height: h * CGFloat(fillLevel))
                    .offset(x: 2, y: h - h * CGFloat(fillLevel))
            }
            // Comb pattern
            VStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 1) {
                        ForEach(0..<5, id: \.self) { _ in
                            HexShape().stroke(color.opacity(0.6), lineWidth: 0.6)
                        }
                    }
                }
            }.padding(4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Jar
struct JarIcon: View {
    var size: CGFloat = 36
    var fill: Color = ApiaryTheme.amber
    var line: Color = ApiaryTheme.walnut
    var body: some View {
        ZStack {
            // Lid
            RoundedRectangle(cornerRadius: 2)
                .fill(line)
                .frame(width: size*0.55, height: size*0.12)
                .offset(y: -size*0.40)
            // Body
            RoundedRectangle(cornerRadius: 5)
                .fill(fill)
                .frame(width: size*0.7, height: size*0.68)
                .offset(y: size*0.04)
            RoundedRectangle(cornerRadius: 5)
                .stroke(line, lineWidth: 1.5)
                .frame(width: size*0.7, height: size*0.68)
                .offset(y: size*0.04)
            // Label band
            Rectangle()
                .fill(ApiaryTheme.cream)
                .frame(width: size*0.6, height: size*0.12)
                .offset(y: size*0.08)
            Rectangle()
                .stroke(line.opacity(0.4), lineWidth: 0.6)
                .frame(width: size*0.6, height: size*0.12)
                .offset(y: size*0.08)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Drop
struct DropIcon: View {
    var size: CGFloat = 22
    var color: Color = ApiaryTheme.amber
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size*0.5, y: size*0.05))
            p.addCurve(to: CGPoint(x: size*0.5, y: size*0.95),
                       control1: CGPoint(x: size*0.95, y: size*0.4),
                       control2: CGPoint(x: size*0.9, y: size*0.95))
            p.addCurve(to: CGPoint(x: size*0.5, y: size*0.05),
                       control1: CGPoint(x: size*0.1, y: size*0.95),
                       control2: CGPoint(x: size*0.05, y: size*0.4))
        }.fill(color)
        .frame(width: size, height: size)
    }
}

// MARK: - Coin
struct CoinIcon: View {
    var size: CGFloat = 18
    var color: Color = ApiaryTheme.amber
    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(ApiaryTheme.walnut.opacity(0.5), lineWidth: 1)
            Text("S")
                .font(.system(size: size*0.55, weight: .bold, design: .serif))
                .foregroundColor(ApiaryTheme.walnut)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Weather Icons
struct SunIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.amber
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: 2, height: size*0.18)
                    .offset(y: -size*0.45)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle().fill(color).frame(width: size*0.5, height: size*0.5)
        }
        .frame(width: size, height: size)
    }
}

struct CloudIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.walnut.opacity(0.7)
    var body: some View {
        ZStack {
            Circle().fill(color).frame(width: size*0.4, height: size*0.4).offset(x: -size*0.18, y: size*0.05)
            Circle().fill(color).frame(width: size*0.5, height: size*0.5).offset(x: size*0.08, y: 0)
            Circle().fill(color).frame(width: size*0.38, height: size*0.38).offset(x: size*0.25, y: size*0.1)
            Capsule().fill(color).frame(width: size*0.7, height: size*0.22).offset(y: size*0.18)
        }
        .frame(width: size, height: size)
    }
}

struct RainIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.sage
    var body: some View {
        ZStack {
            CloudIcon(size: size*0.9, color: ApiaryTheme.walnut.opacity(0.6))
                .offset(y: -size*0.1)
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: size*0.18)
                    .offset(x: CGFloat(i-1) * size*0.18, y: size*0.32)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SnowIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.walnut
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: 1.5, height: size*0.6)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .frame(width: size, height: size)
    }
}

struct WindIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.walnut.opacity(0.7)
    var body: some View {
        VStack(alignment: .leading, spacing: size*0.12) {
            Capsule().fill(color).frame(width: size*0.85, height: 2)
            Capsule().fill(color).frame(width: size*0.6, height: 2)
            Capsule().fill(color).frame(width: size*0.75, height: 2)
        }
        .frame(width: size, height: size)
    }
}

struct StormIcon: View {
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            CloudIcon(size: size, color: ApiaryTheme.walnut.opacity(0.75))
            Path { p in
                p.move(to: CGPoint(x: size*0.5, y: size*0.45))
                p.addLine(to: CGPoint(x: size*0.35, y: size*0.75))
                p.addLine(to: CGPoint(x: size*0.5, y: size*0.75))
                p.addLine(to: CGPoint(x: size*0.4, y: size*0.95))
                p.addLine(to: CGPoint(x: size*0.7, y: size*0.6))
                p.addLine(to: CGPoint(x: size*0.55, y: size*0.6))
                p.addLine(to: CGPoint(x: size*0.65, y: size*0.45))
                p.closeSubpath()
            }.fill(ApiaryTheme.amber)
        }
        .frame(width: size, height: size)
    }
}

struct MistIcon: View {
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.walnut.opacity(0.45)
    var body: some View {
        VStack(spacing: size*0.12) {
            Capsule().fill(color).frame(width: size*0.85, height: size*0.10)
            Capsule().fill(color).frame(width: size*0.7, height: size*0.10)
            Capsule().fill(color).frame(width: size*0.8, height: size*0.10)
            Capsule().fill(color).frame(width: size*0.6, height: size*0.10)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Person
struct PersonSilhouette: View {
    var size: CGFloat = 22
    var color: Color = ApiaryTheme.walnut
    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(color).frame(width: size*0.45, height: size*0.45)
            RoundedRectangle(cornerRadius: size*0.15)
                .fill(color)
                .frame(width: size*0.75, height: size*0.5)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chevron, Plus, Minus, Check, Gear, Lock
struct ChevronRightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct ChevronDownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

struct PlusShape: Shape {
    var thickness: CGFloat = 2.5
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(CGRect(x: rect.midX - thickness/2, y: rect.minY, width: thickness, height: rect.height))
        p.addRect(CGRect(x: rect.minX, y: rect.midY - thickness/2, width: rect.width, height: thickness))
        return p
    }
}

struct MinusShape: Shape {
    var thickness: CGFloat = 2.5
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.midY - thickness/2, width: rect.width, height: thickness))
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width*0.1, y: rect.midY + rect.height*0.05))
        p.addLine(to: CGPoint(x: rect.midX - rect.width*0.05, y: rect.maxY - rect.height*0.15))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width*0.1, y: rect.minY + rect.height*0.2))
        return p
    }
}

struct PadlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: w*0.15, y: h*0.4, width: w*0.7, height: h*0.55), cornerSize: CGSize(width: 4, height: 4))
        p.addArc(center: CGPoint(x: w*0.5, y: h*0.4), radius: w*0.22, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p.strokedPath(StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
}

struct GearShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let outer = min(rect.width, rect.height) / 2.0
        let teeth = 8
        for i in 0..<teeth*2 {
            let angle = (Double(i) * (180.0 / Double(teeth))) * .pi / 180.0
            let r = (i % 2 == 0) ? outer : outer * 0.78
            let x = cx + CGFloat(cos(angle)) * r
            let y = cy + CGFloat(sin(angle)) * r
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: cx - outer*0.32, y: cy - outer*0.32, width: outer*0.64, height: outer*0.64))
        return p
    }
}

// MARK: - Tab Icons
struct ApiaryTabIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        HiveIcon(size: size, roofColor: color, bodyColor: color, bandColor: color)
    }
}

struct MarketTabIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 2, y: size*0.3))
                p.addLine(to: CGPoint(x: size-2, y: size*0.3))
                p.addLine(to: CGPoint(x: size-2, y: size*0.9))
                p.addLine(to: CGPoint(x: 2, y: size*0.9))
                p.closeSubpath()
            }.stroke(color, lineWidth: 2)
            // Awning
            Path { p in
                p.move(to: CGPoint(x: 0, y: size*0.3))
                p.addLine(to: CGPoint(x: size*0.5, y: size*0.1))
                p.addLine(to: CGPoint(x: size, y: size*0.3))
                p.closeSubpath()
            }.fill(color)
            CoinIcon(size: size*0.35, color: color).offset(y: size*0.1)
        }
        .frame(width: size, height: size)
    }
}

struct InventoryTabIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 2)
            Rectangle().fill(color).frame(height: 2).offset(y: -size*0.05)
            Rectangle().fill(color).frame(width: 2).offset(x: -size*0.05, y: size*0.15)
            Rectangle().fill(color).frame(width: 2).offset(x: size*0.15, y: size*0.15)
        }
        .frame(width: size, height: size)
    }
}

struct AlmanacTabIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 2)
            Rectangle().fill(color).frame(width: size*0.7, height: 1.5).offset(y: -size*0.2)
            Rectangle().fill(color).frame(width: size*0.55, height: 1.5)
            Rectangle().fill(color).frame(width: size*0.6, height: 1.5).offset(y: size*0.2)
            HexShape().fill(color).frame(width: size*0.18, height: size*0.18).offset(x: size*0.28, y: -size*0.28)
        }
        .frame(width: size, height: size)
    }
}

struct MoreTabIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        HStack(spacing: size*0.15) {
            Circle().fill(color).frame(width: size*0.2, height: size*0.2)
            Circle().fill(color).frame(width: size*0.2, height: size*0.2)
            Circle().fill(color).frame(width: size*0.2, height: size*0.2)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Flower / Nectar marker for map
struct NectarMarker: View {
    var size: CGFloat = 22
    var color: Color = ApiaryTheme.sage
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(color.opacity(0.85))
                    .frame(width: size*0.4, height: size*0.4)
                    .offset(x: CGFloat(cos(Double(i) * .pi * 2 / 5)) * size*0.22,
                            y: CGFloat(sin(Double(i) * .pi * 2 / 5)) * size*0.22)
            }
            Circle().fill(ApiaryTheme.amber).frame(width: size*0.3, height: size*0.3)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mountain triangle for valley map
struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Generic abstract icon for inventory items (varies by type)
struct ItemGlyph: View {
    let kind: ItemGlyphKind
    var size: CGFloat = 30
    var color: Color = ApiaryTheme.walnut

    var body: some View {
        switch kind {
        case .frame: FrameIcon(size: size, color: color, fillColor: ApiaryTheme.amber.opacity(0.4), fillLevel: 0.0)
        case .jar: JarIcon(size: size, fill: ApiaryTheme.amber, line: color)
        case .smoker:
            ZStack {
                Capsule().fill(color.opacity(0.2)).frame(width: size*0.4, height: size*0.8)
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.4, height: size*0.8)
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(color.opacity(0.4))
                        .frame(width: size*(0.18 - CGFloat(i)*0.04), height: size*(0.18 - CGFloat(i)*0.04))
                        .offset(x: size*0.3, y: -size*0.25 - CGFloat(i)*size*0.12)
                }
            }
        case .tool:
            ZStack {
                Capsule().fill(color).frame(width: size*0.18, height: size*0.85)
                Path { p in
                    p.move(to: CGPoint(x: size*0.35, y: size*0.05))
                    p.addLine(to: CGPoint(x: size*0.55, y: size*0.05))
                    p.addLine(to: CGPoint(x: size*0.45, y: size*0.25))
                    p.closeSubpath()
                }.fill(color)
            }
        case .suit:
            ZStack {
                Circle().stroke(color, lineWidth: 1.5).frame(width: size*0.45, height: size*0.45).offset(y: -size*0.25)
                RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.2)).frame(width: size*0.7, height: size*0.45).offset(y: size*0.1)
                RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1.5).frame(width: size*0.7, height: size*0.45).offset(y: size*0.1)
            }
        case .syrup: DropIcon(size: size*0.75, color: color)
        case .medicine:
            ZStack {
                Circle().fill(ApiaryTheme.cream).frame(width: size*0.85, height: size*0.85)
                Circle().stroke(color, lineWidth: 1.5).frame(width: size*0.85, height: size*0.85)
                PlusShape(thickness: size*0.1).path(in: CGRect(x: size*0.3, y: size*0.3, width: size*0.4, height: size*0.4)).fill(color)
            }
        case .extractor:
            ZStack {
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.7, height: size*0.9)
                Rectangle().fill(color).frame(width: size*0.05, height: size*0.6).offset(y: -size*0.05)
                Circle().fill(color).frame(width: size*0.15, height: size*0.15).offset(y: -size*0.35)
            }
        case .trap:
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: size*0.5, y: size*0.05))
                    p.addLine(to: CGPoint(x: size*0.05, y: size*0.95))
                    p.addLine(to: CGPoint(x: size*0.95, y: size*0.95))
                    p.closeSubpath()
                }.stroke(color, lineWidth: 1.5)
                ForEach(0..<3, id: \.self) { i in
                    Rectangle().fill(color.opacity(0.5)).frame(width: size*(0.55 + CGFloat(i)*0.12), height: 1.5)
                        .offset(y: size*(0.35 + CGFloat(i)*0.18))
                }
            }
        case .scale:
            ZStack {
                Capsule().fill(color).frame(width: size*0.8, height: size*0.1).offset(y: size*0.3)
                Rectangle().fill(color).frame(width: 2, height: size*0.5).offset(y: size*0.05)
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.6, height: size*0.18).offset(y: -size*0.2)
            }
        case .label:
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(ApiaryTheme.amber.opacity(0.3)).frame(width: size*0.8, height: size*0.5)
                RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1.5).frame(width: size*0.8, height: size*0.5)
                Rectangle().fill(color.opacity(0.5)).frame(width: size*0.55, height: 1)
                Rectangle().fill(color.opacity(0.5)).frame(width: size*0.55, height: 1).offset(y: size*0.08)
            }
        case .super:
            ZStack {
                RoundedRectangle(cornerRadius: 2).stroke(color, lineWidth: 1.5).frame(width: size*0.85, height: size*0.5)
                Rectangle().fill(color.opacity(0.2)).frame(width: size*0.85, height: size*0.5)
                ForEach(0..<5, id: \.self) { i in
                    Rectangle().fill(color).frame(width: 1.5, height: size*0.4)
                        .offset(x: CGFloat(i - 2) * size*0.15)
                }
            }
        case .queenCell:
            ZStack {
                Capsule().fill(ApiaryTheme.amber).frame(width: size*0.4, height: size*0.7)
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.4, height: size*0.7)
                Circle().fill(color).frame(width: 4, height: 4).offset(y: -size*0.25)
            }
        case .pollen:
            ZStack {
                Circle().fill(ApiaryTheme.amber.opacity(0.7)).frame(width: size*0.35, height: size*0.35).offset(x: -size*0.15, y: -size*0.1)
                Circle().fill(ApiaryTheme.sage.opacity(0.7)).frame(width: size*0.4, height: size*0.4).offset(x: size*0.12, y: size*0.05)
                Circle().fill(ApiaryTheme.ember.opacity(0.7)).frame(width: size*0.3, height: size*0.3).offset(x: -size*0.05, y: size*0.2)
            }
        case .cover:
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: size*0.05, y: size*0.5))
                    p.addQuadCurve(to: CGPoint(x: size*0.95, y: size*0.5), control: CGPoint(x: size*0.5, y: size*0.1))
                    p.addLine(to: CGPoint(x: size*0.95, y: size*0.85))
                    p.addLine(to: CGPoint(x: size*0.05, y: size*0.85))
                    p.closeSubpath()
                }.fill(color.opacity(0.3))
                Path { p in
                    p.move(to: CGPoint(x: size*0.05, y: size*0.5))
                    p.addQuadCurve(to: CGPoint(x: size*0.95, y: size*0.5), control: CGPoint(x: size*0.5, y: size*0.1))
                }.stroke(color, lineWidth: 1.5)
            }
        case .refractometer:
            ZStack {
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.85, height: size*0.3)
                Circle().fill(color.opacity(0.3)).frame(width: size*0.18, height: size*0.18).offset(x: -size*0.3)
                Capsule().fill(color).frame(width: size*0.18, height: size*0.04).offset(x: size*0.2)
            }
        case .tank:
            ZStack {
                Capsule().fill(ApiaryTheme.amber.opacity(0.6)).frame(width: size*0.7, height: size*0.9)
                Capsule().stroke(color, lineWidth: 1.5).frame(width: size*0.7, height: size*0.9)
                Rectangle().fill(color).frame(width: size*0.1, height: size*0.18).offset(y: size*0.4)
            }
        case .excluder:
            ZStack {
                RoundedRectangle(cornerRadius: 2).stroke(color, lineWidth: 1.5).frame(width: size*0.85, height: size*0.65)
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(color).frame(width: size*0.7, height: 1.5)
                        .offset(y: CGFloat(i - 1) * size*0.15 - size*0.08)
                }
            }
        case .foundation:
            ZStack {
                RoundedRectangle(cornerRadius: 2).stroke(color, lineWidth: 1.5).frame(width: size*0.85, height: size*0.85)
                VStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 1) {
                            ForEach(0..<5, id: \.self) { _ in
                                HexShape().stroke(color.opacity(0.6), lineWidth: 0.6)
                            }
                        }
                    }
                }.padding(4)
            }
        }
    }
}

enum ItemGlyphKind {
    case frame, foundation, smoker, tool, suit, syrup, medicine, extractor, trap, scale, label, jar, `super`, queenCell, pollen, cover, refractometer, tank, excluder
}

// MARK: - Banner with hex pattern background
struct HexBackgroundPattern: View {
    var color: Color = ApiaryTheme.amber.opacity(0.10)
    var size: CGFloat = 30
    var body: some View {
        GeometryReader { geo in
            let cols = Int(ceil(geo.size.width / (size * 0.9))) + 2
            let rows = Int(ceil(geo.size.height / (size * 0.78))) + 2
            ZStack {
                ForEach(0..<rows, id: \.self) { r in
                    ForEach(0..<cols, id: \.self) { c in
                        let x = CGFloat(c) * size * 0.9 + (r.isMultiple(of: 2) ? 0 : size * 0.45)
                        let y = CGFloat(r) * size * 0.78
                        HexShape()
                            .stroke(color, lineWidth: 1)
                            .frame(width: size, height: size)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}
