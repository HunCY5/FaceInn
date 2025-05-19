//
//  DatePickerPopoverViewController.swift
//  FaceInn
//
//  Created by 신찬솔 on 5/18/25.
//

import UIKit
import FSCalendar

final class DatePickerPopoverViewController: UIViewController, FSCalendarDelegate, FSCalendarDelegateAppearance, FSCalendarDataSource {

    var onDateSelected: ((Date?, Date?) -> Void)?

    private let calendar = FSCalendar()
    private var startDate: Date?
    private var endDate: Date?
    private var hasUserInteracted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        calendar.delegate = self
        calendar.dataSource = self
        calendar.scrollDirection = .horizontal
        calendar.scope = .month
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.appearance.selectionColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        calendar.appearance.headerTitleColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        calendar.appearance.weekdayTextColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        calendar.appearance.todayColor = UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1)
        calendar.allowsMultipleSelection = true
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            calendar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
        ])

        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        startDate = today
        endDate = tomorrow
        calendar.select(today)
        calendar.select(tomorrow)
        calendar.appearance.todayColor = .white
        calendar.appearance.titleTodayColor = UIColor.black
        calendar.appearance.borderRadius = 1.0
    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        hasUserInteracted = true
        
        // Clear default selection if user interacts first time with different date
        if let start = startDate, let end = endDate, !Calendar.current.isDate(date, inSameDayAs: start), !Calendar.current.isDate(date, inSameDayAs: end) {
            for selected in calendar.selectedDates {
                calendar.deselect(selected)
            }
            startDate = nil
            endDate = nil
            calendar.reloadData()
            calendar.select(date)
            startDate = date
            onDateSelected?(startDate, endDate)
            return
        }

        // If one date is selected
        if let start = startDate, endDate == nil {
            if date < start {
                endDate = start
                startDate = date
            } else {
                endDate = date
            }
            calendar.select(startDate!)
            calendar.select(endDate!)
            calendar.reloadData()
        }
        // If no date is selected yet
        else if startDate == nil {
            startDate = date
            calendar.select(date)
        }
        onDateSelected?(startDate, endDate)
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        guard let start = startDate, let end = endDate else { return nil }
        if Calendar.current.isDate(date, inSameDayAs: start) || Calendar.current.isDate(date, inSameDayAs: end) {
            return UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 1.0)
        }
        return nil
    }

    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderRadiusFor date: Date) -> CGFloat {
        return 1.0
    }

    // Highlight the range between startDate and endDate with a soft green background
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        guard let start = startDate, let end = endDate else { return nil }
        if date > start && date < end {
            return UIColor(red: 47/255, green: 175/255, blue: 83/255, alpha: 0.15)
        }
        return nil
    }
    
}
