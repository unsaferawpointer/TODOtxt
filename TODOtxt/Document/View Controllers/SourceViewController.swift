//
//  SourceViewController.swift
//  TODOtxt
//
//  Created by subzero on 13.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum Group: Hashable {
    
    case date(value: String)
    case completion(value: Bool)
    case pinned
    case none
    
    var title: String {
        switch self {
        case .completion(let value):
            return value ? "completed" : "uncompleted"
        case .date(let value):
            return String(value.dropFirst(4))
        case .pinned:
            return "pinned"
        case .none:
            return "w/o"
        }
    }
    
    var priority: String {
        switch self {
        case .pinned:
            return "0"
        case .date(let value):
            return value
        case .none:
            return "2"
        case .completion(let value):
            return value ? "3" : "1"
        }
    }
    
}


class Grouping {
    
    func group(for task: Task) -> Group {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = task.dueDate?.date as Date? else { return .none }
        
        let calendar = NSCalendar.current
        let today = Date()
        let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if calendar.compare(today, to: date, toGranularity: .day) == .orderedDescending {
            return .date(value: "1_0_overdue")
        } else if calendar.compare(today, to: date, toGranularity: .day) == .orderedSame {
            return .date(value: "1_1_today")
        } else if calendar.compare(tomorrow, to: date, toGranularity: .day) == .orderedSame {
            return .date(value: "1_2_tomorrow")
        } else if calendar.compare(today, to: date, toGranularity: .weekOfYear) == .orderedSame {
            return .date(value: "1_3_current week")
        } else if calendar.compare(today, to: date, toGranularity: .month) == .orderedSame {
            return .date(value: "1_4_current month")
        } else if calendar.compare(today, to: date, toGranularity: .year) == .orderedSame {
            return .date(value: "1_5_current year")
        } else {
            return .date(value: "1_6_later")
        }
        
        return .none
    }
}

class TasksGroup {
    
    var title: String
    var tasks: [Task]
    
    init(_ title: String, tasks: [Task]) {
        self.title = title
        self.tasks = tasks
    }
    
}

class SourceViewController: NSViewController {
    
    var groups: [TasksGroup] = []
    var filter: NSPredicate = NSPredicate.init(value: true)
    var grouping: Grouping = Grouping()
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        // Do view setup here.
        // -------- Setup Outline View --------
        outlineView.dataSource = self
        outlineView.delegate = self
        
        let text = 
        """
        Задания, которые не требуют срочности.

        Книги:
        [x] Одноэтажная америка @everywhere
        [ ] Игроку приготовиться @everywhere

        Путешествия:
        [x] Аквапарк в тайланде
        [ ] Поездка на шри - ланку в ноябре @due(2019-11-07)

        Заведения:
        [ ] Бар «на связи» @moscow
        [ ] Ресторан «в темноте» @moscow

        Остальное:
        [C] Водительские права @due(2020-06-01)
        [B] Посещение стоматолога @due(2020-01-10)
        """
        let parser = Parser()
        
        let tasks = parser.parse(string: text)
        reload(tasks)
        outlineView.reloadData()
        for group in groups {
            outlineView.expandItem(group, expandChildren: true)
        }
        
    }
    
    func reload(_ tasks: [Task]) {
        let array = NSArray(array: tasks)
        let filtered = array.filtered(using: filter) as! [Task]
        
        let dictionary = Dictionary(grouping: filtered) { (element) -> Group in
            
            return grouping.group(for: element)
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key.priority < rhs.key.priority
        }
        
        var newGroups = [TasksGroup]()
        for (key, value) in data {
            let taskGroup = TasksGroup(key.title, tasks: value)
            newGroups.append(taskGroup)
        }
        groups = newGroups
        
    }
    
}

extension SourceViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let group = item as? TasksGroup {
            return group.tasks.count
        }
        return groups.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let group = item as? TasksGroup {
            return group.tasks[index]
        }
        return groups[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        if let _ = item as? TasksGroup {
            return true
        }
        
        return false
    }
}

extension SourceViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let headerID = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
        let dataCellID = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
        print("item = \(item)")
        if let group = item as? TasksGroup {
            if let cell = outlineView.makeView(withIdentifier: headerID, owner: nil) as? TaskHeaderCellView {
                //cell.textField?.stringValue = group.title
                return cell
            }
        } else if let task = item as? Task {
            if let cell = outlineView.makeView(withIdentifier: dataCellID, owner: nil) as? TaskDataCellView {
                cell.textField?.stringValue = task.body
                cell.statusCheckbox.state = task.isCompleted ? .on : .off
                if let context = task.hashtag {
                    cell.secondaryLabel.stringValue = context
                    cell.secondaryLabel.isHidden = false
                } else {
                    cell.secondaryLabel.isHidden = true
                }
                
                return cell
            }
        }
        
        return nil
        
    }
}
