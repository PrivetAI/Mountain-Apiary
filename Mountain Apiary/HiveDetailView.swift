import SwiftUI

struct HiveDetailView: View {
    let hiveId: UUID
    @Binding var activeSheet: ActiveSheet?
    @EnvironmentObject var store: ApiaryStore
    @Environment(\.presentationMode) var presentationMode

    @State private var pendingActions: [HiveAction] = []
    @State private var harvestCount: Int = 1
    @State private var showMergePicker: Bool = false

    var body: some View {
        Group {
            if let hive = store.state.hives.first(where: { $0.id == hiveId }) {
                content(hive: hive)
            } else {
                VStack(spacing: 10) {
                    Text("This hive is no longer in the apiary.")
                        .font(ApiaryTheme.body(14)).foregroundColor(ApiaryTheme.text)
                    Button("Close") { activeSheet = nil; presentationMode.wrappedValue.dismiss() }
                        .buttonStyle(ApiaryButtonStyle())
                }
                .padding(20)
            }
        }
        .background(ApiaryTheme.background.edgesIgnoringSafeArea(.all))
        .navigationTitle("Inspect Hive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    activeSheet = nil
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(ApiaryTheme.amber)
            }
        }
    }

    @ViewBuilder
    private func content(hive: Hive) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerCard(hive: hive)
                vitalsCard(hive: hive)
                queenCard(hive: hive)
                actionsCard(hive: hive)
                if showMergePicker {
                    mergePicker(hive: hive)
                }
                Spacer(minLength: 40)
            }
            .padding(14)
        }
    }

    private func headerCard(hive: Hive) -> some View {
        ApiaryCard {
            HStack(alignment: .top, spacing: 12) {
                HiveIcon(size: 60, roofColor: ApiaryTheme.walnut, bodyColor: ApiaryTheme.amber, bandColor: ApiaryTheme.walnut)
                VStack(alignment: .leading, spacing: 6) {
                    Text(hive.name).font(ApiaryTheme.title(20)).foregroundColor(ApiaryTheme.text)
                    HStack(spacing: 6) {
                        ApiaryPill(text: hive.race.displayName, color: ApiaryTheme.amber)
                        if hive.disease == .none {
                            ApiaryPill(text: "Healthy", color: ApiaryTheme.sage)
                        } else {
                            ApiaryPill(text: hive.disease.displayName,
                                       color: hive.disease.severity >= 3 ? ApiaryTheme.danger : ApiaryTheme.warning)
                        }
                        if hive.queenMarked {
                            ApiaryPill(text: "Q marked", color: ApiaryTheme.sage)
                        }
                    }
                    Text(hive.race.profile.blurb)
                        .font(.system(size: 11, design: .serif).italic())
                        .foregroundColor(ApiaryTheme.subtext)
                }
                Spacer()
            }
        }
    }

    private func vitalsCard(hive: Hive) -> some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Vitals").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                bar(label: "Population", value: Double(hive.population) / 80000.0, raw: "\(hive.population)", tint: ApiaryTheme.sage)
                bar(label: "Brood", value: Double(hive.brood) / 40000.0, raw: "\(hive.brood)", tint: ApiaryTheme.ember)
                bar(label: "Honey Frames", value: min(1.0, Double(hive.honeyFrames) / 16.0), raw: "\(hive.honeyFrames)", tint: ApiaryTheme.amber)
                bar(label: "Temperament", value: Double(hive.temperament) / 100.0, raw: "\(hive.temperament)/100", tint: ApiaryTheme.walnut)
                HStack(spacing: 12) {
                    statChip("Supers", "\(hive.supers)")
                    statChip("Empty Frames", "\(hive.emptyFrames)")
                    statChip("Winter Ready", hive.winterReady ? "Yes" : "No")
                }
            }
        }
    }

    private func bar(label: String, value: Double, raw: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
                Spacer()
                Text(raw).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
            }
            ApiaryProgressBar(value: value, tint: tint, height: 6)
        }
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
            Text(label).font(.system(size: 9)).foregroundColor(ApiaryTheme.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(ApiaryTheme.cream))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ApiaryTheme.border, lineWidth: 0.5))
    }

    private func queenCard(hive: Hive) -> some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("The Queen").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    Text("Age \(hive.queenAge) yr").font(.system(size: 12, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                }
                Text("An older queen lays less brood and is more prone to failure. Requeen with a fresh cell to renew her line.")
                    .font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { y in
                        Circle().fill(y <= hive.queenAge ? ApiaryTheme.amber : ApiaryTheme.walnut.opacity(0.18))
                            .frame(width: 10, height: 10)
                    }
                    Spacer()
                    if !hive.queenMarked {
                        Button(action: { store.performAction(on: hive.id, action: .markQueen) }) {
                            Text("Mark Queen").font(.system(size: 12, weight: .semibold))
                        }.buttonStyle(ApiaryGhostButtonStyle(color: ApiaryTheme.amber))
                    } else {
                        ApiaryPill(text: "Marked", color: ApiaryTheme.sage)
                    }
                }
            }
        }
    }

    private func actionsCard(hive: Hive) -> some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Inspection Actions").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                Text("Two are typical per visit; the bees will remember.")
                    .font(.system(size: 11)).foregroundColor(ApiaryTheme.subtext)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    actionButton("Requeen", subtitle: "New queen cell") {
                        store.performAction(on: hive.id, action: .requeen)
                    }
                    actionButton("Add Super", subtitle: "+1 box (uses 1 super)") {
                        store.performAction(on: hive.id, action: .addSuper)
                    }
                    actionButton("Harvest \(harvestCount) Fr.", subtitle: "Spin to jars") {
                        store.performAction(on: hive.id, action: .harvestFrames(harvestCount))
                    }
                    actionButton("Treat Disease", subtitle: "Strip / antibio") {
                        store.performAction(on: hive.id, action: .treatDisease)
                    }
                    actionButton("Feed Sugar", subtitle: "2kg sugar") {
                        store.performAction(on: hive.id, action: .feedSugar)
                    }
                    actionButton("Wrap Winter", subtitle: "Mark winter-ready") {
                        store.performAction(on: hive.id, action: .wrapWinter)
                    }
                    actionButton("Shake Bees", subtitle: "Reset brood band") {
                        store.performAction(on: hive.id, action: .shake)
                    }
                    actionButton("Mark Queen", subtitle: "Year color dot") {
                        store.performAction(on: hive.id, action: .markQueen)
                    }
                    actionButton("Split Colony", subtitle: "Need 20k bees") {
                        store.performAction(on: hive.id, action: .split)
                    }
                    actionButton("Merge Weak", subtitle: "Pick another hive") {
                        showMergePicker = true
                    }
                }
                HStack(spacing: 8) {
                    Text("Harvest count").font(.system(size: 11, weight: .semibold)).foregroundColor(ApiaryTheme.subtext)
                    Button(action: { harvestCount = max(1, harvestCount - 1) }) {
                        MinusShape(thickness: 2).path(in: CGRect(x: 0, y: 0, width: 16, height: 16))
                            .fill(ApiaryTheme.walnut).frame(width: 16, height: 16)
                    }.buttonStyle(ApiaryGhostButtonStyle())
                    Text("\(harvestCount)").font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(ApiaryTheme.text)
                    Button(action: { harvestCount = min(hive.honeyFrames > 0 ? hive.honeyFrames : 1, harvestCount + 1) }) {
                        PlusShape(thickness: 2).path(in: CGRect(x: 0, y: 0, width: 16, height: 16))
                            .fill(ApiaryTheme.walnut).frame(width: 16, height: 16)
                    }.buttonStyle(ApiaryGhostButtonStyle())
                    Spacer()
                    Text("of \(hive.honeyFrames) frames").font(.system(size: 11, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                }
            }
        }
    }

    private func actionButton(_ title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                Text(subtitle).font(.system(size: 10)).foregroundColor(ApiaryTheme.subtext)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.cream))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func mergePicker(hive: Hive) -> some View {
        ApiaryCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Merge into \(hive.name)").font(ApiaryTheme.heading(14)).foregroundColor(ApiaryTheme.text)
                    Spacer()
                    Button(action: { showMergePicker = false }) {
                        Text("Cancel").font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.amber)
                    }
                }
                ForEach(store.state.hives.filter { $0.id != hive.id }) { other in
                    Button(action: {
                        store.performAction(on: hive.id, action: .mergeWeak(other.id))
                        showMergePicker = false
                    }) {
                        HStack {
                            HiveIcon(size: 24, roofColor: ApiaryTheme.walnut, bodyColor: ApiaryTheme.amber, bandColor: ApiaryTheme.walnut)
                            VStack(alignment: .leading) {
                                Text(other.name).font(.system(size: 12, weight: .semibold)).foregroundColor(ApiaryTheme.text)
                                Text("\(other.population) bees · \(other.honeyFrames) frames")
                                    .font(.system(size: 10, design: .monospaced)).foregroundColor(ApiaryTheme.subtext)
                            }
                            Spacer()
                            ChevronRightShape().stroke(ApiaryTheme.amber, lineWidth: 2).frame(width: 8, height: 12)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(ApiaryTheme.cream))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ApiaryTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
