//
//  TextViewController.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TextOperation: Operation {
    
    var storage: NSMutableArray = NSMutableArray(array: [Task]())
    var string: String = ""
    var grouping: Grouping = .commonDateStyle
    
    init(storage: NSMutableArray) {
        self.storage = storage
    }
    
    override func main() {
        sleep(3)
        let badgeFilter = Preferences.shared.badgeFilter
        
        
        
        let array = storage.compactMap { (element) -> Task? in
            return element as? Task
        }
        
        let dictionary = Dictionary(grouping: array) { (element) -> Group in
            if element.isCompleted { return .completion(value: true) }
            if let filter = badgeFilter, filter.evaluate(with: element) { return .pinned }
            return grouping.group(for: element)
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key.priority < rhs.key.priority
        }
        
        let mutableStr = NSMutableString()
        
        for (section, tasks) in data {
            mutableStr.append("-------- \(section.title) --------\n")
            for task in tasks {
                mutableStr.append("\(task.string)\n")
            }
        }
        
        self.string = mutableStr.string
    }
}

class TextViewController: NSViewController, RefreshableScrollViewDelegate {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var infoTextField: InfoTextField!
    @IBOutlet weak var scrollView: RefreshableScrollView!
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    var currentWorkItem: DispatchWorkItem?
    
    var grouping: Grouping = .commonDateStyle
    var isRefreshing: Bool = false
    var backingStore: Storage = Storage()
    
    // VIEWS
    @IBOutlet weak var contentView: BackgroundView!
    @IBOutlet weak var textview: TextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        print(#function)
        
        scrollView.delegate = self
        
        // ---------- info textfield ----------
        //let charactersLimit = backingStore?.CHARACTERS_LIMIT ?? 0
        //let tasksLimit = backingStore?.TASKS_LIMIT ?? 0
        infoTextField.charactersLimit = 4000
        infoTextField.tasksLimit = 150
        
        textview.textContainer?.replaceLayoutManager(LayoutManager())
        
        // ---------- text storage ----------
        let textStorage = TextStorage()
        textStorage.delegate = self
        textStorage.dataDelegate = self
        textview.textContainer?.layoutManager?.replaceTextStorage(textStorage)
        
        // ---------- textview configuration ----------
        textview.completionDelegate = self
        textview.delegate = self
        textview.allowsUndo = true
        
        textview.layoutManager?.allowsNonContiguousLayout = false
        
        textview.setUpLineNumberView()
        textview.insertionPointColor = NSColor.alert
        
        let font = NSFont(name: "Menlo", size: 13.0)
        textview.font = font
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.paragraphSpacing = 6.0
        paragraphStyle.lineHeightMultiple = 1.1
        //textview.defaultParagraphStyle = paragraphStyle
        textview.typingAttributes = [.font : font as Any, .paragraphStyle: paragraphStyle]
        
        // ---------- other views configuration ----------
        contentView.backgroundColor = theme.background
        
        invalidateTheme()
        
        //scrollView.contentView.postsBoundsChangedNotifications = true
        
        // ---------- setup notifications ----------
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange(_:)), name: .appearanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload(_:)), name: .badgeFilterDidChange, object: nil)
        
    }
    
    func startResfresh() {
        print(#function)
        guard isRefreshing == false else { return }
        isRefreshing = true
        textview.isEditable = false
        progressIndicator.startAnimation(self)
        let operation = TextOperation(storage: backingStore.storage)
        operation.grouping = grouping
        operation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                print("complete")
                self?.textview.isEditable = true
                self?.progressIndicator.stopAnimation(self)
                let newStr = operation.string
                self?.textview.reload(with: newStr)
                self?.isRefreshing = false
            }
        }
        let operationQueue = OperationQueue()
        operationQueue.isSuspended = true
        operationQueue.addOperation(operation)
        operationQueue.isSuspended = false
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @IBAction func sort(_ sender: NSMenuItem) {
        
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
        
        reload(self)
    }
   
    // ******** Reloading ********
    
    func reload(data: Data) throws {
        try backingStore.reload(data)
        reload(self)
    }
    
    @objc func reload(_ sender: Any?) {
        print(#function)
        guard isRefreshing == false else { return }
        isRefreshing = true
        textview.isEditable = false
        progressIndicator.startAnimation(self)
        let operation = TextOperation(storage: backingStore.storage)
        operation.grouping = grouping
        operation.completionBlock = {
            DispatchQueue.main.async { [weak self] in
                print("complete")
                self?.textview.isEditable = true
                self?.progressIndicator.stopAnimation(self)
                let newStr = operation.string
                self?.textview.reload(with: newStr)
                self?.isRefreshing = false
            }
        }
        let operationQueue = OperationQueue()
        operationQueue.isSuspended = true
        operationQueue.addOperation(operation)
        operationQueue.isSuspended = false
    }
    
    private func updateInfo() {
        
        let tasksCount = backingStore.storage.count ?? 0
        let charactersCount = textview.string.count 
        infoTextField.setValues(tasksCount: tasksCount, charactersCount: charactersCount)
    }
    
    private func showAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Delete completed")
        alert.informativeText = "The file is big. Please, split it for any more small or delete completed tasks"
        
        alert.beginSheetModal(for: view.window!) { (response) in
            switch response {
            case .alertFirstButtonReturn:
                print("OK")
            case .alertSecondButtonReturn:
                self.textview.removeCompleted(self)
            default:
                break
            }
        }
    }

    
    private func invalidateTheme() {
        contentView.backgroundColor = theme.background
        textview.invalidateColorScheme()
        infoTextField.foregroundColor = theme.foreground
    }
    
    @objc func themeDidChange(_ notification: Notification) {
        print(#function)
        invalidateTheme()
    }
    
    @objc func appearanceDidChange(_ notification: Notification) {
        print(#function)
        invalidateTheme()
    }
    
    override func viewDidDisappear() {
        print(#function)
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension TextViewController: NSTextViewDelegate {
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

extension TextViewController: TextStorageDataDelegate {
    func dataDidChanged(toInsert: [Task], toDelete: [Task]) {
        backingStore.performOperation(inserted: toInsert, removed: toDelete)
    }
   
}

extension TextViewController: AutoCompletionDelegate {
    func complete(element: Element) -> [String] {
        return backingStore.mentions(for: element) ?? []
    }
    
}

extension TextViewController: NSTextStorageDelegate {
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let textStorage = textview.textStorage as? TextStorage else { return }
        if textStorage.observeChanging {
            document.updateChangeCount(.changeDone)
            updateInfo()
        }
        if let rulerView = textview.enclosingScrollView?.verticalRulerView as? RulerView {
            rulerView.invalidateMarks()
        }
        
    }
    
}
