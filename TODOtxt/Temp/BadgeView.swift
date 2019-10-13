//
//  BadgeView.swift
//  TODO txt
//
//  Created by subzero on 01/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa



@IBDesignable class BadgeView: NSView {
    
    @IBInspectable var count: Int = 0 {
        didSet {
            self.needsDisplay = true
            invalidateIntrinsicContentSize()
            self.isHidden = count <= 0
        }
    }
    
    @IBInspectable var fontSize: CGFloat = 14.0 {
        didSet {
            self.needsDisplay = true
            invalidateIntrinsicContentSize()
        }
    }
    
    private var title: String {
        return count < drawMaxCount ? "\(count)" : "\(drawMaxCount)+"
    }
    
    var textSize: NSSize {
        let font = NSFont(name: "HelveticaNeue-Bold", size: fontSize)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 0
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: NSColor.white,
            NSAttributedString.Key.font: font!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let number = title as NSString
        let size = number.size(withAttributes: attrs)
        
        return size
    }
    
    
    
    private var drawMaxCount: Int = 99
    //private var drawTextContent: NSString = ""
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        
        let radius = Double(textSize.height)/1.414
        let offset = radius - Double(textSize.height)/2
        
        let width = max(offset * 2 + Double(textSize.width),2 * radius)
        let height = 2 * radius
        let size = NSSize(width: width, height: height)
        
        let originX = Double(self.bounds.midX) - width/2
        let originY = Double(self.bounds.midY) - Double(self.textSize.height)/2 - offset
        let origin = NSPoint(x: originX, y: originY)
        
        
        
        let rect = NSRect(origin: origin, size: size)
        
        let path = NSBezierPath(roundedRect: rect, xRadius: CGFloat(radius), yRadius: CGFloat(radius))
        NSColor.alert.setFill()
        path.fill()
        
        
        let textX = Double(self.bounds.midX) - Double(self.textSize.width)/2
        let textY = Double(self.bounds.midY) - Double(self.textSize.height)/2
        let textOrigin = NSPoint(x: textX, y: textY)
        
        let textRect = NSRect(origin: textOrigin, size: self.textSize)
        
        let number = title as NSString
        let font = NSFont(name: "HelveticaNeue-Bold", size: fontSize)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 0
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: NSColor.white,
            NSAttributedString.Key.font: font!]
        
        number.draw(in: textRect, withAttributes: attrs)
        
      
    }
    
    override var intrinsicContentSize: NSSize {
        let radius = Double(textSize.height)/1.414
        let offset = radius - Double(textSize.height)/2
        
        let width = max(offset * 2 + Double(textSize.width),2 * radius)
        let height = radius * 2
        return NSSize(width: width, height: height)
    }
    
    
    
}

