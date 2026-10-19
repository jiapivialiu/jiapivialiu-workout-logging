import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case zh, en
    var id: String { rawValue }
}

func tr(_ zh: String, _ en: String, _ language: AppLanguage) -> String {
    language == .zh ? zh : en
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
    var version: Int = 1
    var language: AppLanguage = .zh
    var exercises: [Exercise] = []
    var templates: [WorkoutTemplate] = []
    var sessions: [WorkoutSession] = []
    var activeSession: WorkoutSession? = nil

    static func starter() -> TrackerData {
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
            ("Hip Adduction", "髋内收", .legs, "")
        ]
        func stableID(_ index: Int) -> UUID {
            UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", index))!
        }
        let exercises = rows.enumerated().map { index, item in
            Exercise(id: stableID(index + 1), nameEN: item.0, nameZH: item.1,
                     muscle: item.2, aliases: item.3)
        }
        let templates = [
            WorkoutTemplate(id: stableID(101), name: "Lower Body", nameZH: "下肢训练",
                            exerciseIDs: [2, 1, 5, 6, 11].map(stableID)),
            WorkoutTemplate(id: stableID(102), name: "Back & Biceps", nameZH: "背部与肱二头肌",
                            exerciseIDs: [13, 14, 16, 17, 23].map(stableID)),
            WorkoutTemplate(id: stableID(103), name: "Chest & Shoulders", nameZH: "胸部与肩部",
                            exerciseIDs: [18, 19, 21, 22, 24].map(stableID)),
            WorkoutTemplate(id: stableID(104), name: "Full Body", nameZH: "全身训练",
                            exerciseIDs: [3, 1, 13, 18, 25].map(stableID))
        ]
        return TrackerData(exercises: exercises, templates: templates)
    }
}
