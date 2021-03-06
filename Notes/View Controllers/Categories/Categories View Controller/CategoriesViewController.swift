//
//  CategoriesViewController.swift
//  Notes
//
//  Created by Виктория Бадисова on 19.06.2018.
//  Copyright © 2018 Виктория Бадисова. All rights reserved.
//

import UIKit
import CoreData

class CategoriesViewController: UIViewController {
    
    //MARK: - Segues
    
    private enum Segue {
        static let AddCategory = "AddCategory"
        static let Category = "Category"
    }
    
    //MARK: - Properties
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    //MARK: -
    
    var note: Note?
    
    //MARK: -
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Category> = {
        guard let managedObjectContext = self.note?.managedObjectContext else {
            fatalError("No managed object context found")
        }
        
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Category.name), ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    //MARK: -
    
    private var hasCategories: Bool {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else { return false }
        return fetchedObjects.count > 0
    }
    
    //MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Categories"
        
        setupView()
        fetchCategories()
        updateView()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case Segue.AddCategory:
            guard let destination = segue.destination as? AddCategoryViewController else { return }
            destination.managedObjectContext = note?.managedObjectContext
        case Segue.Category:
            guard let destination = segue.destination as? CategoryViewController else { return }
            guard let cell = sender as? CategoryTableViewCell else { return }
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            let category = fetchedResultsController.object(at: indexPath)
            destination.category = category
        default:
            fatalError("Unexpected segue identifier")
        }
    }
    
    //MARK: - View methods
    
    private func setupView() {
        setupMesageLabel()
        setupBarButtonItems()
    }
    private func updateView() {
        tableView.isHidden = !hasCategories
        messageLabel.isHidden = hasCategories
    }
    
    private func setupMesageLabel() {
        messageLabel.text = "You don't have any categories yet"
    }
    
    private func setupBarButtonItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
    }
    
    //MARK: - Actions
    
    @objc private func add(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Segue.AddCategory, sender: self)
    }
    
    //MARK: - Fetching
    
    private func fetchCategories() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Unable to perform fetch")
            print("\(error): \(error.localizedDescription)")
        }
    }
    
    //MARK: - Helper methods
    
    private func configure(_ cell: CategoryTableViewCell, at indexPath: IndexPath) {
        let category = fetchedResultsController.object(at: indexPath)
        
        cell.nameLabel.text = category.name
        
        if note?.category == category {
            cell.nameLabel.textColor = .bitterSweet
        } else {
            cell.nameLabel.textColor = .black
        }
    }
    
}

//MARK: - UITableViewDataSource methods

extension CategoriesViewController: UITableViewDataSource  {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else { return 0 }
        return section.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reuseIdentifier, for: indexPath) as? CategoryTableViewCell else {
            fatalError("Unexpected index path")
        }
        
        configure(cell, at: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let category = fetchedResultsController.object(at: indexPath)
        
        note?.managedObjectContext?.delete(category)
    }
    
}

//MARK: - UITableViewDelegate methods

extension CategoriesViewController: UITableViewDelegate  {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = fetchedResultsController.object(at: indexPath)
        
        note?.category = category
        
        let _ = navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - NSFetchedResultsControllerDelegate methods

extension CategoriesViewController: NSFetchedResultsControllerDelegate  {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateView()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? CategoryTableViewCell {
                configure(cell, at: indexPath)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
    }

}
