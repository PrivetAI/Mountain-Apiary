import SwiftUI

enum ActiveSheet: Identifiable {
    case hiveDetail(UUID)
    case eventCard(ApiaryEvent)
    case yearSummary
    case weekSummary
    case privacy
    case settings
    case quests
    case achievements
    case race(BeeRace)
    case nectar(String)
    case honey(String)
    case buyer(String)
    case upgrades
    case shop
    case sell(UUID)

    var id: String {
        switch self {
        case .hiveDetail(let id): return "hive-\(id.uuidString)"
        case .eventCard(let e): return "event-\(e.id)"
        case .yearSummary: return "year"
        case .weekSummary: return "week"
        case .privacy: return "privacy"
        case .settings: return "settings"
        case .quests: return "quests"
        case .achievements: return "achievements"
        case .race(let r): return "race-\(r.rawValue)"
        case .nectar(let id): return "nectar-\(id)"
        case .honey(let id): return "honey-\(id)"
        case .buyer(let id): return "buyer-\(id)"
        case .upgrades: return "upgrades"
        case .shop: return "shop"
        case .sell(let id): return "sell-\(id.uuidString)"
        }
    }
}

struct ContentView: View {
    @StateObject private var store = ApiaryStore()
    @State private var selectedTab: Int = 0
    @State private var activeSheet: ActiveSheet? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { ApiaryView(activeSheet: $activeSheet).environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { MarketView(activeSheet: $activeSheet).environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { InventoryView(activeSheet: $activeSheet).environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { AlmanacView(activeSheet: $activeSheet).environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { MoreView(activeSheet: $activeSheet).environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ApiaryTabBar(selected: $selectedTab)
            }
            .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            // Auto-display pending event card if any (from advance week)
            // This routine handles freshly opened app
        }
        .onChange(of: store.pendingEvents.count) { _ in
            // Surface the first event when produced
            if activeSheet == nil, let evt = store.pendingEvents.first {
                activeSheet = .eventCard(evt)
            }
        }
        .onChange(of: store.weekSummary?.id) { _ in
            if activeSheet == nil && store.weekSummary != nil && store.pendingEvents.isEmpty {
                activeSheet = .weekSummary
            }
        }
        .onChange(of: store.yearSummary?.id) { _ in
            if store.yearSummary != nil {
                activeSheet = .yearSummary
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .hiveDetail(let id):
            NavigationView {
                HiveDetailView(hiveId: id, activeSheet: $activeSheet)
                    .environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .eventCard(let event):
            EventCardView(event: event, onClose: {
                store.pendingEvents.removeAll { $0.id == event.id }
                activeSheet = nil
                if let next = store.pendingEvents.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        activeSheet = .eventCard(next)
                    }
                } else if store.weekSummary != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        activeSheet = .weekSummary
                    }
                }
            }).environmentObject(store)
        case .yearSummary:
            NavigationView {
                YearSummarySheet(onClose: {
                    store.yearSummary = nil
                    activeSheet = nil
                })
                .environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .weekSummary:
            NavigationView {
                WeekSummarySheet(onClose: {
                    store.weekSummary = nil
                    activeSheet = nil
                }).environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .privacy:
            MountainApiaryWebPanel(urlString: "https://mountainapiary.org/click.php")
                .edgesIgnoringSafeArea(.all)
        case .settings:
            NavigationView {
                SettingsView(activeSheet: $activeSheet).environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .quests:
            NavigationView {
                QuestsView().environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .achievements:
            NavigationView {
                AchievementsView().environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .race(let race):
            NavigationView {
                RaceDetailView(race: race)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .nectar(let id):
            NavigationView {
                NectarDetailView(nectarId: id)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .honey(let id):
            NavigationView {
                HoneyDetailView(honeyId: id)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .buyer(let id):
            NavigationView {
                BuyerDetailView(buyerId: id)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .upgrades:
            NavigationView {
                UpgradesView().environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .shop:
            NavigationView {
                ShopView().environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        case .sell(let batchId):
            NavigationView {
                SellBatchView(batchId: batchId, onClose: { activeSheet = nil }).environmentObject(store)
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Tab bar
struct ApiaryTabBar: View {
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 0) {
            tabButton(0, label: "Apiary") {
                AnyView(ApiaryTabIcon(size: 24, color: selected == 0 ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.45)))
            }
            tabButton(1, label: "Market") {
                AnyView(MarketTabIcon(size: 24, color: selected == 1 ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.45)))
            }
            tabButton(2, label: "Inventory") {
                AnyView(InventoryTabIcon(size: 24, color: selected == 2 ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.45)))
            }
            tabButton(3, label: "Almanac") {
                AnyView(AlmanacTabIcon(size: 24, color: selected == 3 ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.45)))
            }
            tabButton(4, label: "More") {
                AnyView(MoreTabIcon(size: 24, color: selected == 4 ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.45)))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            ApiaryTheme.card
                .overlay(
                    Rectangle().fill(ApiaryTheme.border).frame(height: 1).frame(maxHeight: .infinity, alignment: .top)
                )
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, label: String, icon: @escaping () -> AnyView) -> some View {
        Button(action: { selected = index }) {
            VStack(spacing: 4) {
                icon()
                Text(label)
                    .font(.system(size: 11, weight: selected == index ? .semibold : .regular))
                    .foregroundColor(selected == index ? ApiaryTheme.amber : ApiaryTheme.text.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
