import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?

    var body: some View {
        ZStack {
            ApiaryTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("More").font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                        Spacer()
                    }
                    statsCard
                    hubButton("Quests", subtitle: "\(completedQuests()) of \(store.state.quests.count) complete") {
                        activeSheet = .quests
                    }
                    hubButton("Achievements", subtitle: "\(unlockedAchievements()) of \(store.state.achievements.count) unlocked") {
                        activeSheet = .achievements
                    }
                    hubButton("Upgrades", subtitle: "\(store.state.purchasedUpgradeIds.count) of \(ApiaryCatalog.upgrades.count) purchased") {
                        activeSheet = .upgrades
                    }
                    hubButton("Shop", subtitle: "Equipment, feed, medicine") {
                        activeSheet = .shop
                    }
                    hubButton("Settings", subtitle: "Privacy policy, reset") {
                        activeSheet = .settings
                    }
                    historyCard
                    Spacer(minLength: 40)
                }
                .padding(14)
            }
        }
        .navigationBarHidden(true)
    }

    private func completedQuests() -> Int { store.state.quests.filter { $0.completed }.count }
    private func unlockedAchievements() -> Int { store.state.achievements.filter { $0.unlockedYear != nil }.count }

    private var statsCard: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Apiary Ledger").font(ApiaryTheme.heading(15))
                ApiaryStatRow(label: "Years played", value: "\(store.state.year)", tint: ApiaryTheme.amber)
                ApiaryStatRow(label: "Total silver earned", value: "\(store.state.totalSilverEarned)")
                ApiaryStatRow(label: "Jars sold this year", value: "\(store.state.sellsThisYear)")
                ApiaryStatRow(label: "Prestige", value: "\(store.state.prestige)", tint: ApiaryTheme.ember)
                ApiaryStatRow(label: "Hive slots", value: "\(store.state.hives.count) / \(store.state.hiveSlots)")
            }
        }
    }

    private func hubButton(_ title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                    Text(subtitle).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                }
                Spacer()
                ChevronRightShape().stroke(ApiaryTheme.amber, lineWidth: 2).frame(width: 10, height: 14)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var historyCard: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Keeper's Log").font(ApiaryTheme.heading(13)).foregroundColor(ApiaryTheme.text)
                if store.state.log.isEmpty {
                    Text("No entries yet.").font(.system(size: 12)).foregroundColor(ApiaryTheme.subtext)
                } else {
                    ForEach(Array(store.state.log.prefix(12).enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 6) {
                            HexShape().fill(ApiaryTheme.amber.opacity(0.7)).frame(width: 6, height: 6).padding(.top, 6)
                            Text(line).font(.system(size: 11, design: .serif)).foregroundColor(ApiaryTheme.text)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Quests

struct QuestsView: View {
    @EnvironmentObject var store: ApiaryStore
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Three Acts").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.subtext)
                Text("A heritage apiary is dying. Find your footing, win the buyers' trust, then restore the valley to its old fame.")
                    .font(.system(size: 12, design: .serif).italic()).foregroundColor(ApiaryTheme.subtext)
                ForEach([1, 2, 3], id: \.self) { act in
                    let acts = store.state.quests.filter { $0.act == act }
                    if !acts.isEmpty {
                        Text("Act \(act)").font(ApiaryTheme.title(18)).foregroundColor(ApiaryTheme.amber)
                            .padding(.top, 6)
                        ForEach(acts) { q in
                            HStack(alignment: .top) {
                                Group {
                                    if q.completed {
                                        CheckShape().stroke(ApiaryTheme.sage, lineWidth: 2.5).frame(width: 18, height: 14)
                                    } else {
                                        Circle().stroke(ApiaryTheme.border, lineWidth: 1.5).frame(width: 14, height: 14)
                                    }
                                }.padding(.top, 4)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(q.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                    Text(q.goal).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                                    Text("Reward: \(q.reward)").font(.system(size: 10, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.card))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Quests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }
}

// MARK: - Achievements

struct AchievementsView: View {
    @EnvironmentObject var store: ApiaryStore
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(store.state.achievements.filter { $0.unlockedYear != nil }.count) of \(store.state.achievements.count) unlocked")
                    .font(.system(size: 12, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(store.state.achievements) { a in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if a.unlockedYear != nil {
                                    HexShape().fill(ApiaryTheme.amber).frame(width: 22, height: 22)
                                } else {
                                    PadlockShape().fill(ApiaryTheme.walnut.opacity(0.4)).frame(width: 22, height: 22)
                                }
                                Spacer()
                                if let y = a.unlockedYear {
                                    ApiaryPill(text: "Y\(y)", color: ApiaryTheme.sage)
                                }
                            }
                            Text(a.name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                .multilineTextAlignment(.leading)
                            Text(a.description).font(.system(size: 10)).foregroundColor(ApiaryTheme.subtext)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.card.opacity(a.unlockedYear == nil ? 0.7 : 1)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
                    }
                }
            }
            .padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetConfirm: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mountain Apiary").font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                Text("A quiet valley simulation of beekeeping, weekly weather, and the honey market.")
                    .font(.system(size: 12, design: .serif).italic()).foregroundColor(ApiaryTheme.subtext)

                ApiaryCard {
                    VStack(spacing: 10) {
                        Button(action: { activeSheet = .privacy }) {
                            HStack {
                                Text("Privacy Policy").font(.system(size: 14, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                Spacer()
                                ChevronRightShape().stroke(ApiaryTheme.amber, lineWidth: 2).frame(width: 8, height: 12)
                            }
                        }
                        .buttonStyle(.plain)
                        Divider()
                        Button(action: { showResetConfirm = true }) {
                            HStack {
                                Text("Reset Game").font(.system(size: 14, weight: .semibold)).foregroundColor(ApiaryTheme.danger)
                                Spacer()
                                ChevronRightShape().stroke(ApiaryTheme.danger, lineWidth: 2).frame(width: 8, height: 12)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                ApiaryCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("About").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                        Text("Version 1.0. All progress is stored locally. The valley remembers what you do.")
                            .font(.system(size: 12)).foregroundColor(ApiaryTheme.subtext)
                    }
                }
                Spacer(minLength: 40)
            }.padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset Game"),
                  message: Text("All progress will be lost. Continue?"),
                  primaryButton: .destructive(Text("Reset"), action: {
                      store.resetGame()
                      presentationMode.wrappedValue.dismiss()
                  }),
                  secondaryButton: .cancel())
        }
    }
}
