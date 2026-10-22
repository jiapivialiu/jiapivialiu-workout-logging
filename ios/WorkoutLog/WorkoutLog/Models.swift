import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case zh, en
    var id: String { rawValue }
}

func tr(_ zh: String, _ en: String, _ language: AppLanguage) -> String {
    language == .zh ? zh : en
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"

    private static let poundsPerKilogram = 2.2046226218

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch self {
        case .pounds:
            return tr("磅 (lb)", "Pounds (lb)", language)
        case .kilograms:
            return tr("公斤 (kg)", "Kilograms (kg)", language)
        }
    }

    func displayValue(kilograms: Double) -> Double {
        switch self {
        case .pounds:
            return kilograms * Self.poundsPerKilogram
        case .kilograms:
            return kilograms
        }
    }

    func kilograms(from displayValue: Double) -> Double {
        switch self {
        case .pounds:
            return displayValue / Self.poundsPerKilogram
        case .kilograms:
            return displayValue
        }
    }
}

func formattedWeight(_ kilograms: Double, unit: WeightUnit) -> String {
    unit.displayValue(kilograms: kilograms)
        .formatted(.number.precision(.fractionLength(0...2)))
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case legs, glutes, hamstrings, back, chest, shoulders, biceps, triceps, core, calves

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        let names: [MuscleGroup: (String, String)] = [
            .legs: ("腿部", "Legs"),
            .glutes: ("臀部", "Glutes"),
            .hamstrings: ("腿后侧", "Hamstrings"),
            .back: ("背部", "Back"),
            .chest: ("胸部", "Chest"),
            .shoulders: ("肩部", "Shoulders"),
            .biceps: ("肱二头肌", "Biceps"),
            .triceps: ("肱三头肌", "Triceps"),
            .core: ("核心", "Core"),
            .calves: ("小腿", "Calves")
        ]
        let pair = names[self] ?? (rawValue, rawValue)
        return tr(pair.0, pair.1, language)
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nameEN: String
    var nameZH: String
    var muscle: MuscleGroup
    var aliases: String = ""
    var tutorialURL: String = ""
    var notes: String = ""
    var archived: Bool = false

    func name(_ language: AppLanguage) -> String {
        tr(nameZH, nameEN, language)
    }

    func otherName(_ language: AppLanguage) -> String {
        tr(nameEN, nameZH, language)
    }

    var tutorial: URL? {
        guard let url = URL(string: tutorialURL),
              url.scheme?.lowercased() == "https",
              url.host != nil else { return nil }
        return url
    }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty || nameEN.localizedStandardContains(q)
            || nameZH.localizedStandardContains(q)
            || aliases.localizedStandardContains(q)
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var nameZH: String = ""
    var exerciseIDs: [UUID] = []

    func displayName(_ language: AppLanguage) -> String {
        language == .zh && !nameZH.isEmpty ? nameZH : name
    }
}

struct TrainingSet: Identifiable, Codable {
    var id: UUID = UUID()
    // Store a canonical kilogram value; the UI converts to the selected display unit.
    var weight: Double = 0
    var reps: Int = 10
    var completed: Bool = false
}

struct WorkoutEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var exerciseID: UUID
    var sets: [TrainingSet] = []
}

struct WorkoutSession: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date = Date()
    var finishedAt: Date? = nil
    var entries: [WorkoutEntry] = []
    var notes: String = ""
}

struct TrackerData: Codable {
    static let currentVersion = 3

    var version: Int = currentVersion
    var language: AppLanguage = .zh
    var weightUnit: WeightUnit = .pounds
    var exercises: [Exercise] = []
    var templates: [WorkoutTemplate] = []
    var sessions: [WorkoutSession] = []
    var activeSession: WorkoutSession? = nil

    init(version: Int = currentVersion,
         language: AppLanguage = .zh,
         weightUnit: WeightUnit = .pounds,
         exercises: [Exercise] = [],
         templates: [WorkoutTemplate] = [],
         sessions: [WorkoutSession] = [],
         activeSession: WorkoutSession? = nil) {
        self.version = version
        self.language = language
        self.weightUnit = weightUnit
        self.exercises = exercises
        self.templates = templates
        self.sessions = sessions
        self.activeSession = activeSession
    }

    private enum CodingKeys: String, CodingKey {
        case version, language, weightUnit, exercises, templates, sessions, activeSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        language = try container.decode(AppLanguage.self, forKey: .language)
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .pounds
        exercises = try container.decode([Exercise].self, forKey: .exercises)
        templates = try container.decode([WorkoutTemplate].self, forKey: .templates)
        sessions = try container.decode([WorkoutSession].self, forKey: .sessions)
        activeSession = try container.decodeIfPresent(WorkoutSession.self, forKey: .activeSession)
    }

    private static func stableID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", index))!
    }

    static var builtInExercises: [Exercise] {
        let rows: [(String, String, MuscleGroup, String)] = [
            ("Romanian Deadlift", "罗马尼亚硬拉", .hamstrings, "RDL"),
            ("Barbell Hip Thrust", "杠铃臀推", .glutes, "臀推"),
            ("Barbell Back Squat", "杠铃深蹲", .legs, "Squat"),
            ("Goblet Squat", "高脚杯深蹲", .legs, ""),
            ("Bulgarian Split Squat", "保加利亚分腿蹲", .legs, "BSS"),
            ("Leg Press", "腿举", .legs, ""),
            ("Leg Extension", "腿屈伸", .legs, ""),
            ("Leg Curl", "腿弯举", .hamstrings, ""),
            ("Walking Lunge", "行走弓步", .legs, ""),
            ("Cable Glute Kickback", "绳索后踢", .glutes, ""),
            ("Hip Abduction", "髋外展", .glutes, ""),
            ("Glute Bridge", "臀桥", .glutes, ""),
            ("Lat Pulldown", "高位下拉", .back, ""),
            ("Seated Cable Row", "坐姿绳索划船", .back, ""),
            ("Assisted Pull-up", "辅助引体向上", .back, ""),
            ("One-arm Dumbbell Row", "单臂哑铃划船", .back, ""),
            ("Face Pull", "面拉", .shoulders, ""),
            ("Barbell Bench Press", "杠铃卧推", .chest, "Bench Press"),
            ("Incline Dumbbell Press", "上斜哑铃卧推", .chest, ""),
            ("Push-up", "俯卧撑", .chest, ""),
            ("Dumbbell Shoulder Press", "哑铃肩推", .shoulders, ""),
            ("Lateral Raise", "侧平举", .shoulders, ""),
            ("Biceps Curl", "肱二头肌弯举", .biceps, ""),
            ("Triceps Pushdown", "绳索三头下压", .triceps, ""),
            ("Plank", "平板支撑", .core, ""),
            ("Dead Bug", "死虫式", .core, ""),
            ("Sumo Deadlift", "相扑硬拉", .glutes, ""),
            ("Dumbbell Chest Fly", "哑铃飞鸟", .chest, ""),
            ("Hammer Curl", "锤式弯举", .biceps, ""),
            ("Hanging Leg Raise", "悬垂举腿", .core, ""),
            ("Standing Calf Raise", "站姿提踵", .calves, ""),
            ("Back Extension", "背部挺身", .back, ""),
            ("Dumbbell RDL", "哑铃罗马尼亚硬拉", .hamstrings, ""),
            ("Overhead Press", "杠铃肩推", .shoulders, "OHP"),
            ("Hip Adduction", "髋内收", .legs, ""),
            ("Knee-to-Wall Ankle Mobilization", "跪墙脚踝活动", .calves, "Ankle Rock, 脚踝前移"),
            ("Single-Leg Spanish Squat", "单腿西班牙蹲", .legs, "Spanish Squat, 西班牙蹲"),
            ("Scapular Push-Up", "肩胛俯卧撑", .shoulders, "Push-up Plus, Serratus Push-up"),
            ("Bird Dog", "鸟狗式", .core, "Quadruped Bird Dog"),
            ("Marching Glute Bridge", "行进式臀桥", .glutes, "Bridge March"),
            ("Pallof Press", "Pallof 抗旋转推", .core, "Anti-Rotation Press, 抗旋转"),
            ("Side Plank", "侧平板支撑", .core, ""),
            ("Low Step-Up", "低台阶上步", .legs, "Step Up"),
            ("Bear Plank Shoulder Tap", "熊式支撑肩触", .core, "Bear Shoulder Tap"),
            ("Half-Kneeling Single-Arm Cable Press (Front-Facing)", "半跪姿单臂绳索推（正面）", .chest, "Half-Kneeling Cable Press"),
            ("Bulgarian Split Squat (Hip Internal-Rotation Bias)", "保加利亚分腿蹲（髋内旋侧重）", .legs, "BSS Internal Rotation"),
            ("Bulgarian Split Squat (Hip External-Rotation Bias)", "保加利亚分腿蹲（髋外旋侧重）", .glutes, "BSS External Rotation"),
            ("Cable Single-Leg Romanian Deadlift (Front-Facing)", "龙门架单腿罗马尼亚硬拉（正面）", .hamstrings, "Cable Single-Leg RDL Front Facing"),
            ("Cable Single-Leg Romanian Deadlift (Side-Facing)", "龙门架单侧罗马尼亚硬拉（侧面）", .glutes, "Cable Single-Leg RDL Side Facing"),
            ("Barbell Deadlift", "杠铃硬拉", .hamstrings, "Deadlift, Conventional Deadlift")
        ]
        return rows.enumerated().map { index, item in
            Exercise(id: stableID(index + 1), nameEN: item.0, nameZH: item.1,
                     muscle: item.2, aliases: item.3)
        }
    }

    func migratedToCurrentVersion() -> TrackerData {
        var merged = self
        if version < 2 {
            let primaryMuscleCorrections: [String: MuscleGroup] = [
                "平板撑": .core,
                "单腿（瑜伽球靠墙）罗马尼亚硬拉": .glutes,
                "杠铃硬拉": .hamstrings,
                "杠铃直腿硬拉": .hamstrings,
                "龙门架单腿罗马尼亚硬拉（正面）": .hamstrings,
                "龙门架单侧罗马尼亚硬拉（侧面）": .glutes
            ]
            for index in merged.exercises.indices {
                let chineseName = merged.exercises[index].nameZH
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let muscle = primaryMuscleCorrections[chineseName] {
                    merged.exercises[index].muscle = muscle
                }
            }
        }

        var existingIDs = Set(exercises.map(\.id))
        var existingEnglishNames = Set(exercises.map {
            $0.nameEN.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })
        var existingChineseNames = Set(exercises.map {
            $0.nameZH.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })

        for exercise in Self.builtInExercises {
            let englishName = exercise.nameEN.lowercased()
            let chineseName = exercise.nameZH.lowercased()
            guard !existingIDs.contains(exercise.id),
                  !existingEnglishNames.contains(englishName),
                  !existingChineseNames.contains(chineseName) else { continue }
            merged.exercises.append(exercise)
            existingIDs.insert(exercise.id)
            existingEnglishNames.insert(englishName)
            existingChineseNames.insert(chineseName)
        }

        if version < 3 {
            let newFullBodyTemplateIDs = Set([105, 106, 107].map(Self.stableID))
            let existingTemplateIDs = Set(merged.templates.map(\.id))
            let existingEnglishNames = Set(merged.templates.map {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            })
            let existingChineseNames = Set(merged.templates.map {
                $0.nameZH.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            })
            let missingTemplates = Self.builtInTemplates(resolving: merged.exercises).filter {
                newFullBodyTemplateIDs.contains($0.id)
                    && !existingTemplateIDs.contains($0.id)
                    && !existingEnglishNames.contains($0.name.lowercased())
                    && !existingChineseNames.contains($0.nameZH.lowercased())
            }
            merged.templates.append(contentsOf: missingTemplates)
        }
        merged.version = Self.currentVersion
        return merged
    }

    private static func builtInTemplates(resolving exercises: [Exercise]) -> [WorkoutTemplate] {
        func exerciseID(_ index: Int) -> UUID {
            let seed = builtInExercises[index - 1]
            if exercises.contains(where: { $0.id == seed.id }) {
                return seed.id
            }
            return exercises.first(where: {
                $0.nameEN.caseInsensitiveCompare(seed.nameEN) == .orderedSame
                    || $0.nameZH == seed.nameZH
            })?.id ?? seed.id
        }

        return [
            WorkoutTemplate(id: stableID(101), name: "Lower Body", nameZH: "下肢训练",
                            exerciseIDs: [2, 1, 5, 6, 11].map(exerciseID)),
            WorkoutTemplate(id: stableID(102), name: "Back & Biceps", nameZH: "背部与肱二头肌",
                            exerciseIDs: [13, 14, 16, 17, 23].map(exerciseID)),
            WorkoutTemplate(id: stableID(103), name: "Chest & Shoulders", nameZH: "胸部与肩部",
                            exerciseIDs: [18, 19, 21, 22, 24].map(exerciseID)),
            WorkoutTemplate(id: stableID(104), name: "Full Body", nameZH: "全身训练",
                            exerciseIDs: [3, 1, 13, 18, 25].map(exerciseID)),
            WorkoutTemplate(id: stableID(105),
                            name: "Full Body A · Squat + Bench",
                            nameZH: "全身 A · 深蹲与卧推",
                            exerciseIDs: [36, 37, 12, 26, 38, 3, 18, 14, 48, 41, 43].map(exerciseID)),
            WorkoutTemplate(id: stableID(106),
                            name: "Full Body B · Deadlift + Vertical Push/Pull",
                            nameZH: "全身 B · 硬拉与垂直推拉",
                            exerciseIDs: [40, 39, 26, 38, 50, 34, 15, 47, 16, 42].map(exerciseID)),
            WorkoutTemplate(id: stableID(107),
                            name: "Full Body C · Unilateral Control",
                            nameZH: "全身 C · 单边控制",
                            exerciseIDs: [36, 40, 44, 20, 39, 4, 19, 16, 9, 45, 49].map(exerciseID))
        ]
    }

    static func starter() -> TrackerData {
        let exercises = builtInExercises
        let templates = builtInTemplates(resolving: exercises)
        return TrackerData(exercises: exercises, templates: templates)
    }
}
