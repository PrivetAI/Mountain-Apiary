import SwiftUI

struct EventCardView: View {
    let event: ApiaryEvent
    let onClose: () -> Void
    @EnvironmentObject var store: ApiaryStore
    @State private var resolved: EventOption? = nil

    var body: some View {
        NavigationView {
            ZStack {
                ApiaryTheme.background.edgesIgnoringSafeArea(.all)
                HexBackgroundPattern(color: ApiaryTheme.amber.opacity(0.08), size: 38)
                    .opacity(0.7)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        bodyCard
                        if let result = resolved {
                            resultCard(result)
                        } else {
                            optionsCard
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(resolved == nil ? "Skip" : "Continue") {
                        onClose()
                    }.foregroundColor(ApiaryTheme.amber)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(ApiaryTheme.amber.opacity(0.18)).frame(width: 56, height: 56)
                HexShape().fill(ApiaryTheme.amber).frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("An Event").font(.system(size: 11, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
                Text(event.title).font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                HStack(spacing: 6) {
                    ForEach(event.allowedSeasons, id: \.self) { s in
                        ApiaryPill(text: s.displayName, color: ApiaryTheme.sage)
                    }
                }
            }
            Spacer()
        }
    }

    private var bodyCard: some View {
        ApiaryCard {
            Text(event.body).font(.system(size: 14, design: .serif)).foregroundColor(ApiaryTheme.text)
        }
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Decide").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
            ForEach(Array(event.options.enumerated()), id: \.offset) { _, option in
                Button(action: { chooseOption(option) }) {
                    HStack(alignment: .top, spacing: 10) {
                        HexShape().stroke(ApiaryTheme.amber, lineWidth: 2).frame(width: 16, height: 16).padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label).font(.system(size: 14, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                            costBadges(option)
                        }
                        Spacer()
                        ChevronRightShape().stroke(ApiaryTheme.amber, lineWidth: 2).frame(width: 8, height: 12)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func costBadges(_ option: EventOption) -> some View {
        HStack(spacing: 6) {
            if option.coinDelta != 0 {
                badge(text: "\(option.coinDelta > 0 ? "+" : "")\(option.coinDelta) silver",
                      color: option.coinDelta >= 0 ? ApiaryTheme.sage : ApiaryTheme.danger)
            }
            if option.prestigeDelta != 0 {
                badge(text: "\(option.prestigeDelta > 0 ? "+" : "")\(option.prestigeDelta) prestige",
                      color: option.prestigeDelta >= 0 ? ApiaryTheme.ember : ApiaryTheme.danger)
            }
            if option.populationDelta != 0 {
                badge(text: "\(option.populationDelta > 0 ? "+" : "")\(option.populationDelta) bees",
                      color: option.populationDelta >= 0 ? ApiaryTheme.sage : ApiaryTheme.danger)
            }
            if option.honeyFramesDelta != 0 {
                badge(text: "\(option.honeyFramesDelta > 0 ? "+" : "")\(option.honeyFramesDelta) frames",
                      color: option.honeyFramesDelta >= 0 ? ApiaryTheme.amber : ApiaryTheme.danger)
            }
            if let req = option.requiresItemId {
                badge(text: "needs \(req.replacingOccurrences(of: "_", with: " "))", color: ApiaryTheme.walnut)
            }
        }
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
            .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 0.7))
    }

    private func resultCard(_ option: EventOption) -> some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CheckShape().stroke(ApiaryTheme.sage, lineWidth: 3).frame(width: 22, height: 16)
                    Text("Outcome").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                }
                Text(option.resultText).font(.system(size: 14, design: .serif)).foregroundColor(ApiaryTheme.text)
                costBadges(option)
                Button(action: onClose) {
                    HStack {
                        Spacer()
                        Text("Continue").font(.system(size: 14, weight: .semibold))
                        ChevronRightShape().stroke(Color.white, lineWidth: 2).frame(width: 8, height: 12)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [ApiaryTheme.amber, ApiaryTheme.ember],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func chooseOption(_ option: EventOption) {
        store.resolveEvent(event, option: option)
        resolved = option
    }
}
