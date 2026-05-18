import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?
    @State private var section: Int = 0

    var body: some View {
        ZStack {
            ApiaryTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    sectionPicker
                    if section == 0 { resourcesGrid }
                    if section == 1 { honeyGrid }
                    if section == 2 { upgradesRow }
                    Spacer(minLength: 40)
                }
                .padding(14)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Inventory").font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    Button(action: { activeSheet = .shop }) {
                        HStack(spacing: 4) {
                            CoinIcon(size: 14)
                            Text("Shop").font(.system(size: 13, weight: .semibold))
                        }
                    }.buttonStyle(ApiaryButtonStyle())
                    Button(action: { activeSheet = .upgrades }) {
                        Text("Upgrades").font(.system(size: 13, weight: .semibold))
                    }.buttonStyle(ApiaryGhostButtonStyle(color: ApiaryTheme.amber))
                }
                HStack(spacing: 8) {
                    pill("Coins", "\(store.state.resources.coins)")
                    pill("Slots", "\(store.state.hives.count)/\(store.state.hiveSlots)")
                    pill("Prestige", "\(store.state.prestige)")
                }
            }
        }
    }

    private func pill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(ApiaryTheme.cream))
        .overlay(Capsule().stroke(ApiaryTheme.border, lineWidth: 0.6))
    }

    private var sectionPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Button(action: { section = i }) {
                    Text(["Resources", "Honey", "Upgrades"][i])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(section == i ? .white : ApiaryTheme.text)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            Capsule().fill(section == i ? ApiaryTheme.amber : ApiaryTheme.cream)
                        )
                        .overlay(
                            Capsule().stroke(section == i ? Color.clear : ApiaryTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var resourcesGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            resourceCell("Sugar Syrup", value: "\(store.state.resources.sugarKg) kg", kind: .syrup)
            resourceCell("Mite Strips", value: "\(store.state.resources.mitestrips)", kind: .medicine)
            resourceCell("Antibiotics", value: "\(store.state.resources.antibiotics)", kind: .medicine)
            resourceCell("Hornet Traps", value: "\(store.state.resources.hornetTraps)", kind: .trap)
            resourceCell("Empty Frames", value: "\(store.state.resources.emptyFramesStock)", kind: .frame)
            resourceCell("Jars", value: "\(store.state.resources.jarsStock)", kind: .jar)
            resourceCell("Supers", value: "\(store.state.resources.supersStock)", kind: .super)
        }
    }

    private func resourceCell(_ name: String, value: String, kind: ItemGlyphKind) -> some View {
        VStack(spacing: 8) {
            ItemGlyph(kind: kind, size: 38, color: ApiaryTheme.walnut)
            Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
            Text(value).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
    }

    private var honeyGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.state.honeyInventory.isEmpty {
                Text("No honey jars yet. Harvest frames in the Apiary, then come back.")
                    .font(ApiaryTheme.body(13)).foregroundColor(ApiaryTheme.subtext)
                    .padding(.vertical, 10)
            } else {
                ForEach(store.state.honeyInventory) { batch in
                    HoneyBatchRow(batch: batch).onTapGesture {
                        activeSheet = .sell(batch.id)
                    }
                }
            }
        }
    }

    private var upgradesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(ApiaryCatalog.upgrades) { up in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(up.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                        Text(up.description).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                    }
                    Spacer()
                    if store.hasUpgrade(up.id) {
                        CheckShape().stroke(ApiaryTheme.sage, lineWidth: 2.5).frame(width: 18, height: 14)
                    } else {
                        Text("\(up.cost)s").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
            }
        }
    }

}

struct HoneyBatchRow: View {
    let batch: HoneyBatch
    var body: some View {
        let honey = ApiaryCatalog.honeyType(id: batch.honeyTypeId)
        HStack {
            JarIcon(size: 36, fill: hex(honey?.color ?? "#D49B3A"), line: ApiaryTheme.walnut)
            VStack(alignment: .leading) {
                Text(honey?.name ?? "Honey").font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                Text("Y\(batch.harvestedYear)·W\(batch.harvestedWeek) · \(batch.hiveName)")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
            }
            Spacer()
            Text("\(batch.jars)").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
            Text("jars").font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
    }

    private func hex(_ s: String) -> Color {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        return Color(red: Double((v>>16)&0xFF)/255.0, green: Double((v>>8)&0xFF)/255.0, blue: Double(v&0xFF)/255.0)
    }
}

// MARK: - Shop & Upgrades

struct ShopView: View {
    @EnvironmentObject var store: ApiaryStore
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("General Store").font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    HStack(spacing: 4) { CoinIcon(size: 14); Text("\(store.state.resources.coins)").font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.walnut) }
                }
                Text("Equip your apiary with frames, feed, and tools.")
                    .font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.subtext)
                ForEach(["Equipment", "Feed", "Tool", "Medicine", "Defense", "Packaging", "Apparel", "Livestock"], id: \.self) { category in
                    let items = ApiaryCatalog.inventoryItems.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category).font(ApiaryTheme.heading(13)).foregroundColor(ApiaryTheme.text)
                            ForEach(items) { item in
                                shopRow(item)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    private func shopRow(_ item: InventoryItem) -> some View {
        HStack {
            ItemGlyph(kind: glyphKind(item.glyph), size: 36, color: ApiaryTheme.walnut)
            VStack(alignment: .leading) {
                Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                Text(item.description).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext).lineLimit(2)
            }
            Spacer()
            Button(action: { store.buyResource(itemId: item.id) }) {
                HStack(spacing: 3) {
                    CoinIcon(size: 12)
                    Text("\(item.price)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
            }
            .buttonStyle(ApiaryButtonStyle())
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
    }

    private func glyphKind(_ s: String) -> ItemGlyphKind {
        switch s {
        case "frame": return .frame
        case "foundation": return .foundation
        case "smoker": return .smoker
        case "tool": return .tool
        case "suit": return .suit
        case "syrup": return .syrup
        case "medicine": return .medicine
        case "extractor": return .extractor
        case "trap": return .trap
        case "scale": return .scale
        case "label": return .label
        case "jar": return .jar
        case "super": return .super
        case "queenCell": return .queenCell
        case "pollen": return .pollen
        case "cover": return .cover
        case "refractometer": return .refractometer
        case "tank": return .tank
        case "excluder": return .excluder
        default: return .tool
        }
    }
}

struct UpgradesView: View {
    @EnvironmentObject var store: ApiaryStore
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Apiary Upgrades").font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    HStack(spacing: 4) { CoinIcon(size: 14); Text("\(store.state.resources.coins)").font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.walnut) }
                }
                Text("Permanent improvements. Some need prestige.").font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.subtext)
                ForEach(ApiaryCatalog.upgrades) { up in
                    upgradeRow(up)
                }
            }
            .padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Upgrades")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    private func upgradeRow(_ up: Upgrade) -> some View {
        let owned = store.hasUpgrade(up.id)
        let canAfford = store.state.resources.coins >= up.cost
        let hasPrestige = store.state.prestige >= up.requiredPrestige
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(up.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                Text(up.description).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                HStack(spacing: 6) {
                    if up.requiredPrestige > 0 {
                        ApiaryPill(text: "Need \(up.requiredPrestige) prestige", color: hasPrestige ? ApiaryTheme.sage : ApiaryTheme.danger)
                    }
                }
            }
            Spacer()
            if owned {
                CheckShape().stroke(ApiaryTheme.sage, lineWidth: 2.5).frame(width: 22, height: 16)
            } else {
                Button(action: { store.buyUpgrade(up) }) {
                    HStack(spacing: 3) {
                        CoinIcon(size: 12)
                        Text("\(up.cost)").font(.system(size: 12, weight: .semibold, design: .monospaced))
                    }
                }
                .buttonStyle(ApiaryButtonStyle(fill: (canAfford && hasPrestige) ? ApiaryTheme.amber : ApiaryTheme.walnut.opacity(0.4)))
                .disabled(!(canAfford && hasPrestige))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
    }
}
