//
//  SelectedRecipeViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 30/09/2020.
//

import UIKit

var favouriteRecipes: [SelectedRecipe] = []

class SelectedRecipeViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var ingredientsLabel: UILabel!
    @IBOutlet var ingredientsTextLabel: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var clockButton: UIButton!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var servingsLabel: UILabel!
    @IBOutlet var peopleButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var similarRecipesLabel: UILabel!
    @IBOutlet var similarRecipesConstraintOne: NSLayoutConstraint!
    @IBOutlet var similarRecipesConstraintTwo: NSLayoutConstraint!
    
    var mealId: Int = 0
    let selectedRecipeAdaptor = SelectedRecipeAdaptor()
    var recipe: SelectedRecipe?
    let defaults = UserDefaults.standard
    var similarRecipes: [Recipe]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkSubscription()
        
        if similarRecipes == nil || similarRecipes!.count == 0 {
            collectionViewHeightConstraint.constant = 0
            similarRecipesLabel.font = UIFont.systemFont(ofSize: 0)
            similarRecipesConstraintOne.constant = 0
            similarRecipesConstraintTwo.constant = 0
        } else {
            collectionViewHeightConstraint.constant = 220
        }
        
        // Set up collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Set initial button states
        clockButton.isEnabled = false
        peopleButton.isEnabled = false
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .selected)
        hideAllViews()
        
        // If this is not a favourited recipe
        if self.recipe == nil {
            generateLoadingIcon()
            selectedRecipeAdaptor.getSelectedRecipe(mealId) { (selectedRecipe, error) in
                // UI changes done on main thread
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem = nil
                    if error == true {
                        self.displayAlert(title: "No Connection", message: "Please check your network connection.")
                    } else if let selectedRecipe = selectedRecipe {
                        self.unhideAllViews()
                        self.recipe = selectedRecipe
                        self.performUIAssignments()
                        self.prepareIngredientsText()
                        self.displayDescription()
                    } else {
                        self.displayAlert(title: "No Recipe", message: "We couldn't find a recipe for this meal. This could be due to it not existing yet or the servers being unavailable at the moment.")
                    }
                }
            }
        } else {
            unhideAllViews()
            performUIAssignments()
            prepareIngredientsText()
            displayDescription()
        }
        
        // If there are favourite recipes saved in the defaults database, copy them across
        if let savedFavouriteRecipes = defaults.object(forKey: "savedFavouriteRecipes") {
            // Type cast object of type Any
            favouriteRecipes = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedFavouriteRecipes as! Data) as! [SelectedRecipe]
        }
        
        if view.frame.width > 500 {
            imageView.constraints.forEach { constraint in
                constraint.isActive = false
            }
            imageView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.2)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        var state = false
        for favouriteRecipe in favouriteRecipes {
            if favouriteRecipe.mealId == mealId {
                state = true
            }
        }
        favouriteButton.isSelected = state
    }
    
    func generateLoadingIcon() {
        let loadingButton = UIButton() // Create new button
        loadingButton.setImage(UIImage(systemName: "circle.grid.cross.fill"), for: .normal) // Assign an image
        loadingButton.imageView?.tintColor = UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        navigationItem.rightBarButtonItem = UIBarButtonItem()
        navigationItem.rightBarButtonItem?.customView = loadingButton // Set as barButton's customView
        UIView.animate(withDuration: 1, delay: 0, options: .repeat, animations: {
            self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransform(rotationAngle: .pi)
                }, completion: nil)
    }
    
    func addAttributes(_ text: String) -> NSMutableAttributedString {
        var indexArray: [Int] = []
        let attributedText = NSMutableAttributedString(string: text)
        
        // Convert string to array of characters
        let mappedText = text.map({ $0 })
        
        // Locate index of bullet points
        for count in 0..<mappedText.count {
            if mappedText[count] == "•" {
                indexArray.append(count)
            }
        }
        
        // Set attributes to relevant ranges
        for index in indexArray {
            attributedText.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.orange, NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(15), weight: .black)], range: NSRange(index...index))
        }
        return attributedText
    }
    
    func performUIAssignments() {
        self.imageView.load(url: self.recipe!.mealImage)
        self.durationLabel.text = "\(self.recipe!.duration) minutes"
        if self.checkIfFavourited() == false {
            self.favouriteButton.isSelected = false
        } else {
            self.favouriteButton.isSelected = true
        }
        self.servingsLabel.text = "\(recipe!.servings) persons"
    }
    
    func prepareIngredientsText() {
        let formattedIngredients = NSMutableAttributedString()
        var index = 1
        self.ingredientsTextLabel.text = ""
        var lineBreak = "\n"
        for ingredient in self.recipe!.ingredients {
            if self.recipe!.ingredients.last!.name == ingredient.name {
                lineBreak = ""
            }
            // Create an attachment with the system icon
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "\(index).circle")
            let attachmentString = NSAttributedString(attachment: attachment)
            
            // Create a string with the instruction step
            let ingredientString = NSAttributedString(string: " \(ingredient.name): \(ingredient.original.htmlToString)\(lineBreak)")
            
            // Combine the attachment and instruction string
            let combinedString = NSMutableAttributedString()
            combinedString.append(attachmentString)
            combinedString.append(ingredientString)
            
            // Append the combined string to the formattedInstructions
            formattedIngredients.append(combinedString)
            index += 1
        }
        self.ingredientsTextLabel.attributedText = formattedIngredients
        self.navigationItem.title = self.recipe!.mealName
    }
    
    func hideAllViews() {
        favouriteButton.isHidden = true
        clockButton.isHidden = true
        durationLabel.isHidden = true
        ingredientsLabel.isHidden = true
        ingredientsTextLabel.isHidden = true
        segmentedControl.isHidden = true
        textLabel.isHidden = true
        peopleButton.isHidden = true
        servingsLabel.isHidden = true
        collectionView.isHidden = true
        similarRecipesLabel.isHidden = true
    }
    
    func unhideAllViews() {
        favouriteButton.isHidden = false
        clockButton.isHidden = false
        durationLabel.isHidden = false
        ingredientsLabel.isHidden = false
        ingredientsTextLabel.isHidden = false
        segmentedControl.isHidden = false
        textLabel.isHidden = false
        peopleButton.isHidden = false
        servingsLabel.isHidden = false
        collectionView.isHidden = false
        similarRecipesLabel.isHidden = false
    }
    
    func checkIfFavourited() -> Bool {
        var favourited = false
        for item in favouriteRecipes {
            if item.mealName == recipe!.mealName {
                favourited = true
            }
        }
        return favourited
    }
    
    func displayAlert(title: String, message: String) {
        // Instantiate alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.applyCustomStyle()
        // Add a button below the text field
        let closeAction = UIAlertAction(title: "Close", style: .default, handler: {_ in
            if title == "No Recipe" {
                self.navigationController?.popViewController(animated: true)
            }
        })
        closeAction.setValue(UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)), forKey: "titleTextColor")
        alert.addAction(closeAction)
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func favourite(_ sender: Any) {
        if checkIfFavourited() == false {
            favouriteButton.isSelected = true
            favouriteRecipes.append(recipe!)
        } else {
            favouriteButton.isSelected = false
            favouriteRecipes.removeAll(where: { $0.mealName == recipe!.mealName })
        }
        // Convert type [SelectedRecipe] to type NSData
        if let convertedFavouriteRecipes = try? NSKeyedArchiver.archivedData(withRootObject: favouriteRecipes, requiringSecureCoding: false) {
            defaults.set(convertedFavouriteRecipes, forKey: "savedFavouriteRecipes")
        }
    }
    
    func displayDescription() {
        self.textLabel.text = recipe!.summary.htmlToString
    }
    
    func displayInstructions() {
        let formattedInstructions = NSMutableAttributedString()
        var index = 1
        var lineBreak = "\n"
        if self.recipe!.analyzedInstructions.count > 0 {
            for instruction in self.recipe!.analyzedInstructions {
                for instructionStep in instruction.steps {
                    if self.recipe!.analyzedInstructions.last!.steps.last! == instructionStep {
                        lineBreak = ""
                    }
                    // Create an attachment with the system icon
                    let attachment = NSTextAttachment()
                    attachment.image = UIImage(systemName: "\(index).circle")
                    let attachmentString = NSAttributedString(attachment: attachment)
                    
                    // Create a string with the instruction step
                    let instructionString = NSAttributedString(string: " \(self.fixTypos(instructionStep.step))\(lineBreak)")
                    
                    // Combine the attachment and instruction string
                    let combinedString = NSMutableAttributedString()
                    combinedString.append(attachmentString)
                    combinedString.append(instructionString)
                    
                    // Append the combined string to the formattedInstructions
                    formattedInstructions.append(combinedString)
                    index += 1
                }
            }
            // Set the attributed text for the label
            self.textLabel.attributedText = formattedInstructions
        } else {
            self.displayAlert(title: "No Instructions", message: "We couldn't find any instructions for this meal. Sorry for the inconvenience.")
            self.segmentedControl.selectedSegmentIndex = 0
        }
    }
    
    func fixTypos(_ input: String) -> String {
        var pattern = "([a-zFCLS][\\.!?:;,])([^\\s.!?\\)\\]\\}\"])"
        var regex = try! NSRegularExpression(pattern: pattern)
        var modifiedInput = regex.stringByReplacingMatches(
            in: input,
            options: [],
            range: NSRange(location: 0, length: input.utf16.count),
            withTemplate: "$1 $2"
        )
        
        pattern = "([a-zA-Z0-9])(\\s+)([.,;!?])"
        regex = try! NSRegularExpression(pattern: pattern)
        modifiedInput = regex.stringByReplacingMatches(
            in: modifiedInput,
            options: [],
            range: NSRange(location: 0, length: input.utf16.count),
            withTemplate: "$1$3"
        )
        
        modifiedInput = replaceMultipleSpaces(removeUnpairedBrackets(from: modifiedInput).trimmingCharacters(in: .whitespacesAndNewlines))
        
        if !modifiedInput.isEmpty {
            let lastChar = modifiedInput.last!
            let terminatingPunctuation: Set<Character> = [".", "!", "?"]
            
            if !terminatingPunctuation.contains(lastChar) {
                return modifiedInput + "."
            }
        }
        
        return modifiedInput
    }
    
    func removeUnpairedBrackets(from input: String) -> String {
        var bracket = ""
        var temp = ""
        var result = ""

        for char in input {
            if bracket != "" {
                if (char == ")" && bracket == "(") || (char == "}" && bracket == "{") || (char == "]" && bracket == "[") {
                    result.append(bracket)
                    result.append(temp)
                    result.append(char)
                    bracket = ""
                    temp = ""
                } else {
                    temp.append(char)
                }
            } else if char == "(" || char == "{" || char == "[" {
                bracket = String(char)
            } else if char != ")" && char != "}" && char != "]" {
                result.append(char)
            }
        }
        result.append(temp)
        return result
    }
    
    func replaceMultipleSpaces(_ input: String) -> String {
        let pattern = "\\s+" // Regular expression pattern for matching one or more whitespace characters
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.utf16.count)
        
        let modifiedString = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: " ")
        return modifiedString
    }
    
    @IBAction func segmentedControlPress(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            displayDescription()
        } else {
            displayInstructions()
        }
    }

}

// Add attribute that strips html code of its operators
extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension SelectedRecipeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return similarRecipes?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Type cast each instance of UICollectionViewCell as RecipeCell.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Recipe", for: indexPath) as? RecipeCell else {
            fatalError("Unable to dequeue a RecipeCell.")
        }
        
        let recipe = similarRecipes![indexPath.item]
        
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
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = storyboard?.instantiateViewController(identifier: "SelectedRecipeViewController") as? SelectedRecipeViewController else {
            fatalError("Failed to load Selected Recipe View Controller from Storyboard")
        }
        viewController.mealId = self.similarRecipes![indexPath.item].mealId
        viewController.similarRecipes = similarRecipes?.filter({$0.mealId != self.similarRecipes![indexPath.item].mealId})
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension SelectedRecipeViewController: UICollectionViewDelegateFlowLayout {
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
