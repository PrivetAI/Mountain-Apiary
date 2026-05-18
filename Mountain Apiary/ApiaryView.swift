import SwiftUI

struct ApiaryView: View {
    @EnvironmentObject var store: ApiaryStore
    @Binding var activeSheet: ActiveSheet?

    var body: some View {
        ZStack {
            ApiaryTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    firstStepsHint
                    headerCard
                    valleyMap
                    advanceWeekButton
                    hivesGrid
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }

    private var firstStepsHint: some View {
        Group {
            if store.state.year == 1 && store.state.weekOfYear <= 4 && store.state.honeyInventory.isEmpty {
                ApiaryCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("First Steps").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.amber)
                            Spacer()
                        }
                        Text("Each hive already has a few honey frames. Tap any hive → Harvest to spin them into jars. Then open Market to sell.")
                            .font(ApiaryTheme.body(12)).foregroundColor(ApiaryTheme.text).fixedSize(horizontal: false, vertical: true)
                        Text("Click Advance Week to let bees forage. New emergence grows population; once a hive passes 20k bees, frames fill faster.")
                            .font(ApiaryTheme.body(11)).foregroundColor(ApiaryTheme.subtext).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Year \(store.state.year), Week \(store.state.weekOfYear)")
                            .font(ApiaryTheme.title(20))
                            .foregroundColor(ApiaryTheme.text)
                        HStack(spacing: 8) {
                            ApiaryPill(text: store.state.currentSeason.displayName, color: seasonColor(store.state.currentSeason))
                            ApiaryPill(text: "Slots \(store.state.hives.count)/\(store.state.hiveSlots)", color: ApiaryTheme.sage)
                            ApiaryPill(text: "Prestige \(store.state.prestige)", color: ApiaryTheme.ember)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            CoinIcon(size: 18)
                            Text("\(store.state.resources.coins)")
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(ApiaryTheme.walnut)
                        }
                        Text("silver")
                            .font(.system(size: 10))
                            .foregroundColor(ApiaryTheme.subtext)
                    }
                }
                HStack(spacing: 12) {
                    resourceChip(label: "Sugar", value: "\(store.state.resources.sugarKg)kg")
                    resourceChip(label: "Strips", value: "\(store.state.resources.mitestrips)")
                    resourceChip(label: "Antibio", value: "\(store.state.resources.antibiotics)")
                    resourceChip(label: "Frames", value: "\(store.state.resources.emptyFramesStock)")
                    resourceChip(label: "Jars", value: "\(store.state.resources.jarsStock)")
                }
            }
        }
    }

    private func resourceChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
            Text(label).font(.system(size: 9, weight: .regular)).foregroundColor(ApiaryTheme.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6).fill(ApiaryTheme.cream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(ApiaryTheme.border, lineWidth: 0.5)
        )
    }

    private var valleyMap: some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("The Valley")
                        .font(ApiaryTheme.heading(15)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    let blooms = ApiaryEngine.activeBlooms(week: store.state.weekOfYear)
                    ApiaryPill(text: "\(blooms.count) in bloom", color: ApiaryTheme.sage)
                }
                ValleyMapView(activeSheet: $activeSheet, week: store.state.weekOfYear)
                    .frame(height: 200)
            }
        }
    }

    private var advanceWeekButton: some View {
        Button(action: { store.advanceWeek() }) {
            HStack {
                Text("Advance Week").font(.system(size: 15, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Text("\(store.state.weekOfYear) → \(min(store.state.weekOfYear + 1, 30))")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    ChevronRightShape().stroke(Color.white, lineWidth: 2).frame(width: 8, height: 12)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [ApiaryTheme.amber, ApiaryTheme.ember],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    private var hivesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Hives").font(ApiaryTheme.heading(15)).foregroundColor(ApiaryTheme.text)
                Spacer()
                if store.state.hives.count < store.state.hiveSlots {
                    Button(action: { store.addHiveSlot() }) {
                        HStack(spacing: 4) {
                            PlusShape(thickness: 2).path(in: CGRect(x: 0, y: 0, width: 10, height: 10))
                                .fill(ApiaryTheme.amber)
                                .frame(width: 10, height: 10)
                            Text("Add Hive").font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(ApiaryGhostButtonStyle(color: ApiaryTheme.amber))
                }
            }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(store.state.hives) { hive in
                    HiveTile(hive: hive)
                        .onTapGesture { activeSheet = .hiveDetail(hive.id) }
                }
                ForEach(0..<max(0, store.state.hiveSlots - store.state.hives.count), id: \.self) { i in
                    EmptySlotTile(slotIndex: store.state.hives.count + i + 1)
                }
            }
        }
    }

    private func seasonColor(_ s: Season) -> Color {
        switch s {
        case .spring: return ApiaryTheme.sage
        case .summer: return ApiaryTheme.amber
        case .autumn: return ApiaryTheme.ember
        case .winter: return Color(red: 90/255, green: 110/255, blue: 130/255)
        }
    }
}

struct HiveTile: View {
    let hive: Hive
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                HiveIcon(size: 50, roofColor: ApiaryTheme.walnut, bodyColor: ApiaryTheme.amber, bandColor: ApiaryTheme.walnut)
                Spacer()
                if hive.disease != .none {
                    ApiaryPill(text: shortDisease(hive.disease), color: hive.disease.severity >= 3 ? ApiaryTheme.danger : ApiaryTheme.warning)
                }
            }
            Text(hive.name).font(.system(size: 13, weight: .semibold)).foregroundColor(ApiaryTheme.text).lineLimit(1)
            Text(hive.race.displayName).font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
            // Population
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Pop").font(.system(size: 10, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
                    Spacer()
                    Text("\(hive.population)").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
                }
                ApiaryProgressBar(value: Double(hive.population) / 80000.0, tint: ApiaryTheme.sage, height: 4)
            }
            // Honey
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Frames").font(.system(size: 10, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
                    Spacer()
                    Text("\(hive.honeyFrames)").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
                }
                ApiaryProgressBar(value: min(1.0, Double(hive.honeyFrames) / 16.0), tint: ApiaryTheme.amber, height: 4)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(ApiaryTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(ApiaryTheme.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func shortDisease(_ d: DiseaseState) -> String {
        switch d {
        case .none: return "OK"
        case .mildVarroa: return "Mite-1"
        case .heavyVarroa: return "Mite-3"
        case .nosema: return "Nos"
        case .chalkbrood: return "Chalk"
        case .foulbrood: return "Foul"
        }
    }
}

struct EmptySlotTile: View {
    let slotIndex: Int
    var body: some View {
        VStack(spacing: 8) {
            PlusShape(thickness: 3).path(in: CGRect(x: 0, y: 0, width: 28, height: 28))
                .fill(ApiaryTheme.walnut.opacity(0.4))
                .frame(width: 28, height: 28)
            Text("Slot \(slotIndex)").font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
            Text("Empty stand").font(.system(size: 10)).foregroundColor(ApiaryTheme.subtext.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundColor(ApiaryTheme.border)
        )
    }
}

// MARK: - Valley Map (abstract)

struct ValleyMapView: View {
    @Binding var activeSheet: ActiveSheet?
    let week: Int

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [ApiaryTheme.cream, ApiaryTheme.sand.opacity(0.7), ApiaryTheme.sage.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Mountains in background
                ZStack {
                    MountainShape().fill(ApiaryTheme.walnut.opacity(0.18))
                        .frame(width: screenSize.width * 0.45, height: screenSize.height * 0.55)
                        .offset(x: -screenSize.width * 0.18, y: -screenSize.height * 0.10)
                    MountainShape().fill(ApiaryTheme.walnut.opacity(0.25))
                        .frame(width: screenSize.width * 0.6, height: screenSize.height * 0.75)
                        .offset(x: 0, y: -screenSize.height * 0.08)
                    MountainShape().fill(ApiaryTheme.walnut.opacity(0.20))
                        .frame(width: screenSize.width * 0.5, height: screenSize.height * 0.6)
                        .offset(x: screenSize.width * 0.20, y: -screenSize.height * 0.10)
                }
                // River
                Path { p in
                    p.move(to: CGPoint(x: 0, y: screenSize.height * 0.75))
                    p.addCurve(to: CGPoint(x: screenSize.width, y: screenSize.height * 0.85),
                               control1: CGPoint(x: screenSize.width * 0.3, y: screenSize.height * 0.55),
                               control2: CGPoint(x: screenSize.width * 0.7, y: screenSize.height * 0.95))
                }.stroke(ApiaryTheme.sage.opacity(0.6), lineWidth: 4)

                // Center apiary marker
                HiveIcon(size: 30, roofColor: ApiaryTheme.walnut, bodyColor: ApiaryTheme.amber, bandColor: ApiaryTheme.walnut)
                    .position(x: screenSize.width / 2, y: screenSize.height * 0.7)

                // Nectar sources around the valley
                ForEach(ApiaryCatalog.nectarBlooms) { bloom in
                    let active = bloom.startWeek <= week && week <= bloom.endWeek
                    let angle = bloom.locationAngle * .pi / 180.0
                    let r = bloom.locationRadius
                    let cx = screenSize.width / 2 + CGFloat(cos(angle)) * (screenSize.width * 0.4 * CGFloat(r))
                    let cy = screenSize.height * 0.55 + CGFloat(sin(angle)) * (screenSize.height * 0.40 * CGFloat(r))
                    Button(action: { activeSheet = .nectar(bloom.id) }) {
                        NectarMarker(size: active ? 18 : 12,
                                     color: active ? bloomColor(bloom) : ApiaryTheme.walnut.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .position(x: max(8, min(cx, screenSize.width - 8)),
                              y: max(8, min(cy, screenSize.height - 8)))
                }
            }
            .frame(width: screenSize.width, height: screenSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1)
            )
        }
    }

    private func bloomColor(_ b: NectarBloom) -> Color {
        switch b.rarity {
        case 5: return ApiaryTheme.ember
        case 4: return ApiaryTheme.amber
        case 3: return ApiaryTheme.sage
        case 2: return ApiaryTheme.sage.opacity(0.85)
        default: return Color(red: 160/255, green: 130/255, blue: 70/255)
        }
    }
}

// MARK: - Week summary sheet
struct WeekSummarySheet: View {
    @EnvironmentObject var store: ApiaryStore
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Week's Yield").font(ApiaryTheme.title(18)).foregroundColor(ApiaryTheme.text)
                Spacer()
                Button(action: onClose) {
                    Text("Done").font(.system(size: 14, weight: .semibold)).foregroundColor(ApiaryTheme.amber)
                }
            }
            if let s = store.weekSummary {
                ApiaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            weatherIcon(s.weather, size: 30)
                            VStack(alignment: .leading) {
                                Text(s.weather.displayName).font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                                Text("Forage modifier x\(String(format: "%.2f", s.weather.forageMult))")
                                    .font(ApiaryTheme.body(11)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                        }
                        Divider()
                        ApiaryStatRow(label: "Total frames produced", value: "\(s.totalFrames)", tint: ApiaryTheme.amber)
                        if let ht = ApiaryCatalog.honeyType(id: s.dominantHoneyId) {
                            ApiaryStatRow(label: "Dominant nectar", value: ht.name, tint: ApiaryTheme.text)
                        }
                    }
                }
                if !s.notes.isEmpty {
                    ApiaryCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(ApiaryTheme.heading(13)).foregroundColor(ApiaryTheme.text)
                            ForEach(s.notes, id: \.self) { note in
                                HStack(alignment: .top, spacing: 6) {
                                    HexShape().fill(ApiaryTheme.amber).frame(width: 8, height: 8).padding(.top, 5)
                                    Text(note).font(ApiaryTheme.body(13)).foregroundColor(ApiaryTheme.text)
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}

struct YearSummarySheet: View {
    @EnvironmentObject var store: ApiaryStore
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("A Year Closes").font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                Spacer()
                Button("Continue", action: onClose)
                    .buttonStyle(ApiaryButtonStyle())
            }
            if let y = store.yearSummary {
                ApiaryCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Year \(y.yearJustEnded)").font(ApiaryTheme.title(28)).foregroundColor(ApiaryTheme.amber)
                        Divider()
                        ApiaryStatRow(label: "Jars sold", value: "\(y.jarsSold)")
                        ApiaryStatRow(label: "Silver earned (total)", value: "\(y.silverEarned)")
                        ApiaryStatRow(label: "Prestige carried", value: "\(y.prestigeGained)", tint: ApiaryTheme.ember)
                        ApiaryStatRow(label: "Overwintered", value: "\(y.overwintered) of \(y.totalHives)", tint: ApiaryTheme.sage)
                    }
                }
                Text("The new year begins with the snowmelt. May your queens lay strong.")
                    .font(.system(size: 13, design: .serif).italic())
                    .foregroundColor(ApiaryTheme.subtext)
            }
            Spacer()
        }
        .padding(16)
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}

@ViewBuilder
func weatherIcon(_ w: Weather, size: CGFloat) -> some View {
    switch w {
    case .clear: SunIcon(size: size, color: ApiaryTheme.amber)
    case .lightRain: RainIcon(size: size, color: ApiaryTheme.sage)
    case .heavyRain: RainIcon(size: size, color: ApiaryTheme.sage)
    case .hotDrought: SunIcon(size: size, color: ApiaryTheme.ember)
    case .coldSnap: SnowIcon(size: size, color: ApiaryTheme.walnut)
    case .wind: WindIcon(size: size)
    case .mist: MistIcon(size: size)
    case .storm: StormIcon(size: size)
    }
}
