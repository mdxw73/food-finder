//
//  RecipesViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import UIKit

class RecipesViewController: UICollectionViewController, UISearchBarDelegate {
    
    let recipeAdaptor = RecipeAdaptor()
    var recipes: [Recipe] = []
    var latestIngredients: [HomeIngredient] = ingredients

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Button Setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(displayComplexSearchAlert))

        // Generate search term and completion handler to send to instance of RecipeAdaptor.
        if ingredients.count > 0 {
            // Set up loading text in navigation bar
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Loading...")
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            // Convert ingredients array into string separated by ,+ to conform to API syntax
            var searchTerm = "\(ingredients[0])"
            for count in 1 ..< ingredients.count {
                searchTerm += ",+\(ingredients[count])"
            }
            recipeAdaptor.getRecipes(searchTerm, directory: "findByIngredients?ingredients=") { (recipes, error) in
                // If no internet connection or unable to parse JSON
                if error == true {
                    // UI changes done on main thread
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.title = "No Connection"
                    }
                } else if recipes == nil && error == false {
                    // Run out of API queries
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.title = "Error"
                        // Instantiate alert
                        let alert = UIAlertController(title: "Error Message", message: "We have run into a server-side problem. We aim to fix this as soon as possible; however, the app will be fully functioning from tomorrow morning, sorry for the inconvenience.", preferredStyle: .alert)
                        // Add a button below the text field
                        alert.addAction(UIAlertAction(title: "Close", style: .default))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    self.recipes = recipes ?? [] // Create an array from the attribute strMeal of all returned recipes
                    
                    // Update latest queried ingredients
                    self.latestIngredients = ingredients
                    
                    // UI change must be done on main thread
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        
                        // Check if no recipes found
                        if self.recipes.count == 0 {
                            self.navigationItem.rightBarButtonItem?.title = "No Recipes"
                        } else {
                            self.navigationItem.rightBarButtonItem = nil
                        }
                    }
                }
            }
        } else {
            // Set up no ingredients text in navigation bar
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Empty")
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            // Remove all recipes and refresh data
            self.recipes.removeAll()
            collectionView.reloadData()
        }
    }
    
    // Check if latest query used current ingredients
    override func viewDidAppear(_ animated: Bool) {
        var change = false
        if latestIngredients.count != ingredients.count {
            change = true
        } else {
            for count in 0..<favouriteRecipes.count {
                if latestIngredients[count].name != ingredients[count].name {
                    change = true
                }
            }
        }
        if change == true {
            viewDidLoad()
        }
    }
    
    @objc func displayComplexSearchAlert() {
        let alert = UIAlertController(title: "Complex Recipe Search", message: "Enter a meal name, style or genre.", preferredStyle: .alert)
        // Add a text field
        alert.addTextField(configurationHandler: { textField in
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .yes
            })
        // Add a button below the text field
        alert.addAction(UIAlertAction(title: "Search", style: .default, handler: { (_) in
            let textField = alert.textFields![0]
            let response = textField.text ?? ""
            
            // Check if ingredient already exists
            if response != "" {
                self.searchButtonPressed(response)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Search API with search bar text
    func searchButtonPressed(_ searchTerm: String) {
        recipeAdaptor.getRecipes(searchTerm, directory: "complexSearch?query=") { (recipes, error) in
            // If no internet connection or unable to parse JSON
            if error == true {
                // UI changes done on main thread
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.title = "No Connection"
                }
            } else if recipes == nil && error == false {
                // Run out of API queries
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.title = "Error"
                    // Instantiate alert
                    let alert = UIAlertController(title: "Error Message", message: "We have run into a server-side problem. We aim to fix this as soon as possible; however, the app will be fully functioning from tomorrow morning, sorry for the inconvenience.", preferredStyle: .alert)
                    // Add a button below the text field
                    alert.addAction(UIAlertAction(title: "Close", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    // UI change must be done on main thread
                    guard let viewController = self.storyboard?.instantiateViewController(identifier: "SearchedRecipesViewController") as? SearchedRecipesViewController else {
                        fatalError("Unable to load RecipesViewController from storyboard")
                    }
                    viewController.recipes = recipes ?? [] // Create an array from the attribute strMeal of all returned recipes
                    
                    // Check if no recipes found
                    if viewController.recipes.count == 0 {
                        viewController.navigationItem.rightBarButtonItem?.title = "No Recipes"
                    } else {
                        viewController.navigationItem.rightBarButtonItem = nil
                    }
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
    }
    
    //MARK: Collection View Config
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Type cast each instance of UICollectionViewCell as RecipeCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Recipe", for: indexPath) as? RecipeCell else {
            fatalError("Unable to dequeue a RecipeCell.")
        }
        
        let recipe = recipes[indexPath.item]
        
        // Edit UILabel
        cell.mealName.text = recipe.mealName
        cell.mealName.adjustsFontSizeToFitWidth = true
        
        // Edit UIImage
        cell.imageView.load(url: recipe.mealImage)
        cell.imageView.layer.cornerRadius = 10
        
        // Customize cell
        cell.layer.cornerRadius = 10
        cell.clipsToBounds = true
        
        // Add shadows
        cell.layer.borderWidth = 0.0
        cell.layer.shadowColor = UIColor.darkGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.layer.shadowRadius = 5.0
        cell.layer.shadowOpacity = 1
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    // Instantiate a selected recipe and pass in the meal id
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = storyboard?.instantiateViewController(identifier: "SelectedRecipeViewController") as? SelectedRecipeViewController else {
            fatalError("Failed to load Selected Recipe View Controller from Storyboard")
        }
        viewController.mealId = self.recipes[indexPath.item].mealId
        viewController.similarRecipes = recipes.filter({$0.mealId != viewController.mealId})
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension RecipesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width/2-17, height: view.frame.width/2.25)
    }
}
