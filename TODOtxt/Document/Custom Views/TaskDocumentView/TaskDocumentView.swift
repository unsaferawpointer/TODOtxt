//
//  TaskDocumentView.swift
//  TODOtxt
//
//  Created by subzero on 01/10/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol TaskDocumentViewDelegate: class {
    func dataDidChange()
}

class TaskDocumentView: NSView {
    
    let nibName = "TaskDocumentView"
    // ********** Updating **********
    
    weak var delegate: TaskDocumentViewDelegate?

    @IBOutlet weak var view: NSView!
    @IBOutlet weak var textView: TaskTextView!
    @IBOutlet weak var scrollView: RefreshableScrollView!
    @IBOutlet weak var infoTextField: InfoTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var taskStorage: TaskStorage = TaskStorage()
    var loadQueue = OperationQueue()
    var sortQueue = OperationQueue()
    var grouping: Grouping = .status
    var isRefreshing = false {
        didSet {
            if isRefreshing {
                textView.isEditable = false
                progressIndicator.startAnimation(self)
            } else {
                textView.isEditable = true
                progressIndicator.stopAnimation(self)
            }
        }
    }
    
    
    
    var data: Data {
        return textView.string.data(using: .utf8) ?? Data()
    }
   
    // ******** Init block ********
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed(nibName, owner: self, topLevelObjects: nil)
        let contentFrame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)
        
        self.view?.frame = contentFrame
        self.addSubview(self.view!)
        
        // ---------- refreshable scrollview ----------
        scrollView.delegate = self
        
        // ---------- textview ----------
        textView.delegate = self
        textView.font = NSFont(name: "IBM Plex Mono", size: 15.0)
        textView.insertionPointColor = NSColor.alert
        //textView.textContainer?.replaceLayoutManager(TaskLayoutManager())
        
        // ---------- text storage ----------
        let textStorage = TaskTextStorage()
        textStorage.delegate = self
        textStorage.taskDelegate = self
        textView.textContainer?.layoutManager?.replaceTextStorage(textStorage)
        textView.layoutManager?.allowsNonContiguousLayout = false
        
        // ---------- rulerview ----------
        
        let rulerView = TaskRulerView(textView: textView)
        textView.rulerView = rulerView
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        
        // ---------- info textfield ----------
        // WARNING
        infoTextField.charactersLimit = 4000
        infoTextField.tasksLimit = 150
        infoTextField.setValues(tasksCount: 0, charactersCount: 0)
        infoTextField.foregroundColor = NSColor.textColor
    }
    
    private func configureInfoTextField() {
        let tasksCount = taskStorage.count
        let charactersCount = textView.string.count 
        infoTextField.setValues(tasksCount: tasksCount, charactersCount: charactersCount)
    }
    
    func reload(str: String) {
        
        textView.set(text: str)
        
        
        loadQueue.cancelAllOperations()
        isRefreshing = true
        let operation = ParserOperation(string: str)
        operation.completionBlock = { [weak self] in
            self?.taskStorage = operation.taskStorage
            let operation2 = TextOperation(storage: operation.taskStorage.storage)
            //operation2.addDependency(operation)
            operation2.completionBlock = { [weak self] in
                DispatchQueue.main.async {
                    self?.isRefreshing = false
                    //let text = operation2.string
                    //self?.textView.set(text: text)
                    self?.configureInfoTextField()
                }
                
            }
            operation2.start()
        }
        
        loadQueue.addOperation(operation)
        
        
    }
    
    // ---------- sorting ----------
    @IBAction func sort(_ sender: NSMenuItem) {
        
        /*
        guard !isRefreshing else { return }
        
        self.isRefreshing = true
        
        switch sender.identifier!.rawValue {
        case "project":
            grouping = .project
        case "context":
            grouping = .context
        case "priority":
            grouping = .priority
        case "due_date":
            grouping = .date
        case "status":
            grouping = .status
        case "due_date_state":
            grouping = .commonDateStyle
        default:
            break
        }
        
        
        
        let operation2 = TextOperation(storage: taskStorage.storage)
        operation2.grouping = grouping
        //operation2.addDependency(operation)
        operation2.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                let text = operation2.string
                self?.textView.set(text: text)
            }
            
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            operation2.start()
        }
 */
        
    }
    
    @IBAction func removeCompleted(_ sender: Any?) {
        guard !isRefreshing else { return }

        self.isRefreshing = true
        
        let operation2 = TextOperation(storage: taskStorage.storage)
        operation2.grouping = grouping
        //operation2.addDependency(operation)
        operation2.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                let text = operation2.string
                self?.textView.set(text: text)
            }
            
        }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.taskStorage.remove(by: NSPredicate(format: "status != nil", argumentArray: nil))
            operation2.start()
        }
    }
    
    
    
    
}

extension TaskDocumentView: NSTextStorageDelegate {
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let textStorage = textView.textStorage as? TaskTextStorage else { return }
        if textStorage.observeChanging {
            delegate?.dataDidChange()
            configureInfoTextField()
        }
        
        
        textView.rulerView!.needsDisplay = true
    }
    
}

extension TaskDocumentView: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        let regex = try! NSRegularExpression(pattern: #"^- "#, options: .anchorsMatchLines)
        if let match = regex.firstMatch(in: textView.string, options: [], range: textView.string.fullRange) {
            textView.replaceText(in: match.range, with: "[ ] ")
        }
    }
    
    private func showAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Delete completed")
        alert.informativeText = "The file is big. Please, split it for any more small or delete completed tasks"
        
        alert.beginSheetModal(for: self.window!) { (response) in
            switch response {
            case .alertFirstButtonReturn:
                print("OK")
            case .alertSecondButtonReturn:
                // WARNING
                self.textView.removeCompleted()
            default:
                break
            }
        }
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        let delta = (replacementString?.count ?? 0) - affectedCharRange.length
        //NSLog("shouldChangeText with delta = %d", delta)
        let result = textView.string.count + delta <= 4000
        if !result {
            showAlert()
        }
        
        return result
    }
}

extension TaskDocumentView: TaskTextStorageDelegate {
    
    func taskTextStorage(insert tasks: [Task]) {
        print(tasks)
        taskStorage.insert(tasks)
    }
    
    func taskTextStorage(remove tasks: [Task]) {
        print(tasks)
        taskStorage.remove(tasks)
    }
}

extension TaskDocumentView: RefreshableScrollViewDelegate {
    
    func willStartUpdate() {
        /*
        self.isRefreshing = true
        let operation2 = TextOperation(storage: taskStorage.storage)
        operation2.grouping = grouping
        //operation2.addDependency(operation)
        operation2.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                let text = operation2.string
                self?.textView.set(text: text)
            }
            
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            operation2.start()
        }
 */
    }
    
}
