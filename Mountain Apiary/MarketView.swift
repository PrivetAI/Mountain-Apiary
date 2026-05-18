import SwiftUI

struct MarketView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?

    var body: some View {
        ZStack {
            ApiaryTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerRow
                    inventoryStrip
                    buyersList
                    Spacer(minLength: 40)
                }
                .padding(14)
            }
        }
        .navigationBarHidden(true)
    }

    private var headerRow: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Market").font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    HStack(spacing: 6) {
                        CoinIcon(size: 16)
                        Text("\(store.state.resources.coins)")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(ApiaryTheme.walnut)
                    }
                }
                Text("Buyers visit the valley weekly. Prestige bumps every bid by ~1% per point.")
                    .font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.subtext)
            }
        }
    }

    private var inventoryStrip: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Your Honey Stocks").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    Text("\(totalJars()) jars").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                }
                if store.state.honeyInventory.isEmpty {
                    Text("No jars yet. Inspect hives, harvest frames, then return.")
                        .font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.subtext.opacity(0.9))
                        .padding(.vertical, 4)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.state.honeyInventory) { batch in
                                batchCard(batch)
                                    .onTapGesture { activeSheet = .sell(batch.id) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func batchCard(_ batch: HoneyBatch) -> some View {
        let honey = ApiaryCatalog.honeyType(id: batch.honeyTypeId)
        return VStack(spacing: 6) {
            JarIcon(size: 38, fill: parseColor(honey?.color), line: ApiaryTheme.walnut)
            Text(honey?.name ?? "Honey").font(.system(size: 11, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                .lineLimit(1)
            Text("\(batch.jars) jars").font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
        }
        .padding(8)
        .frame(width: 100)
        .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.cream))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
    }

    private var buyersList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Buyers This Week")
                .font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
            ForEach(ApiaryCatalog.buyers) { buyer in
                BuyerRow(buyer: buyer, prestige: store.state.prestige, week: store.state.weekOfYear, year: store.state.year)
                    .onTapGesture { activeSheet = .buyer(buyer.id) }
            }
        }
    }

    private func totalJars() -> Int {
        store.state.honeyInventory.reduce(0) { $0 + $1.jars }
    }

    private func parseColor(_ hex: String?) -> Color {
        guard let hex = hex else { return ApiaryTheme.amber }
        var h = hex
        if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16), h.count == 6 else { return ApiaryTheme.amber }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

struct BuyerRow: View {
    let buyer: Buyer
    let prestige: Int
    let week: Int
    let year: Int

    var body: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    PersonSilhouette(size: 32, color: ApiaryTheme.walnut)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(buyer.name).font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                        Text(buyer.archetype).font(ApiaryTheme.body(11)).foregroundColor(ApiaryTheme.subtext)
                    }
                    Spacer()
                    ApiaryPill(text: "Demand \(ApiaryEngine.buyerWeekDemand(buyer: buyer, week: week, year: year))", color: ApiaryTheme.sage)
                }
                HStack(spacing: 6) {
                    ForEach(buyer.preferredHoney.prefix(4), id: \.self) { honeyId in
                        if let honey = ApiaryCatalog.honeyType(id: honeyId) {
                            HStack(spacing: 3) {
                                Circle().fill(hex(honey.color)).frame(width: 8, height: 8)
                                Text(honey.name).font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(ApiaryTheme.text)
                                Text("\(ApiaryEngine.computeBuyerBid(buyer: buyer, honeyType: honey, prestige: prestige, week: week, year: year))s")
                                    .font(.system(size: 10, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(ApiaryTheme.cream))
                            .overlay(Capsule().stroke(ApiaryTheme.border, lineWidth: 0.6))
                        }
                    }
                }
                Text(buyer.blurb).font(.system(size: 11, design: .serif).italic()).foregroundColor(ApiaryTheme.subtext)
            }
        }
    }

    private func hex(_ s: String) -> Color {
        var h = s
        if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Sell sheet

struct SellBatchView: View {
    @EnvironmentObject var store: ApiaryStore
    let batchId: UUID
    let onClose: () -> Void
    @State private var selectedBuyerId: String? = nil
    @State private var jarCount: Int = 1

    var body: some View {
        Group {
            if let batch = store.state.honeyInventory.first(where: { $0.id == batchId }),
               let honey = ApiaryCatalog.honeyType(id: batch.honeyTypeId) {
                content(batch: batch, honey: honey)
            } else {
                VStack(spacing: 8) {
                    Text("This batch is no longer available.").font(ApiaryTheme.body(14)).foregroundColor(ApiaryTheme.text)
                    Button("Close", action: onClose).buttonStyle(ApiaryButtonStyle())
                }
            }
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private func content(batch: HoneyBatch, honey: HoneyType) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    JarIcon(size: 56, fill: hex(honey.color), line: ApiaryTheme.walnut)
                    VStack(alignment: .leading) {
                        Text(honey.name).font(ApiaryTheme.title(18)).foregroundColor(ApiaryTheme.text)
                        Text("\(batch.jars) jars · from \(batch.hiveName)")
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                    }
                    Spacer()
                }
                ApiaryCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Quantity").font(ApiaryTheme.heading(13)).foregroundColor(ApiaryTheme.text)
                            Spacer()
                            Text("\(jarCount) / \(batch.jars)").font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                        }
                        HStack(spacing: 8) {
                            Button(action: { jarCount = max(1, jarCount - 1) }) {
                                MinusShape(thickness: 3).path(in: CGRect(x: 0, y: 0, width: 18, height: 18))
                                    .fill(ApiaryTheme.walnut).frame(width: 18, height: 18)
                            }.buttonStyle(ApiaryGhostButtonStyle())
                            ApiaryProgressBar(value: Double(jarCount) / Double(max(1, batch.jars)))
                            Button(action: { jarCount = min(batch.jars, jarCount + 1) }) {
                                PlusShape(thickness: 3).path(in: CGRect(x: 0, y: 0, width: 18, height: 18))
                                    .fill(ApiaryTheme.walnut).frame(width: 18, height: 18)
                            }.buttonStyle(ApiaryGhostButtonStyle())
                            Button("All") { jarCount = batch.jars }
                                .buttonStyle(ApiaryGhostButtonStyle())
                        }
                    }
                }
                Text("Buyers").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                ForEach(ApiaryCatalog.buyers) { buyer in
                    let bid = ApiaryEngine.computeBuyerBid(buyer: buyer, honeyType: honey, prestige: store.state.prestige, week: store.state.weekOfYear, year: store.state.year)
                    Button(action: {
                        store.recordBuyerSale(buyer.id)
                        store.sell(batchId: batch.id, jarCount: jarCount, to: buyer, bid: bid)
                        onClose()
                    }) {
                        HStack {
                            PersonSilhouette(size: 26, color: ApiaryTheme.walnut)
                            VStack(alignment: .leading) {
                                Text(buyer.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                Text(buyer.archetype).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(bid)s / jar").font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                                Text("=\(bid * jarCount)s").font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }.padding(14)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Sell")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done", action: onClose).foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    private func hex(_ s: String) -> Color {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        return Color(red: Double((v>>16)&0xFF)/255.0, green: Double((v>>8)&0xFF)/255.0, blue: Double(v&0xFF)/255.0)
    }
}
