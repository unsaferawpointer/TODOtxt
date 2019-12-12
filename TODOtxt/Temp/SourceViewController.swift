//
//  SourceViewController.swift
//  TODOtxt
//
//  Created by subzero on 13.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum Group: Hashable, Comparable {
    
    static func < (lhs: Group, rhs: Group) -> Bool {
        if lhs.priority.0 == rhs.priority.0 {
            return lhs.priority.1 < lhs.priority.1
        } else {
            return lhs.priority.0 < rhs.priority.0
        }
    }
    
    case overdue
    case today
    case tomorrow
    case date(year: Int, month: Int, day: Int)
    case completed
    case none
    
    var priority: (typePriority: Int, valuePriority: Int) {
        switch self {
        case .overdue:
            return (1,0)
        case .today:
            return (2,0)
        case .tomorrow:
            return (3,0)
        case .date(let year, let month, let day):
            let value = year*10000+month*100+day
            return (4,value)
        case .none:
            return (5,0)
        case .completed:
            return (6,0)
        }
    }
    
}

class TableGroup {
    
    var value: Group
    var tasks: [Task]
    
    init(value: Group, tasks: [Task]) {
        self.value = value
        self.tasks = tasks
    }
}

class SourceViewController: NSViewController {
    
    
    
    var document: Document {
        return NSDocumentController.shared.document(for: (parent?.view.window!)!) as! Document
    }
    
    var taskStorage: TaskStorage?
    
    var data: [TableGroup] = []
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        // -------- Setup Outline View --------
        outlineView.dataSource = self
        outlineView.delegate = self
        
        outlineView.autoresizesOutlineColumn = true
        outlineView.sizeLastColumnToFit()
        
    }
    
    override func viewWillAppear() {
        print(#function)
                
                
                let text = """
        #Путешествия:
        - Rushguard @due(2019-09-08)
        - Surf-Zink WaterDuck @due(2020-11-23) в магазине «Траектория» #москва

        #Быт:
        - Краска для ткани (бирюзовая)

        #Техника:
        - Купить батарейную ручку BG-E6 #везде
        - Заказать подставку под MacBook @due(2020-01-05 11:35)
        - Заказать подставку2 под MacBook @due(2020-02-05 16:00)

        #Здоровье:
        - Миноксидил  @due(2019-12-05) #москва

        #Парфюмерия:
        - Lalique Lion 100ml @due(2019-10-20)
        - Lalique Lion 100ml @due(2019-10-20) @done
        - Lalique Encre Noire Sport 100ml
        """
        let parser = Parser()
        let tasks = parser.parse(string: text)
        print(tasks)
        reload(tasks)
        outlineView.reloadData()
                
        for group in data {
            outlineView.expandItem(group, expandChildren: true)
        }
            
    }
    
    func reload(_ tasks: [Task]) {
        
        
        let dictionary = Dictionary(grouping: tasks) { (element) -> Group in
            return group(for: element)
        }
        
        var tempData = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key.priority < rhs.key.priority
        }
        
        data = tempData.compactMap({ ( group, tasks) -> TableGroup? in
            return TableGroup(value: group, tasks: tasks)
        })
        
    }
    
    func group(for task: Task) -> Group {
           
        guard task.isCompleted == false else { return .completed }
           
        guard let date = task.dueDate?.value else { return .none }
           
        let calendar = NSCalendar.current
        
        let today = Date()
        let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if calendar.compare(today, to: date, toGranularity: .day) == .orderedDescending {
            return .overdue
        } else if calendar.compare(today, to: date, toGranularity: .day) == .orderedSame {
            return .today
        } else if calendar.compare(tomorrow, to: date, toGranularity: .day) == .orderedSame {
            return .tomorrow
        } 
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return .date(year: year, month: month, day: day)
    
    }
    
    
        
    
}

extension SourceViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let group = item as? TableGroup {
            return group.tasks.count
        }
        
        return data.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let group = item as? TableGroup {
            return group.tasks[index]
        }
        return data[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        if let _ = item as? TableGroup {
            return true
        }
        
        return false
    }
}

extension SourceViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let basicHeaderID = NSUserInterfaceItemIdentifier(rawValue: "BasicHeaderCell")
        let dateHeaderID = NSUserInterfaceItemIdentifier(rawValue: "DateHeaderCell")
        let dataCellID = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
        
        if let tableGroup = item as? TableGroup {
            
                switch tableGroup.value {
                case .overdue:
                    let cell = outlineView.makeView(withIdentifier: basicHeaderID, owner: nil) as! TaskBasicHeaderCellView
                    cell.textField?.stringValue = "Overdue".uppercased()
                    return cell
                case .today:
                    let cell = outlineView.makeView(withIdentifier: basicHeaderID, owner: nil) as! TaskBasicHeaderCellView
                    cell.textField?.stringValue = "Today".uppercased()
                    return cell
                case .tomorrow:
                    let cell = outlineView.makeView(withIdentifier: basicHeaderID, owner: nil) as! TaskBasicHeaderCellView
                    cell.textField?.stringValue = "Tomorrow".uppercased()
                    return cell
                case .date(let year, let month, let day):
                    
                    let cell = outlineView.makeView(withIdentifier: dateHeaderID, owner: nil) as! TaskHeaderCellView
                    cell.dateLabel.stringValue = (day - 10 > 0) ? "\(day)" : "0\(day)"
                    cell.monthLabel.stringValue = Calendar.current.monthSymbols[month-1].uppercased()
                    return cell
                case .none:
                    let cell = outlineView.makeView(withIdentifier: basicHeaderID, owner: nil) as! TaskBasicHeaderCellView
                    cell.textField?.stringValue = "Without date".uppercased()
                    return cell
                case .completed:
                    let cell = outlineView.makeView(withIdentifier: basicHeaderID, owner: nil) as! TaskBasicHeaderCellView
                    cell.textField?.stringValue = "Completed".uppercased()
                    return cell
                }
            
        } else if let task = item as? Task {
            if let cell = outlineView.makeView(withIdentifier: dataCellID, owner: nil) as? TaskDataCellView {
                
                cell.textField?.stringValue = task.body
                cell.statusCheckbox.state = task.isCompleted ? .on : .off
                cell.textField?.textColor = task.isCompleted ? .secondaryLabelColor : .textColor
                
                /*
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm"
                if let taskDate = task.dueDate?.value {
                    if taskDate.granulity == .time {
                        cell.secondaryLabel.stringValue = formatter.string(from: taskDate.date)
                        cell.secondaryLabel.isHidden = false
                    } else {
                        cell.secondaryLabel.isHidden = true
                    }
                } else {
                    cell.secondaryLabel.isHidden = true
                }
                */
                return cell
            }
        }
        
        return nil
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        if let _ = item as? TableGroup {
            return false
        }
        
        return false    
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
}
