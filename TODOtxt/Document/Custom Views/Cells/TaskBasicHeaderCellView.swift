//
//  TaskBasicHeaderCellView.swift
//  TODOtxt
//
//  Created by subzero on 20.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TaskBasicHeaderCellView: NSTableCellView {

   
        
        @IBOutlet weak var view: NSView!
        
        
        var nibName = "TaskBasicHeaderCellView"
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            
            Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: nil)
            let contentFrame = NSMakeRect(0, 0, frame.size.width, frame.size.height)
            self.view.frame = contentFrame
            self.addSubview(self.view)
        }
        
        required init?(coder decoder: NSCoder) {
            super.init(coder: decoder)
            
            Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: nil)
            let contentFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)
            self.view?.frame = contentFrame
            self.addSubview(self.view!)
            
        }
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            
            // Drawing code here.
        }
        
        
        
    }
