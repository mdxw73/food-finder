//
//  SearchedRecipesViewController.swift
//  FoodFinder
//
//  Created by Zack Obied on 16/11/2020.
//

import UIKit

class SearchedRecipesViewController: UICollectionViewController {

    var recipes: [Recipe] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "By Search"
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
        guard tokenManager.updateUserTokens(cost: 0) != -1 else {
            displayAlert(title: "Limit Reached", message: "You have reached your recipe limit for today. Please try again tomorrow.")
            return
        }
        viewController.mealId = self.recipes[indexPath.item].mealId
        viewController.similarRecipes = recipes.filter({$0.mealId != viewController.mealId})
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}

extension SearchedRecipesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let minSpacing: CGFloat = 14 // from storyboard
        let sectionInset: CGFloat = 10 // from storyboard
        let minWidth: CGFloat = 190
        let numberOfColumns = round(collectionView.bounds.width / minWidth)
        let availableWidth = collectionView.bounds.width - ((numberOfColumns-1) * minSpacing) - (2 * sectionInset)
        let width = (availableWidth / numberOfColumns) - 1 // subtract 1 to account for overflows
        
        let height = 140 + 20 + 3 * UIFont.systemFont(ofSize: 14).lineHeight // Image height + constraints + 3 available lines
        
        return CGSize(width: width, height: height)
    }
}
