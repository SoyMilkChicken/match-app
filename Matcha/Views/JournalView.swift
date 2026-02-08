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
                // 1. Top: Hero Stats Card (Dark Green)
                HeroStatsCard(
                    caffeine: selectedDayCaffeine,
                    calories: selectedDayCalories,
                    drinks: selectedDayLogs.count
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                
                // 2. Middle: Calendar
                MonthCalendarView(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    datesWithLogs: datesWithLogs,
                    dateToStickerMap: dateToStickerMap,
                    allStickers: unlockedStickers
                )
                .padding(.horizontal, 8)
                
                // 3. Daily History Section
                VStack(alignment: .leading, spacing: 8) {
                    // Date Header
                    Text(historyHeaderText)
                        .font(.headline)
                        .foregroundStyle(Color.matchaForest)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    // The List
                    ScrollView {
                        VStack(spacing: 10) {
                            if selectedDayLogs.isEmpty {
                                // Empty State
                                VStack(spacing: 8) {
                                    Image(systemName: "cup.and.saucer")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.matchaSage.opacity(0.5))
                                    Text("No sips logged yet")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.matchaSage)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                ForEach(selectedDayLogs) { log in
                                    DrinkLogRow(log: log)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80) // Space for floating button
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color.matchaSurface)
            .overlay(alignment: .bottom) {
                addDrinkButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .background(Color.matchaSurface)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
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
    
    private var historyHeaderText: String {
        if isToday {
            return "Today's Sips"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Sips for \(formatter.string(from: selectedDate))"
        }
    }
    
    private var addDrinkButton: some View {
        Button {
            showAddDrink = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Drink")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#2c6c24"))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Hero Stats Card (Dark Green - Compact)

struct HeroStatsCard: View {
    let caffeine: Int
    let calories: Int
    let drinks: Int

    var body: some View {
        HStack(spacing: 0) {
            statItem(value: "\(caffeine)", unit: "mg", label: "Caffeine", icon: "bolt.fill")
            
            // Shorter Divider
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40) 
            
            statItem(value: "\(calories)", unit: "cal", label: "Calories", icon: "flame.fill")
            
            // Shorter Divider
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            
            statItem(value: "\(drinks)", unit: "", label: "Drinks", icon: "cup.and.saucer.fill")
        }
        .padding(.vertical, 16)
        .background(Color(hex: "#2c6c24"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "#2c6c24").opacity(0.3), radius: 8, y: 4)
    }

    private func statItem(value: String, unit: String, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.subheadline)
                .opacity(0.9)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .opacity(0.8)
                }
            }
            
            Text(label)
                .font(.caption2)
                .opacity(0.7)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Monthly Calendar View (Full Width)

struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let datesWithLogs: Set<Date>
    let dateToStickerMap: [Date: UUID]
    let allStickers: [Sticker]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var monthDates: [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start) - 1
        
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
        VStack(spacing: 8) {
            // Month Header
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.matchaPrimary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthYearText)
                    .font(.headline)
                    .foregroundStyle(Color.matchaForest)
                
                Spacer()
                
                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.matchaPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            
            // Weekday Headers
            HStack(spacing: 2) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.matchaSage)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid - Square cells, full width
            LazyVGrid(columns: columns, spacing: 2) {
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
                        .aspectRatio(1.0, contentMode: .fill)
                    } else {
                        Color.clear
                            .aspectRatio(1.0, contentMode: .fill)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
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

// MARK: - Month Day Cell (Big Stickers)

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
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackground)
                
                // Selection border
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.matchaPrimary, lineWidth: 3)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.matchaPrimary.opacity(0.5), lineWidth: 2)
                }
                
                // Content
                VStack(spacing: 2) {
                    // Day number - top left
                    HStack {
                        Text(dayNumber)
                            .font(.caption2)
                            .fontWeight(isSelected || isToday ? .bold : .medium)
                            .foregroundStyle(isSelected ? Color.matchaPrimary : Color.matchaForest)
                        Spacer()
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Large sticker or indicator - centered
                    if let sticker = sticker {
                        Image(systemName: sticker.imageName)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.matchaPrimary)
                    } else if hasLogs {
                        Circle()
                            .fill(Color.matchaSuccess)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(4)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var cellBackground: Color {
        if isSelected {
            return Color.matchaSuccess.opacity(0.3)
        } else if hasLogs {
            return Color.matchaSurface
        } else {
            return Color.matchaSurface.opacity(0.5)
        }
    }
}

// MARK: - Drink Log Row

struct DrinkLogRow: View {
    let log: DrinkLog
    
    var body: some View {
        HStack(spacing: 12) {
            Text(log.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.matchaForest)
                
                Text(log.loggedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(Color.matchaSage)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(log.caffeineMg) mg")
                    .font(.caption)
                    .foregroundStyle(Color.matchaForest)
                Text("\(log.calories) cal")
                    .font(.caption)
                    .foregroundStyle(Color.matchaSage)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
    }
}

#Preview {
    JournalView()
        .modelContainer(for: [DrinkLog.self, Sticker.self, UserStats.self], inMemory: true)
}
