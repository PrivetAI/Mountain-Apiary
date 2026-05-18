import Foundation

// MARK: - Enums

enum BeeRace: String, Codable, CaseIterable {
    case carniolan, italian, russian, buckfast, caucasian

    var displayName: String {
        switch self {
        case .carniolan: return "Carniolan"
        case .italian: return "Italian"
        case .russian: return "Russian"
        case .buckfast: return "Buckfast"
        case .caucasian: return "Caucasian"
        }
    }

    /// All mechanical effects in a single tuple so they are reachable everywhere.
    /// temperament: gentleness baseline (higher = calmer)
    /// yieldMult: nectar gathering multiplier
    /// diseaseResist: 0..1 added resistance
    /// honeyRate: weekly comb construction speed
    /// broodRate: queen laying multiplier
    /// winterHardiness: survival modifier
    var profile: (temperament: Int, yieldMult: Double, diseaseResist: Double, honeyRate: Double, broodRate: Double, winterHardiness: Double, blurb: String) {
        switch self {
        case .carniolan:
            return (80, 1.05, 0.10, 1.00, 0.95, 0.18,
                    "Gentle, conserve stores in dearth, swarm-prone in spring.")
        case .italian:
            return (75, 1.15, 0.05, 1.10, 1.10, 0.05,
                    "Prolific, productive, but consume more winter stores.")
        case .russian:
            return (60, 0.95, 0.22, 0.95, 0.90, 0.20,
                    "Strong varroa resistance and hardy through cold snaps.")
        case .buckfast:
            return (78, 1.10, 0.12, 1.05, 1.00, 0.10,
                    "Balanced hybrid, calm, disease-tolerant, even yield.")
        case .caucasian:
            return (82, 1.00, 0.08, 0.95, 0.92, 0.14,
                    "Very calm with long tongues, gather from deep flowers.")
        }
    }
}

enum DiseaseState: String, Codable, CaseIterable {
    case none, mildVarroa, heavyVarroa, nosema, chalkbrood, foulbrood

    var displayName: String {
        switch self {
        case .none: return "Healthy"
        case .mildVarroa: return "Mild Varroa"
        case .heavyVarroa: return "Heavy Varroa"
        case .nosema: return "Nosema"
        case .chalkbrood: return "Chalkbrood"
        case .foulbrood: return "Foulbrood"
        }
    }

    var isContagious: Bool {
        switch self {
        case .heavyVarroa, .foulbrood: return true
        default: return false
        }
    }

    var severity: Int {
        switch self {
        case .none: return 0
        case .mildVarroa: return 1
        case .chalkbrood: return 1
        case .nosema: return 2
        case .heavyVarroa: return 3
        case .foulbrood: return 4
        }
    }
}

enum Season: String, Codable, CaseIterable {
    case spring, summer, autumn, winter
    var displayName: String { rawValue.capitalized }
    var weeks: Int {
        switch self {
        case .spring: return 10
        case .summer: return 10
        case .autumn: return 6
        case .winter: return 4
        }
    }
}

enum Weather: String, Codable, CaseIterable {
    case clear, lightRain, heavyRain, hotDrought, coldSnap, wind, mist, storm
    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .lightRain: return "Light Rain"
        case .heavyRain: return "Heavy Rain"
        case .hotDrought: return "Hot Drought"
        case .coldSnap: return "Cold Snap"
        case .wind: return "Wind"
        case .mist: return "Mist"
        case .storm: return "Storm"
        }
    }

    var forageMult: Double {
        switch self {
        case .clear: return 1.15
        case .lightRain: return 0.85
        case .heavyRain: return 0.35
        case .hotDrought: return 0.70
        case .coldSnap: return 0.50
        case .wind: return 0.80
        case .mist: return 0.90
        case .storm: return 0.20
        }
    }

    var broodMult: Double {
        switch self {
        case .clear: return 1.05
        case .lightRain: return 0.98
        case .heavyRain: return 0.85
        case .hotDrought: return 0.92
        case .coldSnap: return 0.65
        case .wind: return 0.95
        case .mist: return 1.00
        case .storm: return 0.70
        }
    }

    var swarmRisk: Double {
        switch self {
        case .clear, .mist: return 0.10
        case .hotDrought: return 0.07
        case .wind: return 0.04
        default: return 0.02
        }
    }
}

// MARK: - Hive

struct Hive: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var race: BeeRace
    var queenAge: Int        // 1..5 years
    var queenMarked: Bool
    var population: Int      // up to 80000
    var brood: Int           // 0..40000
    var honeyFrames: Int     // frames stored in this hive
    var emptyFrames: Int
    var supers: Int          // number of supers (extra boxes) added
    var disease: DiseaseState
    var temperament: Int     // 0..100 (higher = calmer)
    var winterReady: Bool
    var weeksSinceTreatment: Int
    var locked: Bool
    var slotIndex: Int       // stable per-hive integer index used as a deterministic RNG salt

    enum CodingKeys: String, CodingKey {
        case id, name, race, queenAge, queenMarked, population, brood, honeyFrames,
             emptyFrames, supers, disease, temperament, winterReady, weeksSinceTreatment,
             locked, slotIndex
    }

    init(id: UUID,
         name: String,
         race: BeeRace,
         queenAge: Int,
         queenMarked: Bool,
         population: Int,
         brood: Int,
         honeyFrames: Int,
         emptyFrames: Int,
         supers: Int,
         disease: DiseaseState,
         temperament: Int,
         winterReady: Bool,
         weeksSinceTreatment: Int,
         locked: Bool,
         slotIndex: Int = 0) {
        self.id = id
        self.name = name
        self.race = race
        self.queenAge = queenAge
        self.queenMarked = queenMarked
        self.population = population
        self.brood = brood
        self.honeyFrames = honeyFrames
        self.emptyFrames = emptyFrames
        self.supers = supers
        self.disease = disease
        self.temperament = temperament
        self.winterReady = winterReady
        self.weeksSinceTreatment = weeksSinceTreatment
        self.locked = locked
        self.slotIndex = slotIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.race = try c.decode(BeeRace.self, forKey: .race)
        self.queenAge = try c.decode(Int.self, forKey: .queenAge)
        self.queenMarked = try c.decode(Bool.self, forKey: .queenMarked)
        self.population = try c.decode(Int.self, forKey: .population)
        self.brood = try c.decode(Int.self, forKey: .brood)
        self.honeyFrames = try c.decode(Int.self, forKey: .honeyFrames)
        self.emptyFrames = try c.decode(Int.self, forKey: .emptyFrames)
        self.supers = try c.decode(Int.self, forKey: .supers)
        self.disease = try c.decode(DiseaseState.self, forKey: .disease)
        self.temperament = try c.decode(Int.self, forKey: .temperament)
        self.winterReady = try c.decode(Bool.self, forKey: .winterReady)
        self.weeksSinceTreatment = try c.decode(Int.self, forKey: .weeksSinceTreatment)
        self.locked = try c.decode(Bool.self, forKey: .locked)
        self.slotIndex = try c.decodeIfPresent(Int.self, forKey: .slotIndex) ?? 0
    }

    static func starter(index: Int, name: String, race: BeeRace) -> Hive {
        Hive(id: UUID(),
             name: name,
             race: race,
             queenAge: 1,
             queenMarked: false,
             population: 14000 + index*900,
             brood: 1200 + index*100,
             honeyFrames: 3,
             emptyFrames: 6,
             supers: 0,
             disease: .none,
             temperament: race.profile.temperament,
             winterReady: false,
             weeksSinceTreatment: 0,
             locked: false,
             slotIndex: index)
    }
}

// MARK: - Honey & Nectar

struct NectarBloom: Codable, Identifiable, Equatable {
    var id: String  // stable string id
    var name: String
    var startWeek: Int  // 1..30
    var endWeek: Int
    var rarity: Int      // 1..5
    var preferredWeather: [Weather]
    var yieldFactor: Double
    var honeyTypeId: String
    var locationAngle: Double // 0..360 around the valley for map positioning
    var locationRadius: Double // 0..1 distance
    var lore: String
}

struct HoneyType: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var basePrice: Int
    var tier: Int     // 1..5
    var color: String // hex
    var preferredBuyerIds: [String]
    var description: String
}

struct HoneyBatch: Codable, Identifiable, Equatable {
    var id: UUID
    var honeyTypeId: String
    var jars: Int
    var harvestedYear: Int
    var harvestedWeek: Int
    var hiveName: String
}

// MARK: - Buyer

struct Buyer: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var archetype: String
    var preferredHoney: [String]
    var basePriceMult: Double
    var demandMax: Int
    var blurb: String
}

// MARK: - Inventory

struct InventoryItem: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var category: String
    var price: Int
    var glyph: String   // mapped to ItemGlyphKind raw
    var description: String
}

// MARK: - Upgrade

struct Upgrade: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var cost: Int
    var requiredPrestige: Int
    var description: String
    var unlockTag: String  // semantic tag for engine logic
}

// MARK: - Event

struct EventOption: Codable, Equatable {
    var label: String
    var resultText: String
    var coinDelta: Int
    var prestigeDelta: Int
    var populationDelta: Int
    var honeyFramesDelta: Int
    var diseaseRiskDelta: Double
    var requiresItemId: String?
    var consumesItemId: String?
}

struct ApiaryEvent: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var weight: Int
    var allowedSeasons: [Season]
    var options: [EventOption]
}

// MARK: - Achievement & Quest

struct Achievement: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var unlockedYear: Int?  // nil = locked
}

struct Quest: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var goal: String
    var reward: String
    var completed: Bool
    var act: Int  // 1..3 narrative arc
}

// MARK: - Resources

struct Resources: Codable, Equatable {
    var coins: Int
    var sugarKg: Int
    var mitestrips: Int
    var antibiotics: Int
    var hornetTraps: Int
    var emptyFramesStock: Int
    var jarsStock: Int
    var supersStock: Int

    static var starter: Resources {
        Resources(coins: 240, sugarKg: 6, mitestrips: 2, antibiotics: 1, hornetTraps: 1, emptyFramesStock: 12, jarsStock: 20, supersStock: 2)
    }
}

// MARK: - Save Game

struct WeatherLogEntry: Codable, Equatable {
    var year: Int
    var week: Int
    var weather: Weather
    var dominantNectarId: String
    var totalNectarYield: Int
}

struct GameState: Codable {
    var year: Int
    var weekOfYear: Int  // 1..30
    var hives: [Hive]
    var resources: Resources
    var honeyInventory: [HoneyBatch]
    var purchasedUpgradeIds: [String]
    var soldJarsByType: [String: Int]
    var prestige: Int
    var achievements: [Achievement]
    var quests: [Quest]
    var log: [String]
    var weatherLog: [WeatherLogEntry]
    var lastEventIds: [String]   // history; capped
    var sellsThisYear: Int
    var hiveSlots: Int
    var totalSilverEarned: Int
    var firstLaunchYear: Int

    init(year: Int = 1,
         weekOfYear: Int = 1,
         hives: [Hive] = [],
         resources: Resources = .starter,
         honeyInventory: [HoneyBatch] = [],
         purchasedUpgradeIds: [String] = [],
         soldJarsByType: [String: Int] = [:],
         prestige: Int = 0,
         achievements: [Achievement] = [],
         quests: [Quest] = [],
         log: [String] = [],
         weatherLog: [WeatherLogEntry] = [],
         lastEventIds: [String] = [],
         sellsThisYear: Int = 0,
         hiveSlots: Int = 8,
         totalSilverEarned: Int = 0,
         firstLaunchYear: Int = 1) {
        self.year = year
        self.weekOfYear = weekOfYear
        self.hives = hives
        self.resources = resources
        self.honeyInventory = honeyInventory
        self.purchasedUpgradeIds = purchasedUpgradeIds
        self.soldJarsByType = soldJarsByType
        self.prestige = prestige
        self.achievements = achievements
        self.quests = quests
        self.log = log
        self.weatherLog = weatherLog
        self.lastEventIds = lastEventIds
        self.sellsThisYear = sellsThisYear
        self.hiveSlots = hiveSlots
        self.totalSilverEarned = totalSilverEarned
        self.firstLaunchYear = firstLaunchYear
    }

    // Backward-compatible decode with decodeIfPresent ?? default
    enum CodingKeys: String, CodingKey {
        case year, weekOfYear, hives, resources, honeyInventory, purchasedUpgradeIds,
             soldJarsByType, prestige, achievements, quests, log, weatherLog,
             lastEventIds, sellsThisYear, hiveSlots, totalSilverEarned, firstLaunchYear
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try c.decodeIfPresent(Int.self, forKey: .year) ?? 1
        self.weekOfYear = try c.decodeIfPresent(Int.self, forKey: .weekOfYear) ?? 1
        self.hives = try c.decodeIfPresent([Hive].self, forKey: .hives) ?? []
        self.resources = try c.decodeIfPresent(Resources.self, forKey: .resources) ?? .starter
        self.honeyInventory = try c.decodeIfPresent([HoneyBatch].self, forKey: .honeyInventory) ?? []
        self.purchasedUpgradeIds = try c.decodeIfPresent([String].self, forKey: .purchasedUpgradeIds) ?? []
        self.soldJarsByType = try c.decodeIfPresent([String: Int].self, forKey: .soldJarsByType) ?? [:]
        self.prestige = try c.decodeIfPresent(Int.self, forKey: .prestige) ?? 0
        self.achievements = try c.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        self.quests = try c.decodeIfPresent([Quest].self, forKey: .quests) ?? []
        self.log = try c.decodeIfPresent([String].self, forKey: .log) ?? []
        self.weatherLog = try c.decodeIfPresent([WeatherLogEntry].self, forKey: .weatherLog) ?? []
        self.lastEventIds = try c.decodeIfPresent([String].self, forKey: .lastEventIds) ?? []
        self.sellsThisYear = try c.decodeIfPresent(Int.self, forKey: .sellsThisYear) ?? 0
        self.hiveSlots = try c.decodeIfPresent(Int.self, forKey: .hiveSlots) ?? 8
        self.totalSilverEarned = try c.decodeIfPresent(Int.self, forKey: .totalSilverEarned) ?? 0
        self.firstLaunchYear = try c.decodeIfPresent(Int.self, forKey: .firstLaunchYear) ?? 1
        // Backfill slotIndex for older saves: if any hive has slotIndex == 0 and there are
        // duplicates (i.e. the field was missing/defaulted on legacy saves), reassign sequentially.
        let zeroSlotCount = self.hives.filter { $0.slotIndex == 0 }.count
        if zeroSlotCount > 1 {
            for i in self.hives.indices {
                self.hives[i].slotIndex = i
            }
        }
    }

    var currentSeason: Season {
        switch weekOfYear {
        case 1...10: return .spring
        case 11...20: return .summer
        case 21...26: return .autumn
        default: return .winter
        }
    }

    var weekInSeason: Int {
        switch currentSeason {
        case .spring: return weekOfYear
        case .summer: return weekOfYear - 10
        case .autumn: return weekOfYear - 20
        case .winter: return weekOfYear - 26
        }
    }
}

// MARK: - Seeded RNG (deterministic; never use String.hash)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        // SplitMix64 starting from seed
        self.state = seed &+ 0x9E3779B97F4A7C15
    }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B5
        z = (z ^ (z &>> 27)) &* 0x94D722C5BAE2D67D
        return z ^ (z &>> 31)
    }

    mutating func roll(_ range: ClosedRange<Int>) -> Int {
        return Int.random(in: range, using: &self)
    }
    mutating func chance(_ p: Double) -> Bool {
        return Double.random(in: 0..<1, using: &self) < p
    }
    mutating func pick<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[Int.random(in: 0..<array.count, using: &self)]
    }
    mutating func weighted<T>(_ items: [(T, Int)]) -> T? {
        let total = items.reduce(0) { $0 + max(0, $1.1) }
        guard total > 0 else { return items.first?.0 }
        let r = Int.random(in: 0..<total, using: &self)
        var acc = 0
        for (val, w) in items {
            acc += max(0, w)
            if r < acc { return val }
        }
        return items.last?.0
    }
}
