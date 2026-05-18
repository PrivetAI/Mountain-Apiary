import SwiftUI

struct AlmanacView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?
    @State private var tab: Int = 0

    var body: some View {
        ZStack {
            ApiaryTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Almanac").font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                        Spacer()
                    }
                    Text("Knowledge of the valley: the races of bees, the nectars they harvest, the honeys they make, and the buyers who seek them.")
                        .font(.system(size: 12, design: .serif).italic()).foregroundColor(ApiaryTheme.subtext)
                    tabs
                    Group {
                        switch tab {
                        case 0: racesSection
                        case 1: nectarsSection
                        case 2: honeysSection
                        case 3: buyersSection
                        default: weatherSection
                        }
                    }
                    Spacer(minLength: 40)
                }
                .padding(14)
            }
        }
        .navigationBarHidden(true)
    }

    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    Button(action: { tab = i }) {
                        Text(["Races", "Nectars", "Honeys", "Buyers", "Weather"][i])
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(tab == i ? ApiaryTheme.amber : ApiaryTheme.cream))
                            .overlay(Capsule().stroke(tab == i ? Color.clear : ApiaryTheme.border, lineWidth: 1))
                            .foregroundColor(tab == i ? .white : ApiaryTheme.text)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var racesSection: some View {
        VStack(spacing: 10) {
            ForEach(BeeRace.allCases, id: \.self) { race in
                Button(action: { activeSheet = .race(race) }) {
                    HStack {
                        ZStack {
                            Circle().fill(raceColor(race)).frame(width: 36, height: 36)
                            HexShape().fill(ApiaryTheme.cream).frame(width: 18, height: 18)
                        }
                        VStack(alignment: .leading) {
                            Text(race.displayName).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                            Text(race.profile.blurb).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext).multilineTextAlignment(.leading)
                        }
                        Spacer()
                        ChevronRightShape().stroke(ApiaryTheme.subtext, lineWidth: 2).frame(width: 8, height: 12)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func raceColor(_ r: BeeRace) -> Color {
        switch r {
        case .carniolan: return ApiaryTheme.walnut
        case .italian: return ApiaryTheme.amber
        case .russian: return Color(red: 130/255, green: 90/255, blue: 60/255)
        case .buckfast: return ApiaryTheme.ember
        case .caucasian: return Color(red: 90/255, green: 110/255, blue: 130/255)
        }
    }

    private var nectarsSection: some View {
        VStack(spacing: 8) {
            ForEach(ApiaryCatalog.nectarBlooms) { bloom in
                Button(action: { activeSheet = .nectar(bloom.id) }) {
                    HStack {
                        NectarMarker(size: 26, color: ApiaryTheme.sage)
                        VStack(alignment: .leading) {
                            Text(bloom.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                            HStack(spacing: 6) {
                                Text("Wk \(bloom.startWeek)–\(bloom.endWeek)").font(.system(size: 10, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                                rarityDots(bloom.rarity)
                            }
                        }
                        Spacer()
                        ChevronRightShape().stroke(ApiaryTheme.subtext, lineWidth: 2).frame(width: 8, height: 12)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func rarityDots(_ n: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Circle().fill(i < n ? ApiaryTheme.amber : ApiaryTheme.walnut.opacity(0.18))
                    .frame(width: 5, height: 5)
            }
        }
    }

    private var honeysSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(ApiaryCatalog.honeyTypes) { honey in
                Button(action: { activeSheet = .honey(honey.id) }) {
                    VStack(spacing: 6) {
                        JarIcon(size: 40, fill: hex(honey.color), line: ApiaryTheme.walnut)
                        Text(honey.name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                            .multilineTextAlignment(.center).lineLimit(2)
                        Text("\(honey.basePrice)s · Tier \(honey.tier)").font(.system(size: 10, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buyersSection: some View {
        VStack(spacing: 8) {
            ForEach(ApiaryCatalog.buyers) { buyer in
                Button(action: { activeSheet = .buyer(buyer.id) }) {
                    HStack {
                        PersonSilhouette(size: 28, color: ApiaryTheme.walnut)
                        VStack(alignment: .leading) {
                            Text(buyer.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                            Text(buyer.archetype).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                        }
                        Spacer()
                        ChevronRightShape().stroke(ApiaryTheme.subtext, lineWidth: 2).frame(width: 8, height: 12)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weatherSection: some View {
        VStack(spacing: 8) {
            Text("Weather Log").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
            ForEach(Array(store.state.weatherLog.suffix(20).reversed().enumerated()), id: \.offset) { _, entry in
                HStack {
                    weatherIcon(entry.weather, size: 20)
                    Text("Y\(entry.year)·W\(entry.week)")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                    Text(entry.weather.displayName).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    Text("\(entry.totalNectarYield) frames").font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.amber)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
            }
            if store.state.weatherLog.isEmpty {
                Text("No weather recorded yet. Advance a week.").font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.subtext)
            }
        }
    }

    private func hex(_ s: String) -> Color {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        return Color(red: Double((v>>16)&0xFF)/255.0, green: Double((v>>8)&0xFF)/255.0, blue: Double(v&0xFF)/255.0)
    }
}

// MARK: - Detail screens (Race / Nectar / Honey / Buyer)

struct RaceDetailView: View {
    let race: BeeRace
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle().fill(ApiaryTheme.amber.opacity(0.25)).frame(width: 70, height: 70)
                        HexShape().fill(ApiaryTheme.amber).frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading) {
                        Text(race.displayName).font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                        Text("Bee Race").font(.system(size: 12)).foregroundColor(ApiaryTheme.subtext)
                    }
                    Spacer()
                }
                Text(race.profile.blurb).font(.system(size: 14, design: .serif).italic()).foregroundColor(ApiaryTheme.text)
                ApiaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mechanical Effects").font(ApiaryTheme.heading(14))
                        ApiaryStatRow(label: "Temperament base", value: "\(race.profile.temperament)/100")
                        ApiaryStatRow(label: "Forage yield multiplier", value: String(format: "x%.2f", race.profile.yieldMult), tint: ApiaryTheme.amber)
                        ApiaryStatRow(label: "Disease resistance", value: String(format: "+%.0f%%", race.profile.diseaseResist * 100), tint: ApiaryTheme.sage)
                        ApiaryStatRow(label: "Honey rate", value: String(format: "x%.2f", race.profile.honeyRate))
                        ApiaryStatRow(label: "Brood rate", value: String(format: "x%.2f", race.profile.broodRate))
                        ApiaryStatRow(label: "Winter hardiness", value: String(format: "+%.0f%%", race.profile.winterHardiness * 100), tint: ApiaryTheme.sage)
                    }
                }
            }
            .padding(14)
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Race")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }
}

struct NectarDetailView: View {
    let nectarId: String
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Group {
            if let bloom = ApiaryCatalog.nectar(id: nectarId), let honey = ApiaryCatalog.honeyType(id: bloom.honeyTypeId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            NectarMarker(size: 50, color: ApiaryTheme.sage)
                            VStack(alignment: .leading) {
                                Text(bloom.name).font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                                Text("Bloom: Week \(bloom.startWeek)–\(bloom.endWeek)")
                                    .font(.system(size: 12, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                        }
                        Text(bloom.lore).font(.system(size: 13, design: .serif).italic()).foregroundColor(ApiaryTheme.text)
                        ApiaryCard {
                            VStack(alignment: .leading, spacing: 6) {
                                ApiaryStatRow(label: "Yield factor", value: String(format: "x%.2f", bloom.yieldFactor))
                                ApiaryStatRow(label: "Rarity", value: String(repeating: "*", count: bloom.rarity))
                                ApiaryStatRow(label: "Produces honey", value: honey.name, tint: ApiaryTheme.amber)
                                HStack {
                                    Text("Prefers weather").font(ApiaryTheme.body(13)).foregroundColor(ApiaryTheme.subtext)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        ForEach(bloom.preferredWeather, id: \.self) { w in
                                            weatherIcon(w, size: 18)
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(14)
                }
            } else {
                Text("Bloom unknown.")
            }
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Nectar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }
}

struct HoneyDetailView: View {
    let honeyId: String
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Group {
            if let honey = ApiaryCatalog.honeyType(id: honeyId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            JarIcon(size: 60, fill: hex(honey.color), line: ApiaryTheme.walnut)
                            VStack(alignment: .leading) {
                                Text(honey.name).font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                                Text("Tier \(honey.tier) · base \(honey.basePrice) silver/jar")
                                    .font(.system(size: 12, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                        }
                        Text(honey.description).font(.system(size: 13, design: .serif).italic()).foregroundColor(ApiaryTheme.text)
                        ApiaryCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Preferred Buyers").font(ApiaryTheme.heading(14))
                                ForEach(honey.preferredBuyerIds, id: \.self) { id in
                                    if let b = ApiaryCatalog.buyer(id: id) {
                                        HStack {
                                            PersonSilhouette(size: 18, color: ApiaryTheme.walnut)
                                            Text(b.name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                            Spacer()
                                            Text(b.archetype).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(14)
                }
            } else { Text("Honey unknown.") }
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Honey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    private func hex(_ s: String) -> Color {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        return Color(red: Double((v>>16)&0xFF)/255.0, green: Double((v>>8)&0xFF)/255.0, blue: Double(v&0xFF)/255.0)
    }
}

struct BuyerDetailView: View {
    let buyerId: String
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Group {
            if let buyer = ApiaryCatalog.buyer(id: buyerId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            PersonSilhouette(size: 48, color: ApiaryTheme.walnut)
                            VStack(alignment: .leading) {
                                Text(buyer.name).font(ApiaryTheme.title(22)).foregroundColor(ApiaryTheme.text)
                                Text(buyer.archetype).font(.system(size: 12)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                        }
                        Text(buyer.blurb).font(.system(size: 13, design: .serif).italic()).foregroundColor(ApiaryTheme.text)
                        ApiaryCard {
                            VStack(alignment: .leading, spacing: 6) {
                                ApiaryStatRow(label: "Price multiplier", value: String(format: "x%.2f", buyer.basePriceMult), tint: ApiaryTheme.amber)
                                ApiaryStatRow(label: "Demand range", value: "up to ~\(buyer.demandMax) jars/wk", tint: ApiaryTheme.sage)
                                Text("Preferred Honeys").font(ApiaryTheme.heading(13)).padding(.top, 4)
                                ForEach(buyer.preferredHoney, id: \.self) { hid in
                                    if let h = ApiaryCatalog.honeyType(id: hid) {
                                        HStack {
                                            Circle().fill(hex(h.color)).frame(width: 10, height: 10)
                                            Text(h.name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                            Spacer()
                                            Text("\(h.basePrice)s").font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(14)
                }
            } else { Text("Unknown buyer.") }
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Buyer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }.foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    private func hex(_ s: String) -> Color {
        var h = s; if h.hasPrefix("#") { h.removeFirst() }
        guard let v = Int(h, radix: 16) else { return ApiaryTheme.amber }
        return Color(red: Double((v>>16)&0xFF)/255.0, green: Double((v>>8)&0xFF)/255.0, blue: Double(v&0xFF)/255.0)
    }
}
