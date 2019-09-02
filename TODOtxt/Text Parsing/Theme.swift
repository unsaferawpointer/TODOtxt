//
//  Theme.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation
import Cocoa

struct ThemePair {
    
    let name: String
    
    let light: Theme
    let dark: Theme
    
    init(name: String, light: Theme, dark: Theme) {
        self.name = name
        self.light = light
        self.dark = dark
    }
    var description: String {
        return "Theme (Name = \(name))"
    }
}

struct Theme: Equatable {
    
    var defaultColor: NSColor = NSColor.labelColor
    
    var background: NSColor {
        return scheme["background"] ?? NSColor.textColor
    }
    var foreground: NSColor {
        return scheme["foreground"] ?? NSColor.darkGray
    }
    var selection: NSColor {
        return scheme["selection"] ?? NSColor.textColor
    }
    
    var line: NSColor {
        return scheme["line"] ?? NSColor.textColor
    }
    
    var completed: NSColor {
        return scheme["completed"] ?? NSColor.textColor
    }
    
    private var scheme: [String : NSColor] = [:]
    
    init(scheme: [String : String]) {
        
        let handler = { (dictionary: [String : String]) -> [String : NSColor] in
            var scheme = [String : NSColor]()
            for (key, value) in dictionary {
                scheme[key] = NSColor.color(hex: value)
            }
            return scheme
        }
        self.scheme = handler(scheme)
    }
    
    func color(for element: Element) -> NSColor {
        return scheme[element.rawValue] ?? defaultColor
    }
}

