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
        
        checkSubscription()
        
        // Search button setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(displayComplexSearchAlert))
        
        // Refresh button setup
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refresh))

        // Generate search term and completion handler to send to instance of RecipeAdaptor.
        if ingredients.count > 0 {
            let searchTerm = getSearchTerm()
            queryApi(searchTerm)
        } else {
            displayAlert(title: "No Ingredients", message: "To find recipes by ingredients, return to the home tab and add some using the search bar.")
            latestIngredients = ingredients
        }
    }
    
    // Check if latest query used current ingredients
    override func viewDidAppear(_ animated: Bool) {
        var change = false
        if latestIngredients.count != ingredients.count {
            change = true
        } else {
            for count in 0..<ingredients.count {
                if latestIngredients[count].name != ingredients[count].name {
                    change = true
                }
            }
        }
        if change == true {
            viewDidLoad()
        }
    }
    
    @objc func refresh() {
        viewDidLoad()
    }
    
    func getSearchTerm() -> String {
        // Convert ingredients array into string separated by ,+ to conform to API syntax
        var searchTerm = "\(ingredients[0].name)"
        for count in 1 ..< ingredients.count {
            searchTerm += ",+\(ingredients[count].name)"
        }
        return searchTerm
    }
    
    func generateLoadingIcon() {
        let loadingButton = UIButton() // Create new button
        loadingButton.setImage(UIImage(systemName: "circle.grid.cross.fill"), for: .normal) // Assign an image
        loadingButton.imageView?.tintColor = UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        navigationItem.rightBarButtonItem?.customView = loadingButton // Set as barButton's customView
        UIView.animate(withDuration: 1, delay: 0, options: .repeat, animations: {
            self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransform(rotationAngle: .pi)
                }, completion: nil)
    }
    
    func queryApi(_ searchTerm: String) {
        generateLoadingIcon()
        recipeAdaptor.getRecipes(searchTerm, directory: "findByIngredients?ingredients=") { (recipes, error) in
            // Update latest queried ingredients
            self.latestIngredients = ingredients
            
            // If no internet connection or unable to parse JSON
            if error == true {
                // UI changes done on main thread
                DispatchQueue.main.async {
                    self.displayAlert(title: "No Connection", message: "Please check your network connection.")
                }
            } else if recipes == nil && error == false {
                // Run out of API queries
                DispatchQueue.main.async {
                    self.displayAlert(title: "Error Message", message: "We have run into a server-side problem. We aim to fix this as soon as possible. Sorry for the inconvenience.")
                }
            } else {
                self.recipes = recipes ?? [] // Create an array from the attribute strMeal of all returned recipes
                
                // UI change must be done on main thread
                DispatchQueue.main.async {
                    // Check if no recipes found
                    if self.recipes.count == 0 {
                        self.displayAlert(title: "No Recipes", message: "We couldn't find any recipes for the ingredients in your home tab.")
                    } else {
                        self.collectionView.reloadData()
                    }
                }
            }
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(self.refresh))
            }
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.applyCustomStyle()
        // Add a button below the text field
        let closeAction = UIAlertAction(title: "Close", style: .default)
        closeAction.setValue(UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)), forKey: "titleTextColor")
        alert.addAction(closeAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func displayComplexSearchAlert() {
        let alert = UIAlertController(title: "Complex Recipe Search", message: "Enter a meal name, style or genre.", preferredStyle: .alert)
        alert.applyCustomStyle()
        // Add a text field
        alert.addTextField(configurationHandler: { textField in
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .yes
            textField.placeholder = "Search"
            })
        // Add a button below the text field
        let searchAction = UIAlertAction(title: "Search", style: .default, handler: { (_) in
            let textField = alert.textFields![0]
            let response = textField.text ?? ""
            
            // Check if ingredient already exists
            if response != "" {
                self.searchButtonPressed(response)
            }
        })
        searchAction.setValue(UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)), forKey: "titleTextColor")
        alert.addAction(searchAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)), forKey: "titleTextColor")
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Search API with search bar text
    func searchButtonPressed(_ searchTerm: String) {
        generateLoadingIcon()
        recipeAdaptor.getRecipes(searchTerm, directory: "complexSearch?query=") { (recipes, error) in
            // If no internet connection or unable to parse JSON
            if error == true {
                // UI changes done on main thread
                DispatchQueue.main.async {
                    self.displayAlert(title: "No Connection", message: "Please check your network connection.")
                }
            } else if recipes == nil && error == false {
                // Run out of API queries
                DispatchQueue.main.async {
                    self.displayAlert(title: "Error", message: "We have run into a server-side error. Please try again tomorrow. Sorry for the inconvenience.")
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
                        self.displayAlert(title: "No Recipes", message: "We couldn't find any recipes matching to your search.")
                    } else {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                }
            }
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(self.refresh))
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
        
        // Likes
        cell.mealLikes.text = String(recipe.mealLikes ?? 0)
        cell.usedIngredientCount.text = String(recipe.usedIngredientCount ?? 0)
        cell.missedIngredientCount.text = String(recipe.missedIngredientCount ?? 0)
        
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
        guard let cell = collectionView.dataSource?.collectionView(collectionView, cellForItemAt: indexPath) as? RecipeCell else {
            fatalError("Unable to decode the data source's cells.")
        }
        var numberOfColumns = CGFloat(2)
        if view.frame.width > 500 {
            numberOfColumns = view.frame.width / 250
        }
        let height = 140 + 20 + 3 * cell.mealName.font.lineHeight // Image height + constraints + 3 available lines
        return CGSize(width: view.frame.width / numberOfColumns - 17, height: height)
    }
}

extension UIAlertController {
    func applyCustomStyle() {
        // Customize the title and message text color
        if let title = self.title {
            let attributedTitle = NSAttributedString(string: title, attributes: [
                .foregroundColor: UIColor.darkGray,
                .font: UIFont.boldSystemFont(ofSize: 17)
            ])
            self.setValue(attributedTitle, forKey: "attributedTitle")
        }
        
        if let message = self.message {
            let attributedMessage = NSAttributedString(string: message, attributes: [
                .foregroundColor: UIColor.darkGray,
                .font: UIFont.systemFont(ofSize: 14)
            ])
            self.setValue(attributedMessage, forKey: "attributedMessage")
        }
        
        // Customize the background color and shape
        if let backgroundView = self.view.subviews.first, let contentView = backgroundView.subviews.first {
            contentView.backgroundColor = UIColor.systemPink
            contentView.layer.cornerRadius = 30
            contentView.layer.masksToBounds = true
        }
    }
}
