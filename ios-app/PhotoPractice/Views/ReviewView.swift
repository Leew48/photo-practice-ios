import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: PhotoPracticeStore
    @State private var selectedDate = Date()

    private var monthRecords: [ViewRecord] {
        store.records(inMonthContaining: selectedDate)
    }

    private var activeDayCount: Int {
        Set(monthRecords.map { Calendar.current.startOfDay(for: $0.viewedAt) }).count
    }

    private var favoriteInMonthCount: Int {
        monthRecords.filter { $0.favorite }.count
    }

    private var monthGrid: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: selectedDate),
              let dayRange = calendar.range(of: .day, in: .month, for: selectedDate) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlankCount = (firstWeekday + 5) % 7
        let days = dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        return Array(repeating: nil, count: leadingBlankCount) + days
    }

    var body: some View {
        NavigationStack {
            List {
                Section("日期") {
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                }

                Section("本月") {
                    HStack {
                        StatTile(label: "看图", value: "\(monthRecords.count)")
                        StatTile(label: "活跃", value: "\(activeDayCount) 天")
                        StatTile(label: "收藏", value: "\(favoriteInMonthCount)")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("本月进度") {
                    VStack(spacing: 10) {
                        HStack {
                            Text(selectedDate.formatted(.dateTime.year().month(.wide)))
                                .font(.headline)
                            Spacer()
                            Text("目标 \(store.progress.dailyTarget) 张/天")
                                .font(.caption)
                                .foregroundStyle(Color.practiceMuted)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.practiceMuted)
                                    .frame(maxWidth: .infinity)
                            }

                            ForEach(Array(monthGrid.enumerated()), id: \.offset) { _, date in
                                CalendarDayCell(
                                    date: date,
                                    count: date.map { recordCount(on: $0) } ?? 0,
                                    target: store.progress.dailyTarget,
                                    isSelected: date.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
                                )
                                .onTapGesture {
                                    if let date {
                                        selectedDate = date
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("观看记录") {
                    let records = store.records(on: selectedDate)
                    if records.isEmpty {
                        Text("这一天还没有看图记录。")
                            .foregroundStyle(Color.practiceMuted)
                    } else {
                        ForEach(records) { record in
                            RecordRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("回顾")
        }
    }

    private func recordCount(on date: Date) -> Int {
        store.records(on: date).count
    }
}

struct CalendarDayCell: View {
    let date: Date?
    let count: Int
    let target: Int
    let isSelected: Bool

    private var progressRatio: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1)
    }

    var body: some View {
        Group {
            if let date {
                VStack(spacing: 3) {
                    Text(String(Calendar.current.component(.day, from: date)))
                        .font(.caption.weight(.semibold))
                    Text(count > 0 ? "\(count)" : " ")
                        .font(.caption2)
                }
                .foregroundStyle(count > 0 ? Color.practiceForest : Color.practiceMuted)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.practiceClay : Color.clear, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
    }

    private var backgroundColor: Color {
        guard count > 0 else { return Color.white.opacity(0.72) }
        return Color.practiceForest.opacity(0.14 + progressRatio * 0.42)
    }
}

struct RecordRow: View {
    let record: ViewRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(record.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer()
                if record.favorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.practiceGold)
                }
            }
            Text("\(record.photographer.isEmpty ? "未知摄影人" : record.photographer) · \(record.viewedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(Color.practiceMuted)
            if !record.note.isEmpty {
                Text(record.note)
                    .font(.footnote)
                    .foregroundStyle(Color.practiceMuted)
            }
        }
        .padding(.vertical, 4)
    }
}
