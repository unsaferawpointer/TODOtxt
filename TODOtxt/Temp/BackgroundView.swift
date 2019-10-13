//
//  BackgroundView.swift
//  TODO txt
//
//  Created by subzero on 25/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

@IBDesignable
class BackgroundView: NSView {
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    
    @IBInspectable
    var backgroundColor: NSColor = .textBackgroundColor {
        didSet {
            wantsLayer = true
            self.layer?.backgroundColor = backgroundColor.cgColor
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    
    override func viewDidChangeEffectiveAppearance() {
        self.layer?.backgroundColor = backgroundColor.cgColor
    }
    
}
