//
//  TaskDataCellView.swift
//  TODOtxt
//
//  Created by subzero on 16.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TaskDataCellView: NSTableCellView {
    
    
    @IBOutlet weak var view: NSView!
    @IBOutlet weak var secondaryLabel: NSTextField!
    @IBOutlet weak var statusCheckbox: NSButton!
    //var defaultImage: NSImage?
    
    var nibName = "TaskDataCellView"
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: nil)
        //badgeView.translatesAutoresizingMaskIntoConstraints = false
        let contentFrame = NSMakeRect(0, 0, frame.size.width, frame.size.height)
        //textField?.font = NSFont(name: "IBM Plex Mono", size: 15.0)
        self.view.frame = contentFrame
        self.addSubview(self.view)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: nil)
        //badgeView.translatesAutoresizingMaskIntoConstraints = false
        let contentFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)
        //textField?.font = NSFont(name: "IBM Plex Mono", size: 15.0)
        self.view?.frame = contentFrame
        self.addSubview(self.view!)
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    
    
}
