//
//  TutorialViewController.swift
//  FoodFinder
//
//  Created by Zack Obied on 27/08/2023.
//

import UIKit

class TutorialViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    
    var currentStepIndex: Int = 0
    var tutorialSteps: [(title: String, description: String, imageName: String)] = [
        ("Welcome!", "Hello and welcome to the only cooking companion you'll ever need, complete with state of the art machine learning to help save you time and stress. This tutorial will walk you through some of the basic features the app has to offer.", ""),
        ("Home", "The home tab is where you can find all your ingredients. You can add new ones by pressing the search bar and selecting the store, or delete existing ones using the edit button.", "TutorialHome"),
        ("Detector", "The detector tab offers you the ability to take a photo and use that to add new ingredients to your pantry. Simply snap a photo of your fridge or counter and it'll identify everything it recognises.", "TutorialDetector"),
        ("Recipes", "The recipes tab automatically finds recipes that you can make with your ingredients. You can also search for specific recipes if that's what you'd prefer.", "TutorialRecipes"),
        ("That's it!", "Now you're all caught up, you can dive in and start cooking up some masterpieces you didn't even know you could make. All new users get a one month free trial, after that you'll need to pay $4.99 a month. Enjoy!", "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleUIElements()
        updateUIForCurrentStep()
    }
    
    func styleUIElements() {
        styleLabels()
        styleButtons()
        styleImageView()
    }
    
    func styleLabels() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor.darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
    }
    
    func styleButtons() {
        let buttonCornerRadius: CGFloat = 10
        let buttonShadowOpacity: Float = 0.3
        
        // Style Next Button
        nextButton.backgroundColor = UIColor.init(cgColor: CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1))
        nextButton.setTitleColor(UIColor.white, for: .normal)
        nextButton.setTitleColor(UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1)), for: .highlighted)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        nextButton.layer.cornerRadius = buttonCornerRadius
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOpacity = buttonShadowOpacity
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        nextButton.layer.shadowRadius = 5
        
        // Style Previous Button
        previousButton.backgroundColor = UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1))
        previousButton.setTitleColor(UIColor.white, for: .normal)
        previousButton.setTitleColor(UIColor.init(cgColor: CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)), for: .highlighted)
        previousButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        previousButton.layer.cornerRadius = buttonCornerRadius
        previousButton.layer.shadowColor = UIColor.black.cgColor
        previousButton.layer.shadowOpacity = buttonShadowOpacity
        previousButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        previousButton.layer.shadowRadius = 5
    }
    
    func styleImageView() {
        imageView.layer.cornerRadius = 15
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        imageView.layer.shadowRadius = 5
    }
    
    func updateUIForCurrentStep() {
        let step = tutorialSteps[currentStepIndex]
        titleLabel.text = step.title
        descriptionLabel.text = step.description
        if step.imageName != "" {
            imageView.image = UIImage(named: step.imageName)
        }
        
        if currentStepIndex == tutorialSteps.count - 1 {
            nextButton.setTitle("Finish", for: .normal)
            nextButton.backgroundColor = UIColor.systemGreen
        } else {
            nextButton.setTitle("Next", for: .normal)
            nextButton.backgroundColor = UIColor.init(cgColor: CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1))
        }
        
        if currentStepIndex == 0 {
            previousButton.isHidden = true
        } else {
            previousButton.isHidden = false
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if currentStepIndex < tutorialSteps.count - 1 {
            currentStepIndex += 1
            animateTransitionToNextStep()
        } else {
            UserDefaults.standard.set(true, forKey: "tutorialCompleted")
            if #available(iOS 15.0, *) {
                Task.init {
                    let purchaseManager = PurchaseManager()
                    await purchaseManager.updatePurchasedProducts()
                    do {
                        try await purchaseManager.loadProducts()
                    } catch {
                        print(error)
                    }
                    if !purchaseManager.hasUnlockedAccess {
                        do {
                            try await purchaseManager.purchase(purchaseManager.products[0])
                        } catch {
                            print(error)
                        }
                    } else {
                        dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                let alertController = UIAlertController(
                    title: "Update Required",
                    message: "This app requires iOS 15.0 or later. Please update your iOS version to continue.",
                    preferredStyle: .alert
                )
                
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    // Handle the user's response here if needed
                }
                alertController.addAction(okAction)
                
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func previousButtonTapped(_ sender: UIButton) {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            animateTransitionToPreviousStep()
        }
    }
    
    func animateTransitionToNextStep() {
        UIView.transition(with: view, duration: 0.5, options: .transitionFlipFromRight, animations: {
            self.updateUIForCurrentStep()
        }, completion: nil)
    }
    
    func animateTransitionToPreviousStep() {
        UIView.transition(with: view, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            self.updateUIForCurrentStep()
        }, completion: nil)
    }
}
