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
        navigationItem.title = "By Complex Search"
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

extension SearchedRecipesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let cell = collectionView.dataSource?.collectionView(collectionView, cellForItemAt: indexPath) as? RecipeCell else {
            fatalError("Unable to decode the data source's cells.")
        }
        let height = 140 + 20 + 3 * cell.mealName.font.lineHeight // Image height + constraints + 3 available lines
        return CGSize(width: view.frame.width / 2 - 17, height: height)
    }
}
