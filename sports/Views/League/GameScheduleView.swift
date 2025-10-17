//
//  GameScheduleView.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import SwiftUI

struct GameScheduleView: View {
    let games: [Game]
    let isLoading: Bool
    let errorMessage: String?
    let onGameTap: (Game) -> Void
    
    @State private var currentDate = Date()
    @State private var currentVisibleDate: Date = Date()
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingNoGamesMessage = false
    @State private var noGamesMessage = ""
    @State private var scrollTarget: String?
    
    private var gamesByDate: [String: [Game]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        var grouped: [String: [Game]] = [:]
        
        for game in games {
            let dateString = formatter.string(from: game.gameTime)
            if grouped[dateString] == nil {
                grouped[dateString] = []
            }
            grouped[dateString]?.append(game)
        }
        
        // Sort games within each date by game time
        for date in grouped.keys {
            grouped[date]?.sort { $0.gameTime < $1.gameTime }
        }
        
        return grouped
    }
    
    private var sortedDates: [String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        // Always return all dates in chronological order (oldest first)
        return gamesByDate.keys.sorted { dateString1, dateString2 in
            guard let date1 = formatter.date(from: dateString1),
                  let date2 = formatter.date(from: dateString2) else {
                return false
            }
            return date1 < date2 // Chronological order (oldest first)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky Date Header
            if !isLoading && errorMessage == nil && !games.isEmpty {
                stickyDateHeader
            }
            
            // Main Content
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading games...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Error Loading Games")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        // TODO: Implement retry logic
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if games.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Games Found")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("No games scheduled for this season.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(sortedDates, id: \.self) { dateString in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Date Header
                                    HStack {
                                        Text(dateString)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text("\(gamesByDate[dateString]?.count ?? 0) games")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .onAppear {
                                        updateVisibleDate(from: dateString)
                                    }
                                    
                                    // Games for this date - Horizontal scrolling
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            if let gamesForDate = gamesByDate[dateString] {
                                                ForEach(gamesForDate) { game in
                                                    Button(action: {
                                                        onGameTap(game)
                                                    }) {
                                                        GamePosterCard(game: game)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .frame(width: 200) // Fixed width for horizontal scrolling
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .id(dateString)
                            }
                        }
                        .padding(.vertical)
                    }
                    .scrollPosition(id: $scrollTarget)
                    .onChange(of: scrollTarget) { _, newTarget in
                        // Clear scrollTarget after a short delay to allow for re-scrolling
                        if newTarget != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollTarget = nil
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .onChange(of: showingDatePicker) { _, isShowing in
            print("DEBUG: showingDatePicker changed to: \(isShowing)")
            if isShowing {
                // Update selectedDate to current visible date when opening picker
                print("DEBUG: Updating selectedDate to currentVisibleDate: \(currentVisibleDate)")
                selectedDate = currentVisibleDate
            }
        }
        .onAppear {
            // Initialize selectedDate with currentVisibleDate
            selectedDate = currentVisibleDate
            print("DEBUG: GameScheduleView onAppear, currentVisibleDate: \(currentVisibleDate)")
        }
        .overlay(
            // No games message overlay
            Group {
                if showingNoGamesMessage {
                    VStack {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                            Text(noGamesMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.easeInOut(duration: 0.3), value: showingNoGamesMessage)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        )
    }
    
    // MARK: - Sticky Date Header
    private var stickyDateHeader: some View {
        Button(action: {
            print("DEBUG: Sticky header tapped, currentVisibleDate: \(currentVisibleDate)")
            selectedDate = currentVisibleDate
            showingDatePicker = true
        }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text(formatDateForHeader(currentVisibleDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                CustomCalendarView(
                    selectedDate: $selectedDate,
                    gamesByDate: gamesByDate
                )
                .padding()
                
                Button("Jump to Date") {
                    print("DEBUG: Jump to Date button tapped, selectedDate: \(selectedDate)")
                    jumpToDate(selectedDate)
                    showingDatePicker = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                
                Spacer()
            }
            .padding()
            .navigationTitle("Jump to Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDateForHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func updateVisibleDate(from dateString: String) {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        if let date = formatter.date(from: dateString) {
            print("DEBUG: Updating visible date to: \(dateString) -> \(date)")
            currentVisibleDate = date
        }
    }
    
    private func jumpToDate(_ targetDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let targetDateString = formatter.string(from: targetDate)
        
        print("DEBUG: Jumping to date: \(targetDateString)")
        
        if gamesByDate[targetDateString] != nil {
            // Date has games, jump to it
            print("DEBUG: Date has games, jumping to: \(targetDateString)")
            scrollTarget = targetDateString
        } else {
            // No games on this date, find closest date with games
            if let closestDateString = findClosestDateWithGames(to: targetDate) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                
                if let closestDate = dateFormatter.date(from: closestDateString) {
                    let dayFormatter = DateFormatter()
                    dayFormatter.dateFormat = "EEEE, MMMM d"
                    
                    noGamesMessage = "No games on \(dayFormatter.string(from: targetDate)). Showing \(dayFormatter.string(from: closestDate))"
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingNoGamesMessage = true
                    }
                    
                    // Hide message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingNoGamesMessage = false
                        }
                    }
                    
                    // Jump to closest date
                    scrollTarget = closestDateString
                }
            }
        }
    }
    
    
    private func findClosestDateWithGames(to targetDate: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        let calendar = Calendar.current
        let sortedDateStrings = sortedDates
        
        // Since dates are now in chronological order (oldest first), we need to find the closest date
        var closestFutureDate: String?
        var closestPastDate: String?
        
        for dateString in sortedDateStrings {
            if let date = formatter.date(from: dateString) {
                if date >= targetDate {
                    // Found a future date, prefer the first one (closest future)
                    if closestFutureDate == nil {
                        closestFutureDate = dateString
                    }
                } else {
                    // Keep updating the closest past date
                    closestPastDate = dateString
                }
            }
        }
        
        // Prefer future date over past date
        return closestFutureDate ?? closestPastDate
    }
}

    // MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let gamesByDate: [String: [Game]]
    
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(selectedDate: Binding<Date>, gamesByDate: [String: [Game]]) {
        self._selectedDate = selectedDate
        self.gamesByDate = gamesByDate
        self.dateFormatter.dateStyle = .full
        print("DEBUG: CustomCalendarView init with selectedDate: \(selectedDate.wrappedValue)")
        
        // Set currentMonth to match the selectedDate
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month/Year Header with Navigation
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Day of Week Headers
            HStack {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isCurrentMonth(date) ? .primary : .secondary)
                            
                            if hasGamesOnDate(date) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    isSelectedDate(date) ? Color.blue :
                                    isToday(date) ? Color.blue.opacity(0.1) :
                                    Color.clear
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelectedDate(date) ? Color.blue :
                                    isToday(date) ? Color.blue.opacity(0.3) :
                                    Color.clear,
                                    lineWidth: isSelectedDate(date) ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update currentMonth to match the selected date when it changes
            print("DEBUG: CustomCalendarView selectedDate changed to: \(newDate)")
            currentMonth = newDate
        }
        .onAppear {
            print("DEBUG: CustomCalendarView onAppear, selectedDate: \(selectedDate), currentMonth: \(currentMonth)")
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDaysToSubtract = (firstDayOfWeek - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        
        // Add empty cells for days before the first day of the month
        for i in 0..<numberOfDaysToSubtract {
            if let date = calendar.date(byAdding: .day, value: -numberOfDaysToSubtract + i, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasGamesOnDate(_ date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return gamesByDate[dateString] != nil
    }
    
    private func isSelectedDate(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
}

// Preview removed - use real data from server instead
