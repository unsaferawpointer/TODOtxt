//
//  FilterViewController.swift
//  TODOtxt
//
//  Created by subzero on 04/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class FilterViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }

    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var okButton: NSButton!
    
    @objc var filter: NSPredicate? = Preferences.shared.badgeFilter
    
    override func viewDidLoad() {
        super.viewDidLoad()
        predicateEditor?.objectValue = filter
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        print(#function)
        Preferences.shared.badgeFilter = predicateEditor.predicate
        print(predicateEditor.predicate?.predicateFormat)
    }
    
}
