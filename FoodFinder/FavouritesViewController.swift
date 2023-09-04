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
    let noneLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(lockoutUnsubscribedUser), name: InTutorialDidChangeNotification, object: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(self.showTutorial))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: self, action: #selector(self.showSubscription))
        
        // If there are favourite recipes saved in the defaults database, copy them across
        if let savedFavouriteRecipes = defaults.object(forKey: "savedFavouriteRecipes") {
            // Type cast object of type Any
            favouriteRecipes = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedFavouriteRecipes as! Data) as! [SelectedRecipe]
        }
        self.recipes = favouriteRecipes
        
        addNoneLabel()
    }
    
    // Update recipes attribute when necessary
    override func viewDidAppear(_ animated: Bool) {
        if !inTutorial {
            lockoutUnsubscribedUser()
        }
        
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
    
    func addNoneLabel() {
        // Add a UILabel
        noneLabel.text = "No Favourites"
        noneLabel.textColor = .gray
        noneLabel.font = UIFont.systemFont(ofSize: 18)
        noneLabel.textAlignment = .center
        
        // Add constraints to center the UILabel
        noneLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(noneLabel)
        NSLayoutConstraint.activate([
            noneLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            noneLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
    
    @objc func lockoutUnsubscribedUser() {
        Task.init {
            let purchaseManager = PurchaseManager()
            await purchaseManager.updatePurchasedProducts()
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
            if !purchaseManager.hasUnlockedAccess {
                self.showSubscription()
                for item in tabBarController!.tabBar.items! {
                    item.isEnabled = false
                }
            } else {
                for item in tabBarController!.tabBar.items! {
                    item.isEnabled = true
                }
            }
        }
    }
    
    @objc func showSubscription() {
        let subscriptionVC = SubscriptionViewController()
        self.navigationController?.pushViewController(subscriptionVC, animated: true)
    }
    
    @objc func showTutorial() {
        if let tutorialVC = storyboard!.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
            tutorialVC.modalPresentationStyle = .popover
            tutorialVC.popoverPresentationController?.sourceView = self.tabBarController?.tabBar
            present(tutorialVC, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if recipes.count == 0 {
            noneLabel.isHidden = false
        } else {
            noneLabel.isHidden = true
        }
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
        let minSpacing: CGFloat = 14 // from storyboard
        let sectionInset: CGFloat = 10 // from storyboard
        let minWidth: CGFloat = 190
        let numberOfColumns = round(collectionView.bounds.width / minWidth)
        let availableWidth = collectionView.bounds.width - ((numberOfColumns-1) * minSpacing) - (2 * sectionInset)
        let width = (availableWidth / numberOfColumns) - 1 // subtract 1 to account for overflows
        
        let height = 130 + 20 + 3 * UIFont.systemFont(ofSize: 14).lineHeight // Image height + constraints + 3 available lines
        
        return CGSize(width: width, height: height)
    }
}
