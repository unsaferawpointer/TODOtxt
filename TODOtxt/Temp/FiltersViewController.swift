//
//  FiltersViewController.swift
//  TODOtxt
//
//  Created by subzero on 19/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class FiltersViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    lazy var sheetViewController: FilterViewController = {
        return self.storyboard!.instantiateController(withIdentifier: "FilterEditor") as! FilterViewController
    }()
    
    
    @objc var array: [Item] = [Item("Moscow context", predicateFormat: "context = %@", argumentArray: ["moscow"]),
                         Item("Travel project", predicateFormat: "project = %@", argumentArray: ["travel"]),
                         Item("Tyumen context", predicateFormat: "context = %@", argumentArray: ["tyumen"])]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.doubleAction = #selector(doubleClicked(_:))
    }
    
    @objc func doubleClicked(_ sender: Any?) {
        print(#function)
        let clickedRow = tableView.clickedRow
        guard clickedRow > -1 else { return }
        let item = array[clickedRow]
        
        self.presentAsSheet(sheetViewController)
    }
    
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print(#function)
        let clickedRow = tableView.clickedRow
        guard clickedRow > -1 else { return }
        let item = array[clickedRow]
        if let secondViewController = segue.destinationController as? FilterViewController {
           
        }
    }  
    
}
