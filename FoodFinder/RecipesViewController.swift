//
//  RecipesViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import UIKit

class RecipesViewController: UICollectionViewController, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    
    let recipeAdaptor = RecipeAdaptor()
    var recipes: [Recipe] = []
    var latestIngredients: [String] = ingredients

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Button Setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass.circle"), style: .plain, target: self, action: #selector(animateViews))
        
        // Search Bar Setup
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.isHidden = true

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
            recipeAdaptor.getRecipes(searchTerm) { (recipes, error) in
                // If no internet connection or unable to parse JSON
                if error == true {
                    // UI changes done on main thread
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.title = "No Connection"
                    }
                } else if recipes == nil && error == false {
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
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "No Ingredients")
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            // Remove all recipes and refresh data
            self.recipes.removeAll()
            collectionView.reloadData()
        }
    }
    
    // Check if latest query used current ingredients
    override func viewDidAppear(_ animated: Bool) {
        if latestIngredients != ingredients {
            viewDidLoad()
        }
    }
    
    @objc func animateViews() {
        if navigationItem.leftBarButtonItem?.image == UIImage(systemName: "magnifyingglass.circle.fill") {
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "magnifyingglass.circle")
            searchBar.isHidden = true
            for cell in collectionView.visibleCells {
                cell.isHidden = false
            }
            collectionView.isScrollEnabled = true
        } else {
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "magnifyingglass.circle.fill")
            searchBar.isHidden = false
            for cell in collectionView.visibleCells {
                cell.isHidden = true
            }
            collectionView.isScrollEnabled = false
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
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    //MARK: Search Bar Config
    
    // Determine whether to filter ingredients or find autocompletes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    // Show cancel and scope views
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.sizeToFit()
    }
    
    // Hide cancel and scope views
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.sizeToFit()
    }
    
    // Hide keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        searchBar.text = ""
    }
    
    // Hide keyboard and reset views
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        searchBar.text = ""
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
