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
    
    var mealId: Int = 0
    let selectedRecipeAdaptor = SelectedRecipeAdaptor()
    var recipe: SelectedRecipe?
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set initial button states
        clockButton.isEnabled = false
        peopleButton.isEnabled = false
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
        favouriteButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .selected)
        hideAllViews()
        
        // If this is not a favourited recipe
        if self.recipe == nil {
            // Set up loading text in navigation bar
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Loading...")
            navigationItem.rightBarButtonItem?.isEnabled = false
            
            selectedRecipeAdaptor.getSelectedRecipe(mealId) { (selectedRecipe, error) in
                // UI changes done on main thread
                DispatchQueue.main.async {
                    if error == true {
                        self.navigationItem.rightBarButtonItem?.title = "No Connection"
                    } else if let selectedRecipe = selectedRecipe {
                        self.navigationItem.rightBarButtonItem = nil
                        self.unhideAllViews()
                        self.recipe = selectedRecipe
                        self.performUIAssignments()
                        self.prepareIngredientsText()
                        self.displayDescription()
                    } else {
                        self.navigationItem.rightBarButtonItem = nil
                        self.displayAlert(title: "No Recipe Found", message: "We couldn't find any recipe for this meal.", actionTitle: "Close")
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
        self.ingredientsTextLabel.text = ""
        var lineBreak = "\n"
        for ingredient in self.recipe!.ingredients {
            if self.recipe?.ingredients.last?.name == ingredient.name {
                lineBreak = ""
            }
            self.ingredientsTextLabel.text! += "\u{2022} \(ingredient.name): \(ingredient.original.htmlToString)\(lineBreak)"
        }
        self.navigationItem.title = self.recipe!.mealName
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
    
    func displayAlert(title: String, message: String, actionTitle: String) {
        // Instantiate alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // Add a button below the text field
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: {_ in
            if title == "No Recipe Found" {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }))
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
        // Get instructions from API
        var formattedInstructions = ""
        let instructionsAdaptor = InstructionsAdaptor()
        
        // Set up loading text in navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Loading...")
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        instructionsAdaptor.getInstructions(mealId) { (instructions, error) in
            // UI changes done on main thread
            DispatchQueue.main.async {
                // Remove loading text from navigation bar
                self.navigationItem.rightBarButtonItem = nil
                
                if error == true {
                    self.displayAlert(title: "Please Check Your Internet Connection", message: "We couldn't establish a connection with the server.", actionTitle: "Close")
                    self.segmentedControl.selectedSegmentIndex = 0
                } else if instructions?.count ?? 0 > 0 {
                    for instructionStep in instructions![0].steps {
                        formattedInstructions += " \u{2022} \(instructionStep.step)\n"
                    }
                    self.textLabel.attributedText = self.addAttributes(formattedInstructions)
                } else {
                    self.displayAlert(title: "No Instructions Found", message: "We couldn't find any instructions for this meal.", actionTitle: "Close")
                    self.segmentedControl.selectedSegmentIndex = 0
                }
            }
        }
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
