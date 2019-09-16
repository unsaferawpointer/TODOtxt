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
    @IBOutlet weak var templatesPopUpButton: NSPopUpButton!
    
    var filter: Filter?
    
    @objc var isHidden: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
        //setupPredicateEditor()
        predicateEditor.addRow(self)
        
    }
    
    func setupPredicateEditor() { 
        let left = [NSExpression(forKeyPath: "context"),NSExpression(forKeyPath: "project")]
        let operators = [NSComparisonPredicate.Operator.equalTo.rawValue as NSNumber]
        
        let rowTemplate = NSPredicateEditorRowTemplate(leftExpressions: left,
                                                       rightExpressionAttributeType: .stringAttributeType,
                                                       modifier: .all,
                                                       operators: operators,
                                                       options: 0)
        
       
        
        
        predicateEditor.rowTemplates = [rowTemplate] 
        predicateEditor.addRow(self)
        
        
        
        
        
    }
    
    
    @IBAction func buttonClicked(_ sender: Any) {
        print(#function)
        //predicateEditor.objectValue = NSPredicate(format: "project = %@ AND context = %@", argumentArray: ["test","tests"])
        print(predicateEditor.predicate)
    }
    
    
    
}
