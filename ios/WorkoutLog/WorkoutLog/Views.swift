import SwiftUI
import UniformTypeIdentifiers

enum TrackerTab: Hashable {
    case workout, exercises, history, settings
}

struct RootView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var tab: TrackerTab = .workout

    private var language: AppLanguage { store.data.language }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                WorkoutHomeView(selectedTab: $tab)
                    .navigationTitle(tr("训练", "Workout", language))
            }
            .tabItem { Label(tr("训练", "Workout", language), systemImage: "dumbbell.fill") }
            .tag(TrackerTab.workout)

            NavigationStack {
                ExerciseLibraryView()
                    .navigationTitle(tr("动作库", "Exercises", language))
            }
            .tabItem { Label(tr("动作", "Exercises", language), systemImage: "list.bullet.rectangle") }
            .tag(TrackerTab.exercises)

            NavigationStack {
                WorkoutHistoryView()
                    .navigationTitle(tr("历史", "History", language))
            }
            .tabItem { Label(tr("历史", "History", language), systemImage: "calendar") }
            .tag(TrackerTab.history)

            NavigationStack {
                SettingsView()
                    .navigationTitle(tr("设置", "Settings", language))
            }
            .tabItem { Label(tr("设置", "Settings", language), systemImage: "gearshape") }
            .tag(TrackerTab.settings)
        }
    }
}

struct WorkoutHomeView: View {
    @EnvironmentObject private var store: TrackerStore
    @Binding var selectedTab: TrackerTab
    @State private var editingTemplate: WorkoutTemplate?

    private var language: AppLanguage { store.data.language }

    var body: some View {
        Group {
            if store.data.activeSession != nil {
                ActiveWorkoutView(selectedTab: $selectedTab)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(tr("开始一次训练", "Start a workout", language))
                            .font(.title2.bold())
                        Button {
                            store.startWorkout()
                        } label: {
                            Label(tr("空白训练", "Blank workout", language), systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        HStack {
                            Text(tr("训练模板", "Workout templates", language))
                                .font(.headline)
                            Spacer()
                            Button {
                                editingTemplate = WorkoutTemplate(name: "")
                            } label: {
                                Label(tr("新建", "New", language), systemImage: "plus")
                            }
                        }
                        .padding(.top, 8)

                        ForEach(store.data.templates) { template in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(template.displayName(language)).font(.headline)
                                Text(template.exerciseIDs.compactMap { store.exercise($0)?.name(language) }
                                    .joined(separator: " · "))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .lineLimit(3)

                                HStack {
                                    Button(tr("开始", "Start", language)) {
                                        store.startWorkout(template: template)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button(tr("编辑", "Edit", language)) {
                                        editingTemplate = template
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                        }
                        Text(tr("动作名称可随时切换中英文。训练数据保存在这部手机上。",
                                "Exercise names switch languages anytime. Your data stays on this iPhone.",
                                language))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $editingTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template)
            }
            .environmentObject(store)
        }
    }
}

struct ActiveWorkoutView: View {
    @EnvironmentObject private var store: TrackerStore
    @Binding var selectedTab: TrackerTab
    @State private var showPicker = false
    @State private var confirmDiscard = false
    @State private var showFinishWarning = false

    private var language: AppLanguage { store.data.language }

    var body: some View {
        ScrollView {
            if let session = store.data.activeSession {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(tr("进行中的训练", "Active workout", language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField(tr("训练名称", "Workout name", language),
                                  text: Binding(
                                    get: { store.data.activeSession?.name ?? "" },
                                    set: { store.setActiveName($0) }
                                  ))
                            .font(.title2.bold())
                        Text(session.date, style: .date)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(session.entries) { entry in
                        WorkoutEntryCard(entry: entry, sessionID: nil, canRemoveExercise: true)
                    }

                    Button {
                        showPicker = true
                    } label: {
                        Label(tr("添加动作", "Add exercise", language), systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        if store.finishWorkout() {
                            selectedTab = .history
                        } else {
                            showFinishWarning = true
                        }
                    } label: {
                        Label(tr("完成训练并保存", "Finish and save workout", language),
                              systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        confirmDiscard = true
                    } label: {
                        Text(tr("放弃本次训练", "Discard this workout", language))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 16)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                ExercisePickerView { exerciseID in
                    store.addActiveExercise(exerciseID)
                }
            }
        }
        .alert(tr("确定放弃训练？", "Discard this workout?", language),
               isPresented: $confirmDiscard) {
            Button(tr("放弃", "Discard", language), role: .destructive) {
                store.discardWorkout()
            }
            Button(tr("取消", "Cancel", language), role: .cancel) {}
        } message: {
            Text(tr("未完成的训练将被删除。", "This unfinished workout will be deleted.", language))
        }
        .alert(tr("至少完成一组", "Complete at least one set", language),
               isPresented: $showFinishWarning) {
            Button("OK", role: .cancel) {}
        }
    }
}

struct WorkoutEntryCard: View {
    @EnvironmentObject private var store: TrackerStore
    let entry: WorkoutEntry
    let sessionID: UUID?
    let canRemoveExercise: Bool
    private var language: AppLanguage { store.data.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.exercise(entry.exerciseID)?.name(language) ?? "Exercise")
                        .font(.headline)
                    if let exercise = store.exercise(entry.exerciseID) {
                        Text(exercise.muscle.label(language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let last = store.lastCompletedSet(for: entry.exerciseID) {
                        Text("\(tr("上次", "Last", language)): \(last.weight.formatted()) kg × \(last.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let url = store.exercise(entry.exerciseID)?.tutorial {
                    Link(destination: url) {
                        Label(tr("教程", "Tutorial", language), systemImage: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                if canRemoveExercise {
                    Button(role: .destructive) {
                        store.removeActiveExercise(entry.id)
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .accessibilityLabel(tr("移除动作", "Remove exercise", language))
                }
            }

            HStack {
                Text(tr("组", "Set", language)).frame(width: 30, alignment: .leading)
                Text(tr("重量 kg", "Weight kg", language)).frame(maxWidth: .infinity)
                Text(tr("次数", "Reps", language)).frame(maxWidth: .infinity)
                Text("✓").frame(width: 35)
                Color.clear.frame(width: 27)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)

            ForEach(Array(entry.sets.enumerated()), id: \.element.id) { index, set in
                HStack(spacing: 7) {
                    Text("\(index + 1)")
                        .frame(width: 30, alignment: .leading)
                        .foregroundStyle(.secondary)
                    TrainingSetRow(set: set,
                                   language: language,
                                   onWeight: { store.editSet(entryID: entry.id, setID: set.id,
                                                              sessionID: sessionID, weight: $0) },
                                   onReps: { store.editSet(entryID: entry.id, setID: set.id,
                                                            sessionID: sessionID, reps: $0) },
                                   onToggle: { store.toggleSet(entryID: entry.id, setID: set.id,
                                                                sessionID: sessionID) },
                                   onDelete: { store.deleteSet(entryID: entry.id, setID: set.id,
                                                                sessionID: sessionID) })
                }
            }
            Button {
                store.addSet(entryID: entry.id, sessionID: sessionID)
            } label: {
                Label(tr("添加一组", "Add set", language), systemImage: "plus")
                    .font(.subheadline)
            }
            .padding(.top, 3)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
    }
}

struct TrainingSetRow: View {
    let set: TrainingSet
    let language: AppLanguage
    let onWeight: (Double) -> Void
    let onReps: (Int) -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var weightText: String
    @State private var repsText: String

    init(set: TrainingSet, language: AppLanguage,
         onWeight: @escaping (Double) -> Void,
         onReps: @escaping (Int) -> Void,
         onToggle: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.set = set
        self.language = language
        self.onWeight = onWeight
        self.onReps = onReps
        self.onToggle = onToggle
        self.onDelete = onDelete
        _weightText = State(initialValue: set.weight.formatted())
        _repsText = State(initialValue: String(set.reps))
    }

    var body: some View {
        TextField("kg", text: $weightText)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(tr("重量 kg", "Weight kg", language))
            .frame(maxWidth: .infinity)
            .onChange(of: weightText) { _, value in
                let normalized = value.replacingOccurrences(of: ",", with: ".")
                if let number = Double(normalized), number.isFinite, number >= 0 {
                    onWeight(number)
                }
            }

        TextField(tr("次数", "Reps", language), text: $repsText)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(tr("次数", "Reps", language))
            .frame(maxWidth: .infinity)
            .onChange(of: repsText) { _, value in
                if let number = Int(value), number >= 0 {
                    onReps(number)
                }
            }

        Button(action: onToggle) {
            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .frame(width: 35)
                .foregroundStyle(set.completed ? .green : .secondary)
        }
        .accessibilityLabel(tr("完成本组", "Complete set", language))

        Button(role: .destructive, action: onDelete) {
            Image(systemName: "minus.circle")
                .frame(width: 27)
        }
        .accessibilityLabel(tr("删除本组", "Delete set", language))
    }
}

struct ExercisePickerView: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let onSelect: (UUID) -> Void

    private var language: AppLanguage { store.data.language }

    private var results: [Exercise] {
        store.data.exercises.filter { !$0.archived && $0.matches(query) }
            .sorted { $0.name(language) < $1.name(language) }
    }

    var body: some View {
        List(results) { exercise in
            Button {
                onSelect(exercise.id)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name(language)).foregroundStyle(.primary)
                    Text("\(exercise.otherName(language)) · \(exercise.muscle.label(language))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
        }
        .searchable(text: $query, prompt: tr("中文、英文或别名", "Chinese, English or alias", language))
        .navigationTitle(tr("选择动作", "Choose exercise", language))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(tr("关闭", "Close", language)) { dismiss() }
            }
        }
    }
}

struct ExerciseLibraryView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var query = ""
    @State private var editing: Exercise?
    @State private var showArchived = false

    private var language: AppLanguage { store.data.language }
    private var results: [Exercise] {
        store.data.exercises
            .filter { (showArchived || !$0.archived) && $0.matches(query) }
            .sorted { $0.name(language) < $1.name(language) }
    }

    var body: some View {
        List {
            Toggle(tr("显示已归档动作", "Show archived exercises", language),
                   isOn: $showArchived)
                .font(.footnote)

            ForEach(results) { exercise in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(exercise.name(language)).font(.headline)
                            Text(exercise.otherName(language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(tr("编辑", "Edit", language)) {
                            editing = exercise
                        }
                        .buttonStyle(.bordered)
                    }
                    HStack {
                        Text(exercise.muscle.label(language))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        if exercise.archived {
                            Text(tr("已归档", "Archived", language))
                                .font(.caption).foregroundStyle(.orange)
                        }
                        Spacer()
                        if let url = exercise.tutorial {
                            Link(destination: url) {
                                Label(tr("教程", "Tutorial", language),
                                      systemImage: "arrow.up.right.square")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .searchable(text: $query, prompt: tr("搜索中文 / English / RDL", "Search 中文 / English / RDL", language))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = Exercise(nameEN: "", nameZH: "", muscle: .legs)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(tr("新建动作", "New exercise", language))
            }
        }
        .sheet(item: $editing) { exercise in
            NavigationStack {
                ExerciseEditorView(exercise: exercise)
            }
            .environmentObject(store)
        }
    }
}

struct ExerciseEditorView: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var working: Exercise
    @State private var showInvalid = false
    @State private var confirmArchive = false

    init(exercise: Exercise) {
        _working = State(initialValue: exercise)
    }

    private var language: AppLanguage { store.data.language }

    private var valid: Bool {
        !working.nameEN.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !working.nameZH.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (working.tutorialURL.isEmpty || working.tutorial != nil)
    }

    var body: some View {
        Form {
            Section(tr("中英文动作名称", "Bilingual exercise names", language)) {
                TextField("English", text: $working.nameEN)
                TextField("中文", text: $working.nameZH)
            }
            Section(tr("动作信息", "Details", language)) {
                Picker(tr("肌群", "Muscle group", language), selection: $working.muscle) {
                    ForEach(MuscleGroup.allCases) { group in
                        Text(group.label(language)).tag(group)
                    }
                }
                TextField(tr("别名，如 RDL", "Aliases, e.g. RDL", language),
                          text: $working.aliases)
                TextField(tr("外部教学链接 (https://)", "Tutorial URL (https://)", language),
                          text: $working.tutorialURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(tr("备注", "Notes", language), text: $working.notes, axis: .vertical)
                    .lineLimit(2...4)
            }
            if store.exercise(working.id) != nil && !working.archived {
                Section {
                    Button(tr("归档动作", "Archive exercise", language), role: .destructive) {
                        confirmArchive = true
                    }
                }
            }
        }
        .navigationTitle(tr("编辑动作", "Exercise", language))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(tr("取消", "Cancel", language)) { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(tr("保存", "Save", language)) {
                    guard valid else { showInvalid = true; return }
                    working.nameEN = working.nameEN.trimmingCharacters(in: .whitespacesAndNewlines)
                    working.nameZH = working.nameZH.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.addOrUpdateExercise(working)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!valid)
            }
        }
        .alert(tr("输入有误", "Invalid input", language), isPresented: $showInvalid) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(tr("请填写中英文名称，并使用 HTTPS 教学链接。",
                    "Both names are required; tutorial links must use HTTPS.", language))
        }
        .alert(tr("归档动作？", "Archive exercise?", language), isPresented: $confirmArchive) {
            Button(tr("归档", "Archive", language), role: .destructive) {
                store.archiveExercise(working.id)
                dismiss()
            }
            Button(tr("取消", "Cancel", language), role: .cancel) {}
        } message: {
            Text(tr("历史训练记录仍会保留。", "Historical workouts are preserved.", language))
        }
    }
}

struct TemplateEditorView: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var chineseName: String
    @State private var exerciseIDs: [UUID]
    @State private var showPicker = false
    @State private var showDelete = false
    let templateID: UUID

    init(template: WorkoutTemplate) {
        templateID = template.id
        _name = State(initialValue: template.name)
        _chineseName = State(initialValue: template.nameZH)
        _exerciseIDs = State(initialValue: template.exerciseIDs)
    }

    private var language: AppLanguage { store.data.language }

    var body: some View {
        Form {
            Section(tr("模板名称", "Template names", language)) {
                TextField("English / Name", text: $name)
                TextField(tr("中文名（可选）", "Chinese name (optional)", language),
                          text: $chineseName)
            }
            Section(tr("动作顺序", "Exercise order", language)) {
                ForEach(exerciseIDs.indices, id: \.self) { index in
                    HStack {
                        Text(store.exercise(exerciseIDs[index])?.name(language) ?? "Exercise")
                        Spacer()
                        Button {
                            guard index > 0 else { return }
                            exerciseIDs.swapAt(index, index - 1)
                        } label: { Image(systemName: "arrow.up") }
                            .disabled(index == 0)
                        Button {
                            guard index + 1 < exerciseIDs.count else { return }
                            exerciseIDs.swapAt(index, index + 1)
                        } label: { Image(systemName: "arrow.down") }
                            .disabled(index + 1 == exerciseIDs.count)
                        Button(role: .destructive) {
                            exerciseIDs.remove(at: index)
                        } label: { Image(systemName: "minus.circle") }
                    }
                }
                Button {
                    showPicker = true
                } label: {
                    Label(tr("添加动作", "Add exercise", language), systemImage: "plus")
                }
            }
            if store.data.templates.contains(where: { $0.id == templateID }) {
                Section {
                    Button(tr("删除模板", "Delete template", language), role: .destructive) {
                        showDelete = true
                    }
                }
            }
        }
        .navigationTitle(tr("训练模板", "Workout template", language))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(tr("取消", "Cancel", language)) { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(tr("保存", "Save", language)) {
                    store.saveTemplate(WorkoutTemplate(id: templateID,
                                                       name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                       nameZH: chineseName.trimmingCharacters(in: .whitespacesAndNewlines),
                                                       exerciseIDs: exerciseIDs))
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                ExercisePickerView { id in
                    if !exerciseIDs.contains(id) { exerciseIDs.append(id) }
                }
            }
        }
        .alert(tr("删除模板？", "Delete template?", language), isPresented: $showDelete) {
            Button(tr("删除", "Delete", language), role: .destructive) {
                store.deleteTemplate(templateID)
                dismiss()
            }
            Button(tr("取消", "Cancel", language), role: .cancel) {}
        } message: {
            Text(tr("已保存的训练记录不会受到影响。",
                    "Completed workouts will not be affected.", language))
        }
    }
}

struct WorkoutHistoryView: View {
    @EnvironmentObject private var store: TrackerStore
    private var language: AppLanguage { store.data.language }

    private var sorted: [WorkoutSession] {
        store.data.sessions.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        List {
            if sorted.isEmpty {
                ContentUnavailableView(
                    tr("还没有训练记录", "No workouts yet", language),
                    systemImage: "calendar",
                    description: Text(tr("完成一次训练后会显示在这里。",
                                         "Finished workouts appear here.", language))
                )
            }
            ForEach(sorted) { session in
                NavigationLink {
                    WorkoutDetailView(id: session.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.name).font(.headline)
                        Text(session.date, format: .dateTime.year().month().day())
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("\(session.entries.count) \(tr("个动作", "exercises", language))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { offsets in
                store.deleteSessions(Set(offsets.map { sorted[$0].id }))
            }
        }
    }
}

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: TrackerStore
    let id: UUID
    private var language: AppLanguage { store.data.language }

    var body: some View {
        ScrollView {
            if let session = store.completedSession(id) {
                VStack(alignment: .leading, spacing: 13) {
                    TextField(tr("训练名称", "Workout name", language),
                              text: Binding(
                                get: { store.completedSession(id)?.name ?? "" },
                                set: { store.renameSession(id, to: $0) }
                              ))
                        .font(.title2.bold())
                    Text(session.date, format: .dateTime.year().month().day())
                        .foregroundStyle(.secondary)

                    ForEach(session.entries) { entry in
                        WorkoutEntryCard(entry: entry, sessionID: id,
                                         canRemoveExercise: false)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(tr("训练记录不存在", "Workout not found", language),
                                       systemImage: "exclamationmark.circle")
            }
        }
        .navigationTitle(tr("训练详情", "Workout details", language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var contents: Data

    init(contents: Data) { self.contents = contents }

    init(configuration: ReadConfiguration) throws {
        contents = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contents)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var exportDocument: WorkoutBackupDocument?
    @State private var showExport = false
    @State private var showImport = false
    @State private var confirmImport = false
    @State private var pendingImport: Data?
    @State private var errorText = ""

    private var language: AppLanguage { store.data.language }

    var body: some View {
        Form {
            Section(tr("语言", "Language", language)) {
                Picker(tr("界面语言", "Interface language", language),
                       selection: Binding(
                        get: { store.data.language },
                        set: { store.data.language = $0 }
                       )) {
                    Text("中文").tag(AppLanguage.zh)
                    Text("English").tag(AppLanguage.en)
                }
                .pickerStyle(.segmented)
                Text(tr("切换语言不会改变任何训练数据。",
                        "Changing language never changes workout data.", language))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section(tr("备份与恢复", "Backup and restore", language)) {
                Button {
                    do {
                        exportDocument = WorkoutBackupDocument(contents: try store.exportBackup())
                        showExport = true
                    } catch {
                        errorText = error.localizedDescription
                    }
                } label: {
                    Label(tr("导出 JSON 备份", "Export JSON backup", language),
                          systemImage: "square.and.arrow.up")
                }
                Button {
                    showImport = true
                } label: {
                    Label(tr("导入 JSON 备份", "Import JSON backup", language),
                          systemImage: "square.and.arrow.down")
                }
                Text(tr("你的动作库和训练记录只保存在这部手机上，不会上传到 GitHub。换手机前请导出备份。",
                        "Your exercises and logs are stored only on this iPhone, never on GitHub. Export before switching phones.",
                        language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = store.storageError {
                Section(tr("保存错误", "Storage error", language)) {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section {
                Text("Workout Log · iOS MVP 1.0")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .fileExporter(isPresented: $showExport,
                      document: $exportDocument,
                      contentType: .json,
                      defaultFilename: "workout-backup") { result in
            if case .failure(let error) = result { errorText = error.localizedDescription }
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let granted = url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }
                pendingImport = try Data(contentsOf: url)
                confirmImport = true
            } catch {
                errorText = error.localizedDescription
            }
        }
        .confirmationDialog(tr("导入将覆盖当前全部训练数据。",
                                "Import will replace all existing workout data.", language),
                            isPresented: $confirmImport,
                            titleVisibility: .visible) {
            Button(tr("确认导入", "Replace and import", language), role: .destructive) {
                guard let data = pendingImport else { return }
                do {
                    try store.importBackup(data)
                } catch {
                    errorText = error.localizedDescription
                }
                pendingImport = nil
            }
            Button(tr("取消", "Cancel", language), role: .cancel) {
                pendingImport = nil
            }
        }
        .alert(tr("操作失败", "Something went wrong", language),
               isPresented: Binding(
                get: { !errorText.isEmpty },
                set: { if !$0 { errorText = "" } }
               )) {
            Button("OK", role: .cancel) { errorText = "" }
        } message: {
            Text(errorText)
        }
    }
}
