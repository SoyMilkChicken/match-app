// JournalView.swift
// Matcha

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrinkLog.loggedAt, order: .reverse) private var allLogs: [DrinkLog]
    @Query(filter: #Predicate<Sticker> { $0.ownedCount > 0 }) private var unlockedStickers: [Sticker]
    
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var showAddDrink = false
    @State private var rewardedSticker: Sticker?
    @State private var showStickerReveal = false
    
    private var calendar: Calendar { Calendar.current }
    
    /// Filter logs for selected date
    private var selectedDayLogs: [DrinkLog] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return allLogs.filter { $0.loggedAt >= startOfDay && $0.loggedAt < endOfDay }
    }
    
    private var selectedDayCalories: Int {
        selectedDayLogs.reduce(0) { $0 + $1.calories }
    }
    
    private var selectedDayCaffeine: Int {
        selectedDayLogs.reduce(0) { $0 + $1.caffeineMg }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }
    
    /// Map of date -> sticker ID from logs
    private var dateToStickerMap: [Date: UUID] {
        var map: [Date: UUID] = [:]
        for log in allLogs {
            let day = calendar.startOfDay(for: log.loggedAt)
            if let stickerID = log.rewardedStickerID, map[day] == nil {
                map[day] = stickerID
            }
        }
        return map
    }
    
    /// Set of dates that have any logs
    private var datesWithLogs: Set<Date> {
        Set(allLogs.map { calendar.startOfDay(for: $0.loggedAt) })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Top: Compact Stats Card
                        compactStatsCard
                        
                        // Jump to Today (if not today)
                        if !isToday {
                            jumpToTodayButton
                        }
                        
                        // Middle: Big Calendar (main focus)
                        MonthCalendarView(
                            displayedMonth: $displayedMonth,
                            selectedDate: $selectedDate,
                            datesWithLogs: datesWithLogs,
                            dateToStickerMap: dateToStickerMap,
                            allStickers: unlockedStickers
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Bottom: Pinned Add Drink Button
                addDrinkButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.matchaSurface)
            }
            .background(Color.matchaSurface)
            .navigationTitle(navigationTitle)
            .sheet(isPresented: $showAddDrink) {
                AddDrinkSheet(onDrinkLogged: { sticker in
                    if let sticker {
                        rewardedSticker = sticker
                        showStickerReveal = true
                    }
                })
            }
            .sheet(isPresented: $showStickerReveal) {
                if let sticker = rewardedSticker {
                    StickerRevealView(sticker: sticker)
                }
            }
        }
    }
    
    private var navigationTitle: String {
        if isToday {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var jumpToTodayButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedDate = Date()
                displayedMonth = Date()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                Text("Jump to Today")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.matchaPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.matchaPrimary.opacity(0.15))
            )
        }
    }
    
    // Compact horizontal stats card
    private var compactStatsCard: some View {
        HStack(spacing: 0) {
            CompactStatItem(
                value: "\(selectedDayCaffeine)",
                unit: "mg",
                icon: "bolt.fill"
            )
            
            Divider()
                .frame(height: 30)
            
            CompactStatItem(
                value: "\(selectedDayCalories)",
                unit: "cal",
                icon: "flame.fill"
            )
            
            Divider()
                .frame(height: 30)
            
            CompactStatItem(
                value: "\(selectedDayLogs.count)",
                unit: "drinks",
                icon: "cup.and.saucer.fill"
            )
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.matchaForest.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    private var addDrinkButton: some View {
        Button {
            showAddDrink = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add Drink")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.matchaPrimary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Compact Stat Item

struct CompactStatItem: View {
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.matchaPrimary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.matchaForest)
            
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Color.matchaSage)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Monthly Calendar View

struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let datesWithLogs: Set<Date>
    let dateToStickerMap: [Date: UUID]
    let allStickers: [Sticker]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var monthDates: [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: start) - 1
        
        // Build array with nil padding for offset
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month Header
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(Color.matchaForest)
                }
                
                Spacer()
                
                Text(monthYearText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.matchaForest)
                
                Spacer()
                
                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Color.matchaForest)
                }
            }
            .padding(.horizontal, 8)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.matchaSage)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid - Larger cells for stickers
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        MonthDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            sticker: stickerFor(date: date),
                            hasLogs: datesWithLogs.contains(calendar.startOfDay(for: date))
                        ) {
                            withAnimation(.spring(response: 0.2)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: Color.matchaForest.opacity(0.1), radius: 10, y: 4)
        )
    }
    
    private func stickerFor(date: Date) -> Sticker? {
        let day = calendar.startOfDay(for: date)
        guard let stickerID = dateToStickerMap[day] else { return nil }
        return allStickers.first { $0.id == stickerID }
    }
    
    private func shiftMonth(by months: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: months, to: displayedMonth) {
            withAnimation(.spring(response: 0.3)) {
                displayedMonth = newMonth
            }
        }
    }
}

struct MonthDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sticker: Sticker?
    let hasLogs: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Selection/Today indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.matchaPrimary)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.matchaPrimary, lineWidth: 2)
                }
                
                // Content
                if let sticker = sticker {
                    // Show larger sticker icon for days with sticker rewards
                    VStack(spacing: 2) {
                        Image(systemName: sticker.imageName)
                            .font(.system(size: 22))
                            .foregroundStyle(isSelected ? .white : Color.matchaPrimary)
                        Text(dayNumber)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : Color.matchaSage)
                    }
                } else if hasLogs {
                    // Show day number with a dot for days with logs but no sticker
                    VStack(spacing: 4) {
                        Text(dayNumber)
                            .font(.subheadline)
                            .fontWeight(isSelected || isToday ? .bold : .medium)
                            .foregroundStyle(isSelected ? .white : Color.matchaForest)
                        Circle()
                            .fill(isSelected ? .white : Color.matchaSuccess)
                            .frame(width: 6, height: 6)
                    }
                } else {
                    // Empty day - just show number
                    Text(dayNumber)
                        .font(.subheadline)
                        .fontWeight(isSelected || isToday ? .bold : .regular)
                        .foregroundStyle(isSelected ? .white : Color.matchaForest)
                }
            }
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    JournalView()
        .modelContainer(for: [DrinkLog.self, Sticker.self, UserStats.self], inMemory: true)
}
