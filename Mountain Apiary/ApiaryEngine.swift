import Foundation

// MARK: - Engine: pure functions used by ApiaryStore
enum ApiaryEngine {

    static func weeklySeed(year: Int, week: Int) -> UInt64 {
        // year*52 + week — never use String.hash
        return UInt64(max(0, year)) &* 52 &+ UInt64(max(0, week))
    }

    static func rollWeather(year: Int, week: Int, season: Season) -> Weather {
        var rng = SeededRNG(seed: weeklySeed(year: year, week: week))
        let baseWeights: [(Weather, Int)]
        switch season {
        case .spring: baseWeights = [(.clear, 24), (.lightRain, 18), (.heavyRain, 10), (.wind, 10), (.mist, 12), (.coldSnap, 8), (.storm, 4), (.hotDrought, 2)]
        case .summer: baseWeights = [(.clear, 32), (.lightRain, 12), (.heavyRain, 8), (.wind, 8), (.mist, 6), (.coldSnap, 1), (.storm, 6), (.hotDrought, 18)]
        case .autumn: baseWeights = [(.clear, 18), (.lightRain, 18), (.heavyRain, 14), (.wind, 14), (.mist, 16), (.coldSnap, 12), (.storm, 6), (.hotDrought, 2)]
        case .winter: baseWeights = [(.clear, 16), (.lightRain, 6), (.heavyRain, 6), (.wind, 14), (.mist, 12), (.coldSnap, 28), (.storm, 12), (.hotDrought, 0)]
        }
        return rng.weighted(baseWeights) ?? .clear
    }

    static func activeBlooms(week: Int) -> [NectarBloom] {
        return ApiaryCatalog.nectarBlooms.filter { $0.startWeek <= week && week <= $0.endWeek }
    }

    static func nectarYield(weather: Weather, hive: Hive, hasUpgrade: (String) -> Bool, blooms: [NectarBloom], year: Int, week: Int) -> (frames: Int, dominantId: String) {
        if blooms.isEmpty { return (0, "") }

        // base
        let popFactor = Double(hive.population) / 12000.0
        let baseFrames = max(0.0, popFactor * weather.forageMult * hive.race.profile.yieldMult)
        // honey rate bump
        let withRate = baseFrames * hive.race.profile.honeyRate
        // bloom-weighted
        var rng = SeededRNG(seed: weeklySeed(year: year, week: week) &+ UInt64(max(0, hive.slotIndex)))
        let bloomChoice = rng.weighted(blooms.map { ($0, max(1, $0.rarity * 2)) }) ?? blooms[0]
        var frames = Int((withRate * bloomChoice.yieldFactor).rounded())
        // disease impact
        if hive.disease.severity >= 3 { frames = max(0, frames - 1) }
        if hive.disease == .foulbrood { frames = 0 }
        // supers add capacity
        let supersBonus = min(2, hive.supers)
        frames += supersBonus
        // upgrades: scale sensor and pollen trap
        if hasUpgrade("scale_sensor") { frames += 0 } // visibility only
        if frames > 0 && weather == .storm { frames = max(0, frames - 1) }
        return (max(0, min(frames, 4)), bloomChoice.honeyTypeId)
    }

    static func broodProgress(weather: Weather, hive: Hive) -> Int {
        let base = Double(hive.population) * 0.04 * hive.race.profile.broodRate * weather.broodMult
        return Int(base)
    }

    /// Disease progression decision (no side-effects)
    static func diseaseRoll(seedSalt: UInt64, hive: Hive, hasUpgrade: (String) -> Bool) -> DiseaseState {
        var rng = SeededRNG(seed: seedSalt &+ UInt64(max(0, hive.slotIndex)))
        let resistBoost = hive.race.profile.diseaseResist + (hasUpgrade("better_boxes") ? 0.08 : 0.0)
        let baseChance: Double
        switch hive.disease {
        case .none: baseChance = 0.05
        case .mildVarroa: baseChance = 0.25
        case .heavyVarroa: baseChance = 0.40
        case .chalkbrood: baseChance = 0.15
        case .nosema: baseChance = 0.18
        case .foulbrood: baseChance = 0.30
        }
        let effective = max(0.005, baseChance - resistBoost)
        guard rng.chance(effective) else { return hive.disease }

        // progression / new infection picker
        switch hive.disease {
        case .none:
            let picks: [(DiseaseState, Int)] = [(.mildVarroa, 32), (.nosema, 18), (.chalkbrood, 22), (.foulbrood, 4)]
            return rng.weighted(picks) ?? .none
        case .mildVarroa:
            return rng.chance(0.6) ? .heavyVarroa : .mildVarroa
        case .heavyVarroa:
            return .heavyVarroa // remains, additional pop loss handled elsewhere
        case .chalkbrood:
            return rng.chance(0.3) ? .none : .chalkbrood
        case .nosema:
            return rng.chance(0.4) ? .none : .nosema
        case .foulbrood:
            return .foulbrood
        }
    }

    static func updateTemperament(hive: Hive, weather: Weather) -> Int {
        var t = hive.temperament
        if weather == .storm || weather == .heavyRain { t -= 4 }
        if weather == .clear { t += 1 }
        if hive.disease == .foulbrood { t -= 5 }
        if hive.disease == .heavyVarroa { t -= 3 }
        return max(0, min(100, t))
    }

    static func computeBuyerBid(buyer: Buyer, honeyType: HoneyType, prestige: Int, week: Int, year: Int) -> Int {
        var rng = SeededRNG(seed: weeklySeed(year: year, week: week) &+ UInt64(buyer.id.unicodeScalars.first?.value ?? 1))
        let prefMult: Double = buyer.preferredHoney.contains(honeyType.id) ? 1.25 : 0.85
        let prestigeMult: Double = 1.0 + Double(prestige) * 0.012
        let jitter: Double = Double(rng.roll(85...115)) / 100.0
        let raw = Double(honeyType.basePrice) * buyer.basePriceMult * prefMult * prestigeMult * jitter
        return max(1, Int(raw.rounded()))
    }

    static func buyerWeekDemand(buyer: Buyer, week: Int, year: Int) -> Int {
        var rng = SeededRNG(seed: weeklySeed(year: year, week: week) &+ UInt64(buyer.id.count * 17))
        return rng.roll(2...max(2, buyer.demandMax / 2))
    }

    static func pickEvents(year: Int, week: Int, season: Season, recent: [String], hasUpgrade: (String) -> Bool) -> [ApiaryEvent] {
        var rng = SeededRNG(seed: weeklySeed(year: year, week: week) &+ 99173)
        let count = rng.roll(0...2)
        guard count > 0 else { return [] }
        let pool = ApiaryCatalog.events.filter { $0.allowedSeasons.contains(season) && !recent.contains($0.id) }
        guard !pool.isEmpty else { return [] }
        var result: [ApiaryEvent] = []
        var working = pool
        for _ in 0..<count {
            guard let picked = rng.weighted(working.map { ($0, $0.weight) }) else { break }
            result.append(picked)
            working.removeAll { $0.id == picked.id }
        }
        // optionally suppress some by upgrades (e.g. hornet sentinel auto-handles hornet)
        if hasUpgrade("auto_hornet") {
            result.removeAll { $0.id == "hornet" }
        }
        return result
    }
}
