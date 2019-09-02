//
//  NSColor Extention.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

extension NSColor {
    
    static let alert: NSColor = NSColor(0x4F65B4F)
    
    static let disableColor: NSColor = #colorLiteral(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    
    static let retroYellow: NSColor = #colorLiteral(red: 0.84, green: 0.65, blue: 0.38, alpha: 1)
    static let retroGreen: NSColor = #colorLiteral(red: 0.43, green: 0.56, blue: 0.42, alpha: 0.55)
    
    static let smokeColor: NSColor = #colorLiteral(red: 0.6, green: 0.63, blue: 0.69, alpha: 1)
    static let blueNight: NSColor = #colorLiteral(red: 0.1607843137, green: 0.2235294118, blue: 0.2705882353, alpha: 1.0)
    static let nightFall: NSColor = #colorLiteral(red: 0.337254902, green: 0.3490196078, blue: 0.3803921569, alpha: 1)
    static let lalique: NSColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
    
    static func color(hex: String) -> NSColor? {
        
        var str = hex
        str.removeAll { (value) -> Bool in
            return value == "#"
        }
        
        var redByte, greenByte, blueByte : UInt8
        
        if let colorCode = Int(str, radix: 16) {
            redByte = UInt8.init(truncatingIfNeeded: (colorCode >> 16))
            greenByte = UInt8.init(truncatingIfNeeded: (colorCode >> 8))
            blueByte = UInt8.init(truncatingIfNeeded: colorCode) // masks off high bits
            
            return NSColor(calibratedRed: CGFloat(redByte) / 0xff, green: CGFloat(greenByte) / 0xff, blue: CGFloat(blueByte) / 0xff, alpha: 1.0)
        } else {
            return nil
        }
    }
    
    /**
     HexColor
     eg. NSColor(0x222222)
     
     :param: value 0xFFFFF
     
     :returns: NSColor
     */
    public convenience init(_ value: Int) {
        let r = CGFloat(value >> 16 & 0xFF) / 255.0
        let g = CGFloat(value >> 8 & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
}

