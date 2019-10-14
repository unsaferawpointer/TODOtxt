//
//  SourceViewController.swift
//  TODOtxt
//
//  Created by subzero on 13.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum Group: Hashable {
    
    case mention(value: String)
    case date(value: String)
    case completion(value: Bool)
    case pinned
    case none
    
    var title: String {
        switch self {
        case .mention(let value):
            return String(value.dropFirst(2))
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
        case .mention(let value):
            return value
        case .date(let value):
            return value
        case .none:
            return "2"
        case .completion(let value):
            return value ? "3" : "1"
        }
    }
    
}

enum Grouping {
    case project, context, priority, date
    case commonDateStyle
    case status
    
    func group(for task: Task) -> Group {
        switch self {
        case .project:
            if let key = task.project {
                return .mention(value: "1_+\(key)")
            }
        case .context:
            if let key = task.context {
                return .mention(value: "1_@\(key)")
            }
        case .priority:
            if let key = task.priority {
                return .mention(value: "1_\(key)")
            }
        case .date:
            if let key = task.dueDate?.description {
                return .mention(value: "1_due:\(key)")
            }
        case .commonDateStyle:
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let date = task.dueDate as Date? else { return .none }
            
            
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
        
        case .status:
            return .completion(value: task.isCompleted)
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
    var grouping: Grouping = .context
    
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
        [ ] одноэтажная америка +books @everywhere
        [ ] игроку приготовиться +books @everywhere

        Путешествия:
        [ ] аквапарк в тайланде +travel
        [ ] поездка на шри - ланку в ноябре due:2019-11-07 +travel

        Заведения:
        [ ] бар «на связи» +go @moscow
        [ ] ресторан «в темноте» +go @moscow

        Остальное:
        [C] водительские права due:2020-06-01
        [B] посещение стоматолога +health due:2020-01-10
        """
        let parser = Parser()
        
        let tasks = parser.parse(string: text)
        print(tasks)
        reload(tasks)
        outlineView.reloadData()
        print(groups)
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
            if let cell = outlineView.makeView(withIdentifier: headerID, owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = group.title
                return cell
            }
        } else if let task = item as? Task {
            if let cell = outlineView.makeView(withIdentifier: dataCellID, owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = task.string
                return cell
            }
        }
        
        return nil
        
    }
}
