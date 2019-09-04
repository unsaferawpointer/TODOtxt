//
//  FilterViewController.swift
//  TODOtxt
//
//  Created by subzero on 04/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class FilterViewController: NSViewController {

    @IBOutlet weak var nameTextfield: NSTextField!
    @IBOutlet weak var conditionTextfield: NSTextField!
    
    var filter: Filter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
        
    }
    
    func parse() -> Filter? {
        let conditionStr = conditionTextfield.stringValue
        
        var components: [String] = []
        let byAndArray = conditionStr.components(separatedBy: "AND")
        for substring in byAndArray {
            let byOrArray = substring.components(separatedBy: "OR")
            components += byOrArray
        }
        
        let pattern = #"^\s*(project|context)\s+(=|=>|<=|contains)\s+(\w+)\s+$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        for substring in components {
            let range = substring.fullRange
            if let match = regex.firstMatch(in: substring, options: [], range: range) {
                let mentionStr = substring.substring(from: match.range(at: 1))
                let filterOperatorStr = substring.substring(from: match.range(at: 2))
                let value = substring.substring(from: match.range(at: 3))
                print("mention = \(mentionStr)")
                print("filterOperator = \(filterOperatorStr)")
                print("value = \(value)")
                
                guard let filterOperator = Filter.FilterOperator(filterOperatorStr) else { return nil }
                guard let mention = Element(rawValue: mentionStr) else { return nil }
                let aggregator = ElementAggregator(element: mention)
                let filter = Filter(filterOperator: filterOperator, value: value, aggregator: aggregator)
                return filter
            }
        }
        
        return nil
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        guard let filter = parse() else { return }
        
    }
    
    
}
