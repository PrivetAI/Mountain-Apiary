import Foundation
import SwiftUI

final class ApiaryStore: ObservableObject {

    static let saveKey = "ma.state.v1"

    @Published var state: GameState
    @Published var pendingEvents: [ApiaryEvent] = []
    @Published var weekSummary: WeekSummary? = nil
    @Published var yearSummary: YearSummary? = nil

    struct WeekSummary: Identifiable {
        let id = UUID()
        let weather: Weather
        let totalFrames: Int
        let dominantHoneyId: String
        let notes: [String]
    }

    struct YearSummary: Identifiable {
        let id = UUID()
        let yearJustEnded: Int
        let jarsSold: Int
        let silverEarned: Int
        let prestigeGained: Int
        let overwintered: Int
        let totalHives: Int
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            self.state = decoded
        } else {
            // Fresh start
            var s = GameState()
            s.hives = ApiaryCatalog.starterHives()
            s.achievements = ApiaryCatalog.starterAchievements()
            s.quests = ApiaryCatalog.starterQuests()
            self.state = s
            log("Welcome — inspect a hive, harvest its frames into jars, then sell at the Market.")
            log("Tap Advance Week when ready. Bees grow population first; honey follows.")
        }
        ensureCatalogConsistency()
    }

    private func ensureCatalogConsistency() {
        // Top up achievements/quests with any catalog ones missing from save
        let achievementIds = Set(state.achievements.map { $0.id })
        for a in ApiaryCatalog.starterAchievements() where !achievementIds.contains(a.id) {
            state.achievements.append(a)
        }
        let questIds = Set(state.quests.map { $0.id })
        for q in ApiaryCatalog.starterQuests() where !questIds.contains(q.id) {
            state.quests.append(q)
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    func resetGame() {
        UserDefaults.standard.removeObject(forKey: Self.saveKey)
        UserDefaults.standard.removeObject(forKey: "ma.buyer_history")
        var s = GameState()
        s.hives = ApiaryCatalog.starterHives()
        s.achievements = ApiaryCatalog.starterAchievements()
        s.quests = ApiaryCatalog.starterQuests()
        self.state = s
        self.pendingEvents = []
        log("The valley is reset. A new keeper begins.")
        save()
    }

    func log(_ message: String) {
        let stamp = "Y\(state.year)·W\(state.weekOfYear)"
        state.log.insert("\(stamp): \(message)", at: 0)
        if state.log.count > 80 { state.log = Array(state.log.prefix(80)) }
    }

    func hasUpgrade(_ id: String) -> Bool {
        state.purchasedUpgradeIds.contains(id)
    }

    // MARK: - Advance Week

    func advanceWeek() {
        let weather = ApiaryEngine.rollWeather(year: state.year, week: state.weekOfYear, season: state.currentSeason)
        let blooms = ApiaryEngine.activeBlooms(week: state.weekOfYear)

        var totalFrames = 0
        var honeyTally: [String: Int] = [:]
        var notes: [String] = []
        var totalEmergence = 0
        var totalAttrition = 0
        let seedSalt = ApiaryEngine.weeklySeed(year: state.year, week: state.weekOfYear)

        for i in state.hives.indices {
            var hive = state.hives[i]

            // brood progress
            let broodDelta = ApiaryEngine.broodProgress(weather: weather, hive: hive)
            hive.brood = min(40000, max(0, hive.brood + broodDelta / 6))
            // population aging
            let emergence = hive.brood / 8
            hive.population = min(80000, hive.population + emergence)
            hive.brood = max(0, hive.brood - emergence)
            totalEmergence += emergence
            // attrition
            let attrition = max(50, hive.population / 28)
            hive.population = max(0, hive.population - attrition)
            totalAttrition += attrition
            // honey production
            let yieldResult = ApiaryEngine.nectarYield(weather: weather, hive: hive, hasUpgrade: hasUpgrade, blooms: blooms, year: state.year, week: state.weekOfYear)
            hive.honeyFrames += yieldResult.frames
            totalFrames += yieldResult.frames
            if !yieldResult.dominantId.isEmpty {
                honeyTally[yieldResult.dominantId, default: 0] += yieldResult.frames
            }
            // weather penalties
            if weather == .heavyRain || weather == .storm {
                hive.population = max(0, hive.population - 200)
            }
            if weather == .coldSnap && state.currentSeason != .summer {
                hive.brood = max(0, hive.brood - 100)
            }
            // disease tick
            let newDisease = ApiaryEngine.diseaseRoll(seedSalt: seedSalt, hive: hive, hasUpgrade: hasUpgrade)
            if newDisease != hive.disease {
                if newDisease == .none {
                    notes.append("\(hive.name) cleared its infection.")
                } else {
                    notes.append("\(hive.name) shows \(newDisease.displayName).")
                }
                hive.disease = newDisease
            }
            hive.weeksSinceTreatment += 1
            // disease casualties
            if hive.disease == .foulbrood {
                hive.population = max(0, hive.population - 1500)
            } else if hive.disease == .heavyVarroa {
                hive.population = max(0, hive.population - 700)
            } else if hive.disease == .nosema {
                hive.population = max(0, hive.population - 400)
            }
            // temperament
            hive.temperament = ApiaryEngine.updateTemperament(hive: hive, weather: weather)
            // queen aging during spring tick
            if state.weekOfYear == 1 { hive.queenAge = min(5, hive.queenAge + 1) }

            // Winter survival
            if state.currentSeason == .winter {
                let consumption = max(1, hive.population / 9000 + 1)
                let needed = consumption
                if hive.honeyFrames >= needed {
                    hive.honeyFrames -= needed
                } else {
                    let shortfall = needed - hive.honeyFrames
                    hive.honeyFrames = 0
                    if state.resources.sugarKg >= shortfall*2 {
                        state.resources.sugarKg -= shortfall*2
                        notes.append("\(hive.name) was sugar-fed (\(shortfall*2) kg).")
                    } else {
                        let loss = 4000 * shortfall
                        hive.population = max(0, hive.population - loss)
                        notes.append("\(hive.name) starved — lost \(loss) bees.")
                    }
                }
                // race winter hardiness
                let surv = 1.0 - (0.06 - hive.race.profile.winterHardiness)
                hive.population = Int(Double(hive.population) * max(0.85, min(1.0, surv)))
            }
            state.hives[i] = hive
        }

        // Disease spread
        let contagiousNames = state.hives.filter { $0.disease.isContagious }.map { $0.name }
        if !contagiousNames.isEmpty {
            for i in state.hives.indices {
                guard state.hives[i].disease == .none else { continue }
                var rng = SeededRNG(seed: seedSalt &+ UInt64(max(0, state.hives[i].slotIndex)) &+ 991)
                let spreadChance = hasUpgrade("better_boxes") ? 0.05 : 0.12
                if rng.chance(spreadChance) {
                    state.hives[i].disease = .mildVarroa
                    notes.append("\(state.hives[i].name) caught varroa from a neighbor.")
                }
            }
        }

        // Pollen trap upgrade weekly tick
        if hasUpgrade("pollen_gen") {
            // give pollen sub via inventory pseudo — we don't track individually as items here, so add coin equivalent
            state.resources.coins += 2
        }
        // Queen-rearing station: produce a queen cell-like resource as silver discount
        if hasUpgrade("queen_rearing") && state.weekOfYear % 4 == 0 {
            state.resources.coins += 5
            notes.append("Queen-rearing station yielded a cell.")
        }

        // Dominant honey
        let dominantId = honeyTally.max(by: { $0.value < $1.value })?.key ?? "honey_wildflower"

        state.weatherLog.append(WeatherLogEntry(year: state.year, week: state.weekOfYear, weather: weather, dominantNectarId: dominantId, totalNectarYield: totalFrames))
        if state.weatherLog.count > 120 { state.weatherLog = Array(state.weatherLog.suffix(120)) }

        // Roll events
        let events = ApiaryEngine.pickEvents(year: state.year, week: state.weekOfYear,
                                             season: state.currentSeason,
                                             recent: state.lastEventIds,
                                             hasUpgrade: hasUpgrade)
        self.pendingEvents = events
        for e in events {
            state.lastEventIds.append(e.id)
        }
        if state.lastEventIds.count > 12 { state.lastEventIds = Array(state.lastEventIds.suffix(12)) }

        // Colony bee-tracker note prepended so players can see week-to-week deltas
        let netPop = totalEmergence - totalAttrition
        let popSign = netPop >= 0 ? "+" : ""
        notes.insert("Colony grew by \(popSign)\(netPop) bees (\(totalEmergence) emerged, \(totalAttrition) lost).", at: 0)

        // Hint when bees foraged but no frame was filled
        if totalFrames == 0 && !blooms.isEmpty && notes.count <= 1 {
            notes.append("Bees foraged but stores didn't fill a frame — give them more weeks to build.")
        }
        // Note when no blooms in season
        if blooms.isEmpty {
            notes.append("No blooms in season this week. Bees rest on the comb.")
        }

        // Build summary
        self.weekSummary = WeekSummary(weather: weather, totalFrames: totalFrames, dominantHoneyId: dominantId, notes: notes)

        // Advance week
        state.weekOfYear += 1
        if state.weekOfYear > 30 {
            advanceYear()
        }

        // Quests passive checks (population, prestige, etc.)
        checkQuests()
        checkAchievements()
        log("Week advanced. Weather: \(weather.displayName). Forage frames: \(totalFrames).")
        save()
    }

    func advanceYear() {
        // tally year summary
        let overwintered = state.hives.filter { $0.population > 4000 }.count
        let summary = YearSummary(
            yearJustEnded: state.year,
            jarsSold: state.sellsThisYear,
            silverEarned: state.totalSilverEarned,
            prestigeGained: state.prestige,
            overwintered: overwintered,
            totalHives: state.hives.count
        )
        self.yearSummary = summary
        state.year += 1
        state.weekOfYear = 1
        state.sellsThisYear = 0
        // small prestige carry over: keep all prestige
        log("Year \(state.year - 1) ended. \(overwintered) hives overwintered.")
        // achievement: season_full
        unlock("season_full")
        if state.year >= 3 { unlock("survivor_three") }
        if overwintered == state.hives.count && !state.hives.isEmpty { unlock("survivor_one") }
        completeQuestIfPossible(id: "q06")
        completeQuestIfPossible(id: "q11")
        completeQuestIfPossible(id: "q18")
        if state.year >= 6 { completeQuestIfPossible(id: "q30") }
    }

    // MARK: - Hive actions

    func performAction(on hiveId: UUID, action: HiveAction) {
        guard let idx = state.hives.firstIndex(where: { $0.id == hiveId }) else { return }
        var hive = state.hives[idx]
        switch action {
        case .requeen:
            hive.queenAge = 1
            hive.brood = max(hive.brood, 1500)
            hive.temperament = min(100, hive.temperament + 8)
            log("Requeened \(hive.name).")
            unlock("queen_rearer")
        case .addSuper:
            if state.resources.supersStock > 0 {
                state.resources.supersStock -= 1
                hive.supers += 1
                log("Added a super to \(hive.name).")
            } else {
                log("No supers in stock.")
            }
        case .harvestFrames(let n):
            let harvested = min(n, hive.honeyFrames)
            hive.honeyFrames -= harvested
            unlock("first_harvest")
            // Convert frames to jars via dominant nectar this week
            let dominantId = mostRecentDominantHoneyId() ?? "honey_wildflower"
            let extractorBonus = hasUpgrade("extractor_master") ? 2 : (hasUpgrade("extractor_pro") ? 1 : 0)
            let baseJars = harvested * 4
            let jars = baseJars + harvested * extractorBonus
            if jars > 0 {
                state.honeyInventory.append(HoneyBatch(id: UUID(), honeyTypeId: dominantId, jars: jars, harvestedYear: state.year, harvestedWeek: state.weekOfYear, hiveName: hive.name))
                log("Harvested \(harvested) frames from \(hive.name) → \(jars) jars of \(ApiaryCatalog.honeyType(id: dominantId)?.name ?? "Honey").")
                completeQuestIfPossible(id: "q01")
            }
        case .treatDisease:
            if hive.disease == .heavyVarroa || hive.disease == .mildVarroa {
                if state.resources.mitestrips > 0 {
                    let wasHeavy = hive.disease == .heavyVarroa
                    state.resources.mitestrips -= 1
                    hive.disease = .none
                    hive.weeksSinceTreatment = 0
                    log("Treated \(hive.name) with mite strip.")
                    if wasHeavy { unlock("varroa_crusher") }
                } else { log("No mite strips."); }
            } else if hive.disease == .foulbrood || hive.disease == .nosema {
                if state.resources.antibiotics > 0 {
                    state.resources.antibiotics -= 1
                    let wasFoul = hive.disease == .foulbrood
                    hive.disease = .none
                    hive.weeksSinceTreatment = 0
                    log("Treated \(hive.name) with antibiotic.")
                    if wasFoul { unlock("foulbrood_save") }
                    completeQuestIfPossible(id: "q13")
                } else { log("No antibiotics."); }
            } else if hive.disease == .chalkbrood {
                hive.disease = .none
                log("\(hive.name) cleared chalkbrood with ventilation.")
            } else {
                log("\(hive.name) needs no treatment.")
            }
        case .feedSugar:
            if state.resources.sugarKg >= 2 {
                state.resources.sugarKg -= 2
                hive.population = min(80000, hive.population + 500)
                log("Fed \(hive.name) sugar syrup.")
            } else { log("Not enough sugar."); }
        case .wrapWinter:
            hive.winterReady = true
            log("Wrapped \(hive.name) for winter.")
        case .shake:
            hive.brood = max(0, hive.brood - 300)
            hive.population = max(0, hive.population - 200)
            log("Shook bees off frames in \(hive.name).")
        case .markQueen:
            hive.queenMarked = true
            log("Marked queen in \(hive.name).")
            completeQuestIfPossible(id: "q04")
        case .split:
            if state.hives.count < state.hiveSlots && hive.population > 20000 {
                hive.population -= 8000
                let newName = "Split of \(hive.name)"
                let nextSlot = (state.hives.map { $0.slotIndex }.max() ?? (state.hives.count - 1)) + 1
                let newHive = Hive(id: UUID(),
                                   name: newName,
                                   race: hive.race,
                                   queenAge: 1,
                                   queenMarked: false,
                                   population: 8000,
                                   brood: 500,
                                   honeyFrames: 0,
                                   emptyFrames: 5,
                                   supers: 0,
                                   disease: .none,
                                   temperament: hive.race.profile.temperament,
                                   winterReady: false,
                                   weeksSinceTreatment: 0,
                                   locked: false,
                                   slotIndex: nextSlot)
                state.hives.append(newHive)
                log("Split \(hive.name) into a new colony.")
            } else {
                log("Cannot split: insufficient population or slots.")
            }
        case .mergeWeak(let otherId):
            if let oi = state.hives.firstIndex(where: { $0.id == otherId }), oi != idx {
                let other = state.hives[oi]
                hive.population += other.population
                hive.honeyFrames += other.honeyFrames
                state.hives.remove(at: oi)
                log("Merged \(other.name) into \(hive.name).")
            }
        }
        if let idx2 = state.hives.firstIndex(where: { $0.id == hiveId }) {
            state.hives[idx2] = hive
        }
        save()
    }

    func mostRecentDominantHoneyId() -> String? {
        return state.weatherLog.last?.dominantNectarId
    }

    // MARK: - Market

    func sell(batchId: UUID, jarCount: Int, to buyer: Buyer, bid: Int) {
        guard let bi = state.honeyInventory.firstIndex(where: { $0.id == batchId }) else { return }
        var batch = state.honeyInventory[bi]
        let toSell = min(jarCount, batch.jars)
        guard toSell > 0 else { return }
        let total = bid * toSell
        state.resources.coins += total
        state.totalSilverEarned += total
        state.sellsThisYear += toSell
        state.soldJarsByType[batch.honeyTypeId, default: 0] += toSell
        batch.jars -= toSell
        if batch.jars <= 0 {
            state.honeyInventory.remove(at: bi)
        } else {
            state.honeyInventory[bi] = batch
        }
        log("Sold \(toSell) jars of \(ApiaryCatalog.honeyType(id: batch.honeyTypeId)?.name ?? "honey") to \(buyer.name) for \(total) silver.")
        unlock("first_jar")
        completeQuestIfPossible(id: "q02")
        // Per-honey achievement
        unlockHoneyAchievement(honeyId: batch.honeyTypeId)
        // Record buyer for per-buyer achievement tracking
        recordBuyerSale(buyer.id)
        // Per-buyer achievement (all twelve)
        if Set(soldBuyerIds()).count >= ApiaryCatalog.buyers.count {
            unlock("twelve_buyers")
            completeQuestIfPossible(id: "q28")
        }
        // total jars
        let totalSold = state.soldJarsByType.values.reduce(0, +)
        if totalSold >= 100 {
            unlock("hundred_jars")
            completeQuestIfPossible(id: "q27")
        }
        if totalSold >= 30 && batch.honeyTypeId == "honey_clover" { unlock("clover_master") }
        // quest-specific buyer hooks
        if buyer.id == "bakery" { completeQuestIfPossible(id: "q08") }
        if buyer.id == "court" { completeQuestIfPossible(id: "q14") }
        if buyer.id == "cafe" {
            let toCafe = state.soldJarsByType.values.reduce(0, +) // simple proxy
            if toCafe >= 5 { completeQuestIfPossible(id: "q15") }
        }
        if buyer.id == "folk" { completeQuestIfPossible(id: "q21") }
        if buyer.id == "apothecary" { completeQuestIfPossible(id: "q22") }
        if buyer.id == "foreign" { completeQuestIfPossible(id: "q23") }
        if batch.honeyTypeId == "honey_buckwheat" { completeQuestIfPossible(id: "q16") }
        if batch.honeyTypeId == "honey_manuka" { completeQuestIfPossible(id: "q24") }
        if batch.honeyTypeId == "honey_forest" { completeQuestIfPossible(id: "q25") }
        if state.prestige >= 10 { unlock("prestige_ten") }
        if state.prestige >= 20 { unlock("prestige_twenty"); completeQuestIfPossible(id: "q26") }
        if hasUpgrade("shrine") && toSell >= 4 {
            state.prestige += 1
        }
        // Stockpile check for q05 / q12
        let totalJars = state.honeyInventory.reduce(0) { $0 + $1.jars }
        if totalJars >= 10 { completeQuestIfPossible(id: "q05") }
        if totalJars >= 40 { completeQuestIfPossible(id: "q12") }

        save()
    }

    func soldBuyerIds() -> [String] {
        // We do not track per-buyer separately to keep state lean,
        // but we use sellsThisYear+log to infer; we'll keep a derived set in UserDefaults for completeness.
        let key = "ma.buyer_history"
        let existing = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
        return existing
    }

    func recordBuyerSale(_ buyerId: String) {
        let key = "ma.buyer_history"
        var existing = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
        if !existing.contains(buyerId) { existing.append(buyerId) }
        UserDefaults.standard.set(existing, forKey: key)
    }

    private func unlockHoneyAchievement(honeyId: String) {
        let map: [String: String] = [
            "honey_clover": "clover_master",
            "honey_heather": "heather_master",
            "honey_linden": "linden_master",
            "honey_rapeseed": "rapeseed_master",
            "honey_acacia": "acacia_master",
            "honey_buckwheat": "buckwheat_master",
            "honey_sage": "sage_master",
            "honey_lavender": "lavender_master",
            "honey_sunflower": "sunflower_master",
            "honey_wildflower": "wildflower_master",
            "honey_orchard": "orchard_master",
            "honey_cherry": "cherry_master",
            "honey_forest": "forest_master",
            "honey_thyme": "thyme_master",
            "honey_eucalyptus": "eucalyptus_master",
            "honey_manuka": "manuka_master",
            "honey_borage": "borage_master",
            "honey_goldenrod": "goldenrod_master",
        ]
        if let id = map[honeyId] { unlock(id) }
    }

    // MARK: - Resources / Buying

    func buyResource(itemId: String) {
        guard let item = ApiaryCatalog.item(id: itemId) else { return }
        guard state.resources.coins >= item.price else { log("Not enough silver."); return }
        state.resources.coins -= item.price
        switch item.id {
        case "empty_frame", "foundation": state.resources.emptyFramesStock += 1
        case "super": state.resources.supersStock += 1
        case "sugar": state.resources.sugarKg += 4
        case "mite_strip": state.resources.mitestrips += 1
        case "antibiotic": state.resources.antibiotics += 1
        case "hornet_trap": state.resources.hornetTraps += 1
        case "jar": state.resources.jarsStock += 5
        case "smoker", "tool", "suit", "extractor", "tank", "label", "marker", "refractometer", "hive_scale", "fire_cover", "winter_wrap", "queen_cell", "pollen_sub", "excluder":
            // semi-symbolic: register one-off use
            log("Acquired \(item.name).")
            if item.id == "smoker" { completeQuestIfPossible(id: "q09") }
        default:
            break
        }
        save()
    }

    func buyUpgrade(_ upgrade: Upgrade) {
        guard !hasUpgrade(upgrade.id) else { return }
        guard state.resources.coins >= upgrade.cost else { log("Not enough silver for \(upgrade.name)."); return }
        guard state.prestige >= upgrade.requiredPrestige else { log("Need \(upgrade.requiredPrestige) prestige."); return }
        state.resources.coins -= upgrade.cost
        state.purchasedUpgradeIds.append(upgrade.id)
        // Apply slot bumps immediately
        switch upgrade.unlockTag {
        case "slot+1": state.hiveSlots += 1
        case "slot+2": state.hiveSlots += 2
        case "slot+3": state.hiveSlots += 3
        case "slot+5": state.hiveSlots += 5
        default: break
        }
        log("Purchased upgrade: \(upgrade.name).")
        if state.hiveSlots >= 10 { completeQuestIfPossible(id: "q19") }
        if state.hiveSlots >= 12 { unlock("apiary_grown") }
        if state.hiveSlots >= 20 { unlock("apiary_grand"); completeQuestIfPossible(id: "q29") }
        if upgrade.id == "almanac" { completeQuestIfPossible(id: "q17") }
        save()
    }

    func addHiveSlot() {
        if state.hives.count < state.hiveSlots {
            let n = state.hives.count + 1
            let names = ["New Stand", "Quiet Stand", "Hilltop", "Riverbank", "Glade", "Northwood",
                         "Southwood", "Sunset", "Twin Pines", "Quiet Brook", "Far Stand", "Bell Stand"]
            let name = names[(n-1) % names.count] + " \(n)"
            let race = BeeRace.allCases.randomElement() ?? .italian
            let nextSlot = (state.hives.map { $0.slotIndex }.max() ?? (n - 2)) + 1
            var hive = Hive.starter(index: n, name: name, race: race)
            hive.slotIndex = nextSlot
            state.hives.append(hive)
            log("Established a new hive: \(name).")
            save()
        }
    }

    // MARK: - Events resolution

    func resolveEvent(_ event: ApiaryEvent, option: EventOption) {
        // requires/consumes
        if let req = option.requiresItemId {
            // shorthand: requires implies the player must have it
            switch req {
            case "queen_cell": if state.resources.coins < 0 { log("Need a queen cell."); return }
            case "mite_strip": if state.resources.mitestrips < 1 { log("Need a mite strip."); return }
            case "antibiotic": if state.resources.antibiotics < 1 { log("Need an antibiotic."); return }
            case "hornet_trap": if state.resources.hornetTraps < 1 { log("Need a hornet trap."); return }
            case "fire_cover", "winter_wrap":
                // these are consumed but tracked as one-offs; allow it but consume coins symbolically
                break
            default: break
            }
        }
        if let cons = option.consumesItemId {
            switch cons {
            case "mite_strip": state.resources.mitestrips = max(0, state.resources.mitestrips - 1)
            case "antibiotic": state.resources.antibiotics = max(0, state.resources.antibiotics - 1)
            case "hornet_trap": state.resources.hornetTraps = max(0, state.resources.hornetTraps - 1)
            default: break
            }
        }
        state.resources.coins = max(0, state.resources.coins + option.coinDelta)
        if option.coinDelta > 0 { state.totalSilverEarned += option.coinDelta }
        state.prestige = max(0, state.prestige + option.prestigeDelta)
        // population spread
        if option.populationDelta != 0 && !state.hives.isEmpty {
            let per = option.populationDelta / state.hives.count
            for i in state.hives.indices {
                state.hives[i].population = max(0, state.hives[i].population + per)
            }
        }
        // honey frames spread
        if option.honeyFramesDelta != 0 && !state.hives.isEmpty {
            let per = option.honeyFramesDelta / max(1, state.hives.count)
            for i in state.hives.indices {
                state.hives[i].honeyFrames = max(0, state.hives[i].honeyFrames + per)
            }
        }
        // disease risk
        if option.diseaseRiskDelta < 0 {
            // chance to cure something mild
            for i in state.hives.indices {
                if state.hives[i].disease == .mildVarroa || state.hives[i].disease == .chalkbrood {
                    if Double.random(in: 0..<1) < -option.diseaseRiskDelta {
                        state.hives[i].disease = .none
                    }
                }
            }
        } else if option.diseaseRiskDelta > 0 {
            for i in state.hives.indices {
                if state.hives[i].disease == .none {
                    if Double.random(in: 0..<1) < option.diseaseRiskDelta {
                        state.hives[i].disease = .mildVarroa
                    }
                }
            }
        }
        log("\(event.title): \(option.resultText)")
        pendingEvents.removeAll { $0.id == event.id }
        save()
    }

    // MARK: - Achievement / Quest helpers

    func unlock(_ id: String) {
        if let idx = state.achievements.firstIndex(where: { $0.id == id }) {
            if state.achievements[idx].unlockedYear == nil {
                state.achievements[idx].unlockedYear = state.year
                log("Achievement: \(state.achievements[idx].name).")
            }
        }
    }

    func completeQuestIfPossible(id: String) {
        if let idx = state.quests.firstIndex(where: { $0.id == id }) {
            if !state.quests[idx].completed {
                state.quests[idx].completed = true
                log("Quest complete: \(state.quests[idx].name).")
                applyQuestReward(state.quests[idx])
            }
        }
    }

    private func applyQuestReward(_ q: Quest) {
        let lower = q.reward.lowercased()
        // simple parser for "+N silver" and "+N prestige"
        let silverMatches = matches(in: lower, pattern: #"(\+)?(\d+)\s+silver"#)
        if let s = silverMatches.first, let n = Int(s) {
            state.resources.coins += n
            state.totalSilverEarned += n
        }
        let prestigeMatches = matches(in: lower, pattern: #"(\+)?(\d+)\s+prestige"#)
        if let p = prestigeMatches.first, let n = Int(p) {
            state.prestige += n
        }
        if lower.contains("mite strip") {
            state.resources.mitestrips += 1
        }
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let results = re.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return results.compactMap { match -> String? in
            guard match.numberOfRanges >= 3 else { return nil }
            let r = match.range(at: 2)
            if r.location == NSNotFound { return nil }
            return ns.substring(with: r)
        }
    }

    private func checkQuests() {
        // Healthy apiary streak (q03) approximated: if all hives currently healthy and prestige >= 1, mark
        if state.hives.allSatisfy({ $0.disease == .none }) && state.weekOfYear >= 4 {
            completeQuestIfPossible(id: "q03")
        }
        if state.hives.filter({ $0.disease == .none }).count >= 8 {
            completeQuestIfPossible(id: "q10")
        }
        if state.weekOfYear >= 11 {
            completeQuestIfPossible(id: "q07")
        }
        if state.weatherLog.contains(where: { entry in
            entry.year == state.year && entry.week == 30
        }) && !state.hives.isEmpty {
            completeQuestIfPossible(id: "q20")
        }
    }

    private func checkAchievements() {
        if state.prestige >= 10 { unlock("prestige_ten") }
        if state.prestige >= 20 { unlock("prestige_twenty") }
        if state.hiveSlots >= 12 { unlock("apiary_grown") }
        if state.hiveSlots >= 20 { unlock("apiary_grand") }
        if state.year >= 3 { unlock("survivor_three") }
    }
}

enum HiveAction {
    case requeen
    case addSuper
    case harvestFrames(Int)
    case treatDisease
    case feedSugar
    case wrapWinter
    case shake
    case markQueen
    case split
    case mergeWeak(UUID)
}
