//
//  ViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import UIKit

var ingredients: [String] = []

class HomeViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    let defaults = UserDefaults.standard
    var filteredIngredients: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.scopeButtonTitles = ["Pantry", "Store"]
        
        self.clearsSelectionOnViewWillAppear = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addIngredient))
        
        // If there are ingredients saved in the defaults database, copy them across
        if let savedIngredients = defaults.stringArray(forKey: "savedIngredients") {
            ingredients = savedIngredients
        }
        
        filteredIngredients = ingredients
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Check whether each element in detectedIngredients is already in ingredients
        var elementsToDelete: [String] = []
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
            self.defaults.set(ingredients, forKey: "savedIngredients")
            self.tableView.insertRows(at: indexPaths, with: .fade)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        searchBarCancelButtonClicked(searchBar)
    }
    
    func checkRepeatedIngredient(_ response: String) -> Bool {
        for ingredient in ingredients {
            if ingredient.lowercased() == response.lowercased() {
                return true
            }
        }
        return false
    }
    
    // @objc makes the code within the method available to Objective C code, which is run at runtime, as well as Swift code
    // Generates alert and appends input to ingredients array before reloading the data
    @objc func addIngredient() {
        displayIngredientAlert(textFieldText: "", title: "Quick Add", message: "Enter Ingredient")
    }
    
    func displayIngredientAlert(textFieldText: String, title: String, message: String) {
        // Instantiate alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // Add a text field
        alert.addTextField(configurationHandler: { textField in
            textField.text = textFieldText
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .yes
            })
        // Add a button below the text field and create a closure to be executed when the button is pressed
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (_) in
            let textField = alert.textFields![0]
            let response = textField.text ?? ""
            
            // Check if ingredient already exists
            if response != "" && self.checkRepeatedIngredient(response) == false {
                let indexPath = IndexPath(row: ingredients.count, section: 0)
                
                ingredients.append(response)
                self.filteredIngredients = ingredients
                self.defaults.set(ingredients, forKey: "savedIngredients")
                self.tableView.insertRows(at: [indexPath], with: .fade)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Set filtered ingredients to ingredients when search bar is empty and filter based on whether the element contains the search text. Then reload the table view to update the cells to only display the filtered elements
    func filterIngredients(_ searchText: String) {
        if searchText == "" {
            filteredIngredients = ingredients
            self.navigationItem.rightBarButtonItem!.isEnabled = true
            self.navigationItem.leftBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            
            for ingredient in ingredients {
                if ingredient.lowercased().contains(searchText.lowercased()) {
                    filteredIngredients.append(ingredient)
                }
            }
        }
        tableView.reloadData()
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
        if ingredients.contains(selectedIngredient) == false {
            cell.ingredientLabel?.textColor = UIColor.systemPink
            cell.ingredientLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        } else {
            cell.ingredientLabel?.textColor = UIColor.black
            cell.ingredientLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        }
        cell.ingredientLabel?.text = selectedIngredient
        cell.ingredientImage?.load(url: URL(string: "https://spoonacular.com/cdn/ingredients_100x100/\(selectedIngredient.replacingOccurrences(of: " ", with: "+")).jpg") ?? URL(string: "https://spoonacular.com/cdn/ingredients_100x100.jpg")!)
        
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
            self.defaults.set(ingredients, forKey: "savedIngredients")
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ingredients.contains(filteredIngredients[indexPath.row]) == false {
            // Reset views
            view.endEditing(true)
            searchBar.text = ""
            searchBar.selectedScopeButtonIndex = 0
            navigationItem.rightBarButtonItem!.isEnabled = true
            navigationItem.leftBarButtonItem?.isEnabled = true
            
            // Add and store ingredient and display the ingredients before the addition
            ingredients.append(filteredIngredients[indexPath.row])
            self.defaults.set(ingredients, forKey: "savedIngredients")
            filteredIngredients = ingredients
            filteredIngredients.removeLast()
            tableView.reloadData()
            
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
            
            // Get autocomplete ingredients
            AutocompleteIngredientsAdaptor().getAutocompleteIngredients(searchBar.text ?? "") { (autocompleteIngredients, error) in
                // If no internet connection or unable to parse JSON
                if error == false {
                    self.filteredIngredients = []
                    for ingredient in autocompleteIngredients ?? [] {
                        self.filteredIngredients.append(ingredient.name)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
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
        searchBar.selectedScopeButtonIndex = 0
        filteredIngredients = ingredients
        navigationItem.rightBarButtonItem!.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = true
        tableView.reloadData()
    }
    
}
