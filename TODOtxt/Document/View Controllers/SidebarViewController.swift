//
//  SidebarViewController.swift
//  TODO txt
//
//  Created by subzero on 25/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol SidebarDelegate: class {
    func selectedItemDidChange(newItem item: Item)
}

class SidebarViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    weak var delegate: SidebarDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    
    var dataAdapter = DataAdapter()
    
    private var dragDropType = NSPasteboard.PasteboardType(rawValue: "private.table-row")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.backgroundColor = .clear
        tableView.registerForDraggedTypes([dragDropType])
        let menu = NSMenu()
        menu.addItem(withTitle: "Delete", action: nil, keyEquivalent: String.backspace)
        menu.addItem(withTitle: "Rename", action: #selector(rename(_:)), keyEquivalent: "i")
        tableView.menu = menu
        
    }
    
    // ******** Selectors **********
    @IBAction func rename(_ sender: Any) {
        let clickedRow = tableView.clickedRow
        guard clickedRow >= 0 else { return }
        tableView.editColumn(0, row: clickedRow, with: nil, select: true)
    }
    
}

extension SidebarViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataAdapter.storage.count
    }
    
}

extension SidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let id = NSUserInterfaceItemIdentifier(rawValue: "cell")
        let cellView = tableView.makeView(withIdentifier: id, owner: self) as? ItemCellView
        
        cellView?.textField?.stringValue = dataAdapter.storage[row].name
        cellView?.imageView?.image = NSImage(imageLiteralResourceName: "filter")
        cellView?.badgeView.isHidden = !dataAdapter.storage[row].hasBadge
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        guard dropOperation == .above else { return false }
        
        
        var toDropIndex: Int?
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { dragItem, _, stop in
            if let str = (dragItem.item as! NSPasteboardItem).string(forType: self.dragDropType), let index = Int(str) {
                toDropIndex = index
                stop.pointee = ObjCBool(booleanLiteral: true)
            }
        }
        
        tableView.beginUpdates()
        tableView.moveRow(at: toDropIndex!, to: row)
        
        tableView.endUpdates()
        let item = dataAdapter.storage.remove(at: toDropIndex!)
        dataAdapter.storage.insert(item, at: row)
        
        
        return true
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        if dropOperation == .above {
            return .move
        }
        
        return []
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        
        // WARNING DRAG AND DROP TYPE
        let item = NSPasteboardItem()
        item.setString(String(row), forType: dragDropType)
        
        return item
    }
    
}

extension SidebarViewController {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let sRow = tableView.selectedRow
        guard sRow >= 0 else { fatalError("Empty selection is not supported") }
        let newItem = dataAdapter.storage[sRow]
        delegate?.selectedItemDidChange(newItem: newItem)
    }
}

