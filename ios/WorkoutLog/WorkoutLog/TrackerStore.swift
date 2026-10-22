import Foundation
import Combine

@MainActor
final class TrackerStore: ObservableObject {
    @Published var data: TrackerData {
        didSet { persist() }
    }
    @Published var storageError: String?

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("workout-data.json")
        if let saved = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(TrackerData.self, from: saved),
           (1...TrackerData.currentVersion).contains(decoded.version) {
            data = decoded.migratedToCurrentVersion()
        } else {
            data = .starter()
        }
        persist()
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(data).write(to: fileURL, options: .atomic)
            storageError = nil
        } catch {
            storageError = error.localizedDescription
        }
    }

    func exercise(_ id: UUID) -> Exercise? {
        data.exercises.first(where: { $0.id == id })
    }

    func addOrUpdateExercise(_ exercise: Exercise) {
        if let index = data.exercises.firstIndex(where: { $0.id == exercise.id }) {
            data.exercises[index] = exercise
        } else {
            data.exercises.append(exercise)
        }
    }

    func archiveExercise(_ id: UUID) {
        guard let index = data.exercises.firstIndex(where: { $0.id == id }) else { return }
        data.exercises[index].archived = true
    }

    func saveTemplate(_ template: WorkoutTemplate) {
        if let index = data.templates.firstIndex(where: { $0.id == template.id }) {
            data.templates[index] = template
        } else {
            data.templates.append(template)
        }
    }

    func deleteTemplate(_ id: UUID) {
        data.templates.removeAll { $0.id == id }
    }

    func lastCompletedSet(for exerciseID: UUID) -> TrainingSet? {
        for session in data.sessions.sorted(by: { $0.date > $1.date }) {
            for entry in session.entries.reversed() where entry.exerciseID == exerciseID {
                if let found = entry.sets.last(where: { $0.completed }) {
                    return found
                }
            }
        }
        return nil
    }

    private func initialSet(for exerciseID: UUID) -> TrainingSet {
        guard let previous = lastCompletedSet(for: exerciseID) else { return TrainingSet() }
        return TrainingSet(weight: previous.weight, reps: previous.reps)
    }

    func startWorkout(template: WorkoutTemplate? = nil) {
        guard data.activeSession == nil else { return }
        let ids = template?.exerciseIDs ?? []
        let entries = ids.map { WorkoutEntry(exerciseID: $0, sets: [initialSet(for: $0)]) }
        data.activeSession = WorkoutSession(
            name: template?.displayName(data.language) ?? tr("自定义训练", "Custom workout", data.language),
            entries: entries
        )
    }

    func setActiveName(_ name: String) {
        guard var session = data.activeSession else { return }
        session.name = name
        data.activeSession = session
    }

    func setActiveNotes(_ notes: String) {
        guard var session = data.activeSession else { return }
        session.notes = notes
        data.activeSession = session
    }

    private func modifySession(_ sessionID: UUID?, action: (inout WorkoutSession) -> Void) {
        if let sessionID {
            guard let index = data.sessions.firstIndex(where: { $0.id == sessionID }) else { return }
            var session = data.sessions[index]
            action(&session)
            data.sessions[index] = session
        } else {
            guard var session = data.activeSession else { return }
            action(&session)
            data.activeSession = session
        }
    }

    func setWorkoutStart(_ start: Date, sessionID: UUID? = nil) {
        modifySession(sessionID) { session in
            let change = start.timeIntervalSince(session.date)
            session.date = start
            if let end = session.finishedAt {
                session.finishedAt = end.addingTimeInterval(change)
            }
        }
    }

    func setWorkoutEnd(_ end: Date?, sessionID: UUID? = nil) {
        modifySession(sessionID) { session in
            guard var end else {
                session.finishedAt = nil
                return
            }
            if end < session.date,
               let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: end) {
                end = nextDay
            }
            session.finishedAt = end
        }
    }

    func addActiveExercise(_ id: UUID) {
        guard var session = data.activeSession else { return }
        session.entries.append(WorkoutEntry(exerciseID: id, sets: [initialSet(for: id)]))
        data.activeSession = session
    }

    func addExercise(_ exerciseID: UUID, toCompletedSession sessionID: UUID) {
        let initialSet = initialSet(for: exerciseID)
        modifySession(sessionID) { session in
            session.entries.append(WorkoutEntry(exerciseID: exerciseID, sets: [initialSet]))
        }
    }

    func removeActiveExercise(_ id: UUID) {
        guard var session = data.activeSession else { return }
        session.entries.removeAll { $0.id == id }
        data.activeSession = session
    }

    func moveWorkoutEntry(_ entryID: UUID, by offset: Int, sessionID: UUID? = nil) {
        guard offset != 0 else { return }
        modifySession(sessionID) { session in
            guard let source = session.entries.firstIndex(where: { $0.id == entryID }) else { return }
            let destination = source + offset
            guard session.entries.indices.contains(destination) else { return }
            session.entries.swapAt(source, destination)
        }
    }

    private func modifyEntry(
        _ id: UUID,
        sessionID: UUID?,
        action: (inout WorkoutEntry) -> Void
    ) {
        if let sessionID {
            guard let si = data.sessions.firstIndex(where: { $0.id == sessionID }),
                  let ei = data.sessions[si].entries.firstIndex(where: { $0.id == id }) else { return }
            var session = data.sessions[si]
            action(&session.entries[ei])
            data.sessions[si] = session
        } else {
            guard var session = data.activeSession,
                  let ei = session.entries.firstIndex(where: { $0.id == id }) else { return }
            action(&session.entries[ei])
            data.activeSession = session
        }
    }

    func addSet(entryID: UUID, sessionID: UUID? = nil) {
        modifyEntry(entryID, sessionID: sessionID) { entry in
            let previous = entry.sets.last
            entry.sets.append(TrainingSet(weight: previous?.weight ?? 0,
                                          reps: previous?.reps ?? 10))
        }
    }

    func editSet(entryID: UUID, setID: UUID, sessionID: UUID? = nil,
                 weight: Double? = nil, reps: Int? = nil) {
        modifyEntry(entryID, sessionID: sessionID) { entry in
            guard let i = entry.sets.firstIndex(where: { $0.id == setID }) else { return }
            if let weight, weight.isFinite, weight >= 0 {
                entry.sets[i].weight = weight
            }
            if let reps, reps >= 0 {
                entry.sets[i].reps = reps
            }
        }
    }

    func toggleSet(entryID: UUID, setID: UUID, sessionID: UUID? = nil) {
        modifyEntry(entryID, sessionID: sessionID) { entry in
            guard let i = entry.sets.firstIndex(where: { $0.id == setID }) else { return }
            entry.sets[i].completed.toggle()
        }
    }

    func deleteSet(entryID: UUID, setID: UUID, sessionID: UUID? = nil) {
        modifyEntry(entryID, sessionID: sessionID) { entry in
            entry.sets.removeAll { $0.id == setID }
        }
    }

    @discardableResult
    func finishWorkout() -> Bool {
        guard var session = data.activeSession,
              session.entries.contains(where: { entry in entry.sets.contains(where: { $0.completed }) })
        else { return false }
        if session.finishedAt == nil {
            session.finishedAt = max(Date(), session.date)
        }
        if session.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            session.name = tr("训练记录", "Workout", data.language)
        }
        data.sessions.append(session)
        data.activeSession = nil
        return true
    }

    func discardWorkout() {
        data.activeSession = nil
    }

    func completedSession(_ id: UUID) -> WorkoutSession? {
        data.sessions.first(where: { $0.id == id })
    }

    func renameSession(_ id: UUID, to name: String) {
        guard let i = data.sessions.firstIndex(where: { $0.id == id }) else { return }
        data.sessions[i].name = name
    }

    func setSessionNotes(_ id: UUID, to notes: String) {
        guard let i = data.sessions.firstIndex(where: { $0.id == id }) else { return }
        data.sessions[i].notes = notes
    }

    func deleteSessions(_ ids: Set<UUID>) {
        data.sessions.removeAll { ids.contains($0.id) }
    }

    func exportBackup() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }

    func importBackup(_ backup: Data) throws {
        let decoded = try JSONDecoder().decode(TrackerData.self, from: backup)
        let exerciseIDs = Set(decoded.exercises.map(\.id))
        let sessions = decoded.sessions + [decoded.activeSession].compactMap { $0 }
        let sessionIDs = Set(sessions.map(\.id))

        let exercisesAreValid = !decoded.exercises.isEmpty
            && exerciseIDs.count == decoded.exercises.count
            && decoded.exercises.allSatisfy { exercise in
                !exercise.nameEN.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !exercise.nameZH.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && (exercise.tutorialURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || exercise.tutorial != nil)
            }
        let templatesAreValid = decoded.templates.allSatisfy { template in
            !template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && template.exerciseIDs.allSatisfy(exerciseIDs.contains)
        }
        let sessionsAreValid = sessionIDs.count == sessions.count
            && sessions.allSatisfy { session in
                Set(session.entries.map(\.id)).count == session.entries.count
                    && session.entries.allSatisfy { entry in
                        exerciseIDs.contains(entry.exerciseID)
                            && Set(entry.sets.map(\.id)).count == entry.sets.count
                            && entry.sets.allSatisfy {
                                $0.weight.isFinite && $0.weight >= 0 && $0.reps >= 0
                            }
                    }
            }
        let templateIDsAreUnique = Set(decoded.templates.map(\.id)).count == decoded.templates.count

        guard (1...TrackerData.currentVersion).contains(decoded.version),
              exercisesAreValid,
              templateIDsAreUnique,
              templatesAreValid,
              sessionsAreValid else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = decoded.migratedToCurrentVersion()
    }
}
