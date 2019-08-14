//
//  TaskDetailViewController.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/11/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {

    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var prioritySegementedControl: UISegmentedControl!
    
    var task: Task? {
        didSet {
            self.updateViews()
        }
    }
    
    var taskController: TaskController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateViews()
        self.nameTextField.addTarget(self, action: #selector(toggleSaveButton), for: .editingChanged)
    }
    
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard let taskName = self.nameTextField.text,
            !taskName.isEmpty else {return}
        
        let priorityIndex = prioritySegementedControl.selectedSegmentIndex
        let priority = TaskPriority.allPriorities[priorityIndex] //same order as segmentedControl
        
        let notes = self.notesTextView.text
        
        if let task = self.task {
            //Edit existing task
            task.name = taskName
            task.priority = priority.rawValue
            task.notes = notes
            taskController.put(task: task)
        } else {
            let newTask = Task(name: taskName, notes: notes, priority: priority) // create new task using Task
            taskController.put(task: newTask)
        }
        
        //save - basic persistence - relaunching the app datas are still there
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    private func updateViews() {
        guard isViewLoaded else {return}
        
        let priority: TaskPriority
        if let taskPriority = task?.priority {
            priority = TaskPriority(rawValue: taskPriority)!
        } else {
            priority = .normal
        }
        
        prioritySegementedControl.selectedSegmentIndex = TaskPriority.allPriorities.firstIndex(of: priority)!
        
        
        self.title = self.task?.name ?? "Create Task"
        self.nameTextField.text = task?.name
        self.notesTextView.text = task?.notes
    }
    
    @objc private func toggleSaveButton() {
        self.saveButton.isEnabled = !self.nameTextField.text!.isEmpty  //if textfield is not empty saveButton isEnabled
    }
}
