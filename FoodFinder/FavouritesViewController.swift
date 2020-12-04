//
//  FavouritesViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 07/10/2020.
//

import UIKit

class FavouritesViewController: UICollectionViewController {

    var recipes: [SelectedRecipe] = []
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If there are favourite recipes saved in the defaults database, copy them across
        if let savedFavouriteRecipes = defaults.object(forKey: "savedFavouriteRecipes") {
            // Type cast object of type Any
            favouriteRecipes = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedFavouriteRecipes as! Data) as! [SelectedRecipe]
        }
        self.recipes = favouriteRecipes
    }
    
    // Update recipes attribute when necessary
    override func viewDidAppear(_ animated: Bool) {
        var change = false
        if recipes.count != favouriteRecipes.count {
            change = true
        } else {
            for count in 0..<favouriteRecipes.count {
                if recipes[count].mealId != favouriteRecipes[count].mealId {
                    change = true
                }
            }
        }
        if change == true {
            self.recipes = favouriteRecipes
            collectionView.reloadData()
        }
    }
    
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
    
    // Instantiate a selected recipe and pass in the meal id as well as the SelectedRecipe
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = storyboard?.instantiateViewController(identifier: "SelectedRecipeViewController") as? SelectedRecipeViewController else {
            fatalError("Failed to load Selected Recipe View Controller from Storyboard")
        }
        viewController.mealId = recipes[indexPath.item].mealId
        viewController.recipe = recipes[indexPath.item]
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension FavouritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let cell = collectionView.dataSource?.collectionView(collectionView, cellForItemAt: indexPath) as? RecipeCell else {
            fatalError("Unable to decode the data source's cells.")
        }
        let scaleFactor = 18 / Double(view.frame.width) // Ratio of number of characters per line to screen width
        let additionalSpace = CGFloat(pow(Double(cell.mealName.text!.count),2) * scaleFactor) / 3 // Product of number of characters in label, scale factor and a constant
        return CGSize(width: view.frame.width/2-17, height: view.frame.width/2.4 + additionalSpace)
    }
}
