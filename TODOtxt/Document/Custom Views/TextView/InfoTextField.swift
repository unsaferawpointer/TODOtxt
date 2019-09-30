//
//  InfoTextField.swift
//  TODOtxt
//
//  Created by subzero on 24/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class InfoTextField: NSTextField {
    
    let format: String = "%d/%d tasks, %d/%d characters"
    
    var foregroundColor: NSColor = .textColor
    
    var tasksLimit: Int = 0
    var charactersLimit: Int = 0
    
    var tasksCount: Int = 0
    var charactersCount: Int = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    func setValues(tasksCount: Int, charactersCount: Int) {
        let newStr = String(format: format, arguments: [tasksCount, tasksLimit, charactersCount, charactersLimit])
        self.stringValue = newStr
        if tasksCount > Int(Double(tasksLimit) * 0.8) || charactersCount > Int(Double(charactersLimit) * 0.8) {
            self.textColor = NSColor.alert
        } else {
            self.textColor = foregroundColor
        }
    }
    
}
