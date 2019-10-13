//
//  TaskTextAttachmentCell.swift
//  TODOtxt
//
//  Created by subzero on 09.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TaskTextAttachmentCell: NSTextAttachmentCell {
    
    var completed: Bool = false
    var completedImage: NSImage = NSImage(imageLiteralResourceName: "completed")
    var uncompletedImage: NSImage = NSImage(imageLiteralResourceName: "uncompleted")
    
}
