//
//  TaskTableViewController.swift
//  coreDataBasic
//
//  Created by Dongwoo Pae on 8/11/19.
//  Copyright © 2019 Dongwoo Pae. All rights reserved.
//

import UIKit
import CoreData

class TaskTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBAction func refreshControl(_ sender: Any) {
        self.taskController.fetchTaskFromServer { (_) in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    //MARK: - Properties
    // this is not a good efficient way to do fetching
    // will be excuted every time tasks property is accessed.
    // computed property for our task
    //    var tasks: [Task] {
    //        let fetchRequest : NSFetchRequest<Task> = Task.fetchRequest()
    //        let moc = CoreDataStack.shared.mainContext
    //
    //        do {
    //            return try moc.fetch(fetchRequest)
    //        } catch {
    //            NSLog("Error fetching tasks: \(error)")
    //            return []
    //        }
    //    }
    
    // NSFetchResults controller - fetching datas from CoreData - from save Datas
    lazy var fetchedResultsController: NSFetchedResultsController<Task> = {   //name of Entity not the version name or file name
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "priority", cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
        
        // add NSFetchResulsControllerDelegate
    }()
    
    
    private let taskController = TaskController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = self.fetchedResultsController.sections?[section] else {return nil}
        return sectionInfo.name.capitalized
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        
        let task = self.fetchedResultsController.object(at: indexPath) //
        
        cell.textLabel?.text = task.name
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = self.fetchedResultsController.object(at: indexPath)
            
            //delete data in server first and coreData
            taskController.deleteTaskFromServer(task) { (error) in
                if let error = error {
                    NSLog("Error deleting task from server: \(error)")
                    return
                }
                let moc = CoreDataStack.shared.mainContext
                moc.performAndWait {
                    moc.delete(task)
                    
                    do {
                        try moc.save()
                        self.tableView.reloadData()
                    } catch {
                        moc.reset()
                        NSLog("Error saving managed object context: \(error)")
                    }
                }
            }
            
        }
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            guard let destVC = segue.destination as? TaskDetailViewController,
                let selectedRow = self.tableView.indexPathForSelectedRow else {return}
            destVC.task = self.fetchedResultsController.object(at: selectedRow)
            destVC.taskController = self.taskController
        } else if segue.identifier == "ShowCreateTask" {
            guard let destVC = segue.destination as? TaskDetailViewController else {return}
            destVC.taskController = self.taskController
        }
    }
    
    //MARK: - NSfetchresultcontrollerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    
    //Sections
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    //Rows
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else {return}
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default:
            break
        }
    }
}
