//
//  ViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import UIKit

var ingredients: [HomeIngredient] = []

class HomeViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let defaults = UserDefaults.standard
    var filteredIngredients: [HomeIngredient]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.scopeButtonTitles = ["Pantry", "Store"]
        
        self.clearsSelectionOnViewWillAppear = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(removeAllIngredients))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.red
        
        if let savedIngredients = defaults.object(forKey: "savedIngredients") {
            // Type cast object of type Any
            ingredients = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedIngredients as! Data) as! [HomeIngredient]
        }
        
        filteredIngredients = ingredients
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !UserDefaults.standard.bool(forKey: "tutorialCompleted") {
            showTutorial()
        }
        
        // Check whether each element in detectedIngredients is already in ingredients
        var elementsToDelete: [HomeIngredient] = []
        for count in 0..<detectedIngredients.count {
            if checkRepeatedIngredient(detectedIngredients[count]) == true {
                elementsToDelete.append(detectedIngredients[count])
            }
        }
        for element in elementsToDelete {
            detectedIngredients.removeAll(where: { $0 == element })
        }
        // Create an array of index paths and append to ingredients so that each new element can be added to the table view
        if detectedIngredients.count > 0 {
            var indexPaths: [IndexPath] = []
            
            for count in 0..<detectedIngredients.count {
                indexPaths.append(IndexPath(row: ingredients.count, section: 0))
                ingredients.append(detectedIngredients[count])
            }
            
            // Update all relevant data structures
            detectedIngredients = []
            self.filteredIngredients = ingredients
            
            // Convert type [SelectedRecipe] to type NSData
            if let convertedIngredients = try? NSKeyedArchiver.archivedData(withRootObject: ingredients, requiringSecureCoding: false) {
                defaults.set(convertedIngredients, forKey: "savedIngredients")
            }
            
            self.tableView.insertRows(at: indexPaths, with: .fade)
        }
        
        setStateOfBarButtonItems()
    }
    
    func showTutorial() {
        if let tutorialVC = storyboard!.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
            tutorialVC.modalPresentationStyle = .popover
            present(tutorialVC, animated: true, completion: nil)
        }
    }
    
    func setStateOfBarButtonItems() {
        // Disable bar buttons when there are no ingredients
        if ingredients.count == 0 {
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func checkRepeatedIngredient(_ response: HomeIngredient) -> Bool {
        for ingredient in ingredients {
            if ingredient.name.lowercased() == response.name.lowercased() {
                return true
            }
        }
        return false
    }
    
    // Set filtered ingredients to ingredients when search bar is empty and filter based on whether the element contains the search text. Then reload the table view to update the cells to only display the filtered elements
    func filterIngredients(_ searchText: String) {
        if searchText == "" {
            filteredIngredients = ingredients
            setStateOfBarButtonItems()
        } else {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            
            for ingredient in ingredients {
                if ingredient.name.lowercased().contains(searchText.lowercased()) {
                    filteredIngredients.append(ingredient)
                }
            }
        }
        self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func getIngredientNames() -> [String] {
        var ingredientNames: [String] = []
        for ingredient in ingredients {
            ingredientNames.append(ingredient.name)
        }
        return ingredientNames
    }
    
    @objc func removeAllIngredients() {
        let alert = UIAlertController(title: "Remove All Ingredients", message: "Are you sure you want to remove all your ingredients?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { (_) in
            // Update all relevant data structures
            ingredients = []
            self.filteredIngredients = ingredients
            
            // Convert type [SelectedRecipe] to type NSData
            if let convertedIngredients = try? NSKeyedArchiver.archivedData(withRootObject: ingredients, requiringSecureCoding: false) {
                self.defaults.set(convertedIngredients, forKey: "savedIngredients")
            }
            
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            self.setStateOfBarButtonItems()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Table View Config

    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        return filteredIngredients.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Type cast each instance of UICollectionViewCell as RecipeCell.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Ingredient", for: indexPath) as? IngredientCell else {
            fatalError("Unable to dequeue a IngredientCell.")
        }
        
        // Configure the cell...
        let selectedIngredient = filteredIngredients[indexPath.row]
        cell.ingredientLabel?.textColor = UIColor.white
        cell.ingredientLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        if getIngredientNames().contains(selectedIngredient.name) == false {
            cell.backgroundColor = UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1))
        } else {
            cell.backgroundColor = UIColor.init(cgColor: CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1))
        }
        cell.ingredientLabel?.text = selectedIngredient.name
        cell.ingredientImage?.load(url: URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(selectedIngredient.imageDirectory)") ?? URL(string: "https://spoonacular.com/cdn/ingredients_100x100.jpg")!)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Prevent swiping to delete when searching ingredients
        if self.navigationItem.rightBarButtonItem!.isEnabled == false {
            return false
        } else {
            return true
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            ingredients.remove(at: indexPath.row)
            self.filteredIngredients = ingredients
            
            // Convert type [SelectedRecipe] to type NSData
            if let convertedIngredients = try? NSKeyedArchiver.archivedData(withRootObject: ingredients, requiringSecureCoding: false) {
                defaults.set(convertedIngredients, forKey: "savedIngredients")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            setStateOfBarButtonItems()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if getIngredientNames().contains(filteredIngredients[indexPath.row].name) == false {
            // Reset views
            view.endEditing(true)
            searchBar.text = ""
            
            // Add and store ingredient and display the ingredients before the addition
            ingredients.append(filteredIngredients[indexPath.row])
            
            // Convert type [SelectedRecipe] to type NSData
            if let convertedIngredients = try? NSKeyedArchiver.archivedData(withRootObject: ingredients, requiringSecureCoding: false) {
                defaults.set(convertedIngredients, forKey: "savedIngredients")
            }
            
            filteredIngredients = ingredients
            filteredIngredients.removeLast()
            self.tableView.reloadData()
            setStateOfBarButtonItems()
            
            // Animate new ingredient into table view
            let indexPath = IndexPath(row: filteredIngredients.count, section: 0)
            filteredIngredients = ingredients
            self.tableView.insertRows(at: [indexPath], with: .fade)
        } else {
            tableView.cellForRow(at: indexPath)?.isSelected = false
        }
    }
    
    //MARK: Search Bar Config
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.searchBar(self.searchBar, textDidChange: searchBar.text ?? "")
    }
    
    // Determine whether to filter ingredients or find autocompletes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredIngredients = []
        if searchBar.selectedScopeButtonIndex == 0 {
            filterIngredients(searchText)
        } else {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.isEditing = false
            
            // Get autocomplete ingredients
            AutocompleteIngredientsAdaptor().getAutocompleteIngredients(searchBar.text ?? "") { (autocompleteIngredients, error) in
                // If no internet connection or unable to parse JSON
                if error == false {
                    self.filteredIngredients = []
                    for ingredient in autocompleteIngredients ?? [] {
                        self.filteredIngredients.append(HomeIngredient(name: ingredient.name, imageDirectory: ingredient.image))
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                }
            }
        }
    }
    
    // Show cancel and scope views
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.setShowsScope(true, animated: true)
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
        if searchBar.selectedScopeButtonIndex == 1 {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.searchBar(self.searchBar, textDidChange: searchBar.text ?? "")
        }
    }
    
    // Hide cancel and scope views
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.setShowsScope(false, animated: true)
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
    }
    
    // Hide keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    // Hide keyboard and reset views
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        searchBar.text = ""
        filteredIngredients = ingredients
        setStateOfBarButtonItems()
        self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
}
