//
//  TablePopover.swift
//  TODO txt
//
//  Created by subzero on 26/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TablePopover: NSPopover, AutocompletionPopover {
    
    var element: Element!
    
    var tableView: NSTableView!
    
    let POPOVER_PADDING = CGFloat(8.0)
    let POPOVER_WIDTH = CGFloat(240.0)
    let INTERCELL_SPACING = CGSize(width: 0, height: 4)
    
    private var mention: String = ""
    private var data: [String] = []
    
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
        let id = NSUserInterfaceItemIdentifier("text")
        let column = NSTableColumn(identifier: id)
        column.isEditable = false
        column.width = POPOVER_WIDTH - 2*POPOVER_PADDING
        
        let tableView = NSTableView(frame: NSZeroRect)
        tableView.selectionHighlightStyle = .regular
        tableView.backgroundColor = .clear
        tableView.rowSizeStyle = .default
        tableView.intercellSpacing = INTERCELL_SPACING
        tableView.headerView = nil
        tableView.addTableColumn(column)
        tableView.refusesFirstResponder = true
        tableView.target = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(insert)
        
        let tableScrollView = NSScrollView(frame: NSZeroRect)
        tableScrollView.drawsBackground = false
        tableScrollView.documentView = tableView
        tableScrollView.hasVerticalScroller = true
        
        let contentView = NSView(frame: NSZeroRect)
        contentView.addSubview(tableScrollView)
        
        let contentViewController = NSViewController()
        contentViewController.view = contentView
        
        self.tableView = tableView
        
        self.animates = false
        self.contentViewController = contentViewController
        
    }
    
    func reload(_ data: [String]) {
        self.data = data
        
        let height = min(CGFloat(integerLiteral: data.count) *  (tableView.rowHeight + INTERCELL_SPACING.height) + 2*POPOVER_PADDING, CGFloat(320))
        let frame = NSRect(x: 0.0, y: 0.0, width: POPOVER_WIDTH, height: height)
        //autocompleteTableView.enclosingScrollView?.setFrameSize(NSInsetRect(frame, POPOVER_PADDING, POPOVER_PADDING).size)
        tableView.enclosingScrollView?.frame = NSInsetRect(frame, POPOVER_PADDING, POPOVER_PADDING)
        self.contentSize = frame.size
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: false)
        
    }
    
    func reload(_ data: [String], with mention: String) {
        
        self.mention = mention
        self.data = data
        
        let height = min(CGFloat(integerLiteral: data.count) *  (tableView.rowHeight + INTERCELL_SPACING.height) + 2*POPOVER_PADDING, CGFloat(320))
        let frame = NSRect(x: 0.0, y: 0.0, width: POPOVER_WIDTH, height: height)
        tableView.enclosingScrollView?.frame = NSInsetRect(frame, POPOVER_PADDING, POPOVER_PADDING)
        self.contentSize = frame.size
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: false)
        
    }
    
    func moveDown() {
        let row = tableView.selectedRow
        let indexSet = IndexSet(arrayLiteral: row + 1)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    
    func moveUp() {
        let row = tableView.selectedRow
        let indexSet = IndexSet(arrayLiteral: row - 1)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    
    @objc private func insert() {
        
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        let word = data[selectedRow]
        
        autocompletionDelegate?.autocompletionDidChange(self, str: word, element: element)
    }
    
    func complete() {
        insert()
    }
    
}

extension TablePopover : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
}

extension TablePopover : NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return NSTableRowView()
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let font = NSFont.systemFont(ofSize: 14.0)
        let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        
        let id = NSUserInterfaceItemIdentifier(rawValue: "cell")
        var cellView = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView
        if cellView == nil {
            cellView = NSTableCellView(frame: NSZeroRect)
            let textfield = NSTextField(frame: NSZeroRect)
            let imageView = NSImageView(frame: NSZeroRect)
            //imageView.image = NSImage(imageLiteralResourceName: "tag")
            textfield.isBezeled = false
            textfield.drawsBackground = false
            textfield.isEditable = false
            textfield.isSelectable = false
            cellView?.addSubview(textfield)
            cellView?.addSubview(imageView)
            cellView?.textField = textfield
            cellView?.imageView = imageView
            cellView?.identifier = id
            cellView?.textField?.font = font
        }
        
        let mutAttrStr = NSMutableAttributedString(string: data[row], attributes: [.font : font])
        mutAttrStr.addAttribute(.font, value: boldFont, range: mention.fullRange)
        
        cellView?.textField?.attributedStringValue = mutAttrStr
        
        return cellView
        
    }
}
