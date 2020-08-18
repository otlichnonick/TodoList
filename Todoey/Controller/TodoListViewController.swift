//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    var itemArray = [Item]()
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    //создаем массив элементов для хранения пользовательских типов данных (не UserDefault)
    //let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    // создаем синглтон AppDelegate для использования в сохранении и чтении данных[ при использовании CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    //хранилище маленьких данных пользователя используя UserDefault
    //let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //загружаем массив с сохраненными новыми элементами
        //        if let items = defaults.array(forKey: "toDoListArray") as? [Item] {
        //            itemArray = items
        //        }
        
        // print(dataFilePath)
        
        loadItems()
        
        //print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    //MARK: - TableView DataSourse Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = itemArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        cell.textLabel?.text = item.title
        
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add new item to ToDoList", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add item", style: .default) { (action) in
            
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            self.itemArray.append(newItem)
            
            //при добавлении в массив сохраняем новые элементы в хранилище
            //self.defaults.set(self.itemArray, forKey: "toDoListArray")
            
            self.saveItems()
            
        }
        
        alert.addTextField { (allertTextField) in
            allertTextField.placeholder = "add new item"
            textField = allertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Model manipulation methods
    
    func saveItems() {
        
        do {
            try context.save()
        } catch {
            print("Error saving  context \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        //фильтруем по выбранной категории
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        //фильтруем по допфильтру если он есть в UISearchBar
        if let additionalPredicate = predicate {
            //если есть, то фильтруем по нескольким предикатам
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            //если нет, то только по выбранной категории
            request.predicate = categoryPredicate
        }
                
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        tableView.reloadData()
    }
}

//MARK: - UISearchBarDelegate methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // считываем данные из базы данных
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        // создаю сортировку и получаю отсортированные данные
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        // создаю сортировку и сортирую полученные данные по алфавиту
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            
        }
    }
}



