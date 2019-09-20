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
    @IBOutlet weak var nameTextfield: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    
    @objc var isHidden: Bool = true
    
    @objc var item: Item? {
        didSet {
            configure()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        nameTextfield?.stringValue = item?.name ?? "New filter"
        predicateEditor?.objectValue = item?.filter
    }
    
    
    @IBAction func buttonClicked(_ sender: Any) {
        print(#function)
        //predicateEditor.objectValue = NSPredicate(format: "ALL project = %@ AND context = %@", argumentArray: ["test","tests"])
        print(predicateEditor.predicate?.predicateFormat)
    }
    
}
