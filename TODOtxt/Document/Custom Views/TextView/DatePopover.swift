//
//  DatePopover.swift
//  TODO txt
//
//  Created by subzero on 26/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol AutocompletionPopover: class {
    
    var autocompletionDelegate: AutocompletionPopoverDelegate? { get set }
    
    var isShown: Bool { get }
    
    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge)
    func close()
    
    func moveDown()
    func moveUp()
    
    func complete()
}

protocol AutocompletionPopoverDelegate : class {
    func autocompletionDidChange(_ sender: AutocompletionPopover, str: String, element: Element)
}

class DatePopover: NSPopover, AutocompletionPopover {
    
    
    let POPOVER_PADDING = CGFloat(8.0)
    let POPOVER_WIDTH = CGFloat(240.0)
    let INTERCELL_SPACING = CGSize(width: 0, height: 4)
    
    var dateGranulity: DateGranulity?
    var observeDateChanging: Bool = false 
    
    var datePicker: NSDatePicker!
    
    weak var autocompletionDelegate: AutocompletionPopoverDelegate?
    
    // ========
    // INIT
    // ========
    
    override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        
        let datePicker = NSDatePicker(frame: NSZeroRect)
        datePicker.datePickerStyle = .clockAndCalendar
        datePicker.datePickerMode = .single
        datePicker.datePickerElements = .yearMonthDay
        datePicker.drawsBackground = false
        datePicker.isBordered = false
        datePicker.delegate = self
        
        let datePickerSize = datePicker.intrinsicContentSize
        let contentWidth = datePickerSize.width + CGFloat(POPOVER_PADDING*2)
        let contentHeight = datePickerSize.height + CGFloat(POPOVER_PADDING*2)
        let contentFrame = NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        datePicker.frame = NSInsetRect(contentFrame, POPOVER_PADDING, POPOVER_PADDING)
        
        let contentView = NSView(frame: contentFrame)
        contentView.addSubview(datePicker)
        
        let contentViewController = NSViewController()
        contentViewController.view = contentView
        
        self.animates = false
        self.contentViewController = contentViewController
        self.datePicker = datePicker
    }
    
    func setDate(_ date: Date) {
        observeDateChanging = false
        self.datePicker.dateValue = date
        observeDateChanging = true
    }
    
    func complete() {
        let date = datePicker.dateValue
        insertDate(date)
    }
    
    func moveDown() {
        let date = datePicker.dateValue
        observeDateChanging = false
        datePicker.dateValue = Calendar.current.date(byAdding: .day, value: 7, to: date)!
        observeDateChanging = true
    }
    
    func moveUp() {
        let date = datePicker.dateValue
        observeDateChanging = false
        datePicker.dateValue = Calendar.current.date(byAdding: .day, value: -7, to: date)!
        observeDateChanging = true
    }
    
    func moveLeft() {
        let date = datePicker.dateValue
        observeDateChanging = false
        datePicker.dateValue = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        observeDateChanging = true
    }
    
    func moveRight() {
        let date = datePicker.dateValue
        observeDateChanging = false
        datePicker.dateValue = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        observeDateChanging = true
    }
    
    private func insertDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let stringDate = dateFormatter.string(from: date)
        autocompletionDelegate?.autocompletionDidChange(self, str: stringDate, element: .date(granulity: .day))
    }
    
}

extension DatePopover: NSDatePickerCellDelegate {
    func datePickerCell(_ datePickerCell: NSDatePickerCell, validateProposedDateValue proposedDateValue: AutoreleasingUnsafeMutablePointer<NSDate>, timeInterval proposedTimeInterval: UnsafeMutablePointer<TimeInterval>?) {
        print("value changed")
        let date = proposedDateValue.pointee as Date
        if observeDateChanging { insertDate(date) }
    }
}

