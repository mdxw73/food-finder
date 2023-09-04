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
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoBottomConstraint: NSLayoutConstraint!
    
    var currentStepIndex: Int = 0
    var tutorialSteps: [(title: String, description: String, imageName: String)] = [
        ("Welcome!", "Hello and welcome to the only cooking companion you'll ever need, complete with state of the art machine learning to help save you time and money. This tutorial will walk you through some of the basic features the app has to offer.", ""),
        ("Home", "The Home tab is where you can find all your ingredients. You can add new ones by pressing the search bar and selecting the store, or delete existing ones using the edit button.", "TutorialHome"),
        ("Detector", "The Detector tab offers you the ability to take a photo of your fridge/pantry and use that to add new ingredients. We're constantly improving the accuracy and ingredients recognised.", "TutorialDetector"),
        ("Recipes", "The Recipes tab automatically finds recipes that you can make with your ingredients. You can also search for specific recipes if that's what you'd prefer.", "TutorialRecipes"),
        ("Selected Recipes", "Select a recipe to view its description, instructions, and more. You can favourite recipes you love so that they can be quickly accessed in the future.", "TutorialSelectedRecipes"),
        ("That's it!", "Now you're all caught up, you can dive in and start cooking up some masterpieces you didn't even know you could make. No need to create an account, we'll just use your Apple ID. All new users get a 7-day free trial, after that you'll need to pay $2.99 a month. You can cancel the subscription at any time. Enjoy!", "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inTutorial = true
        
        styleUIElements()
        updateUIForCurrentStep()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true)
        inTutorial = false
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
        titleLabel.adjustsFontSizeToFitWidth = true
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor.darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.adjustsFontSizeToFitWidth = true
    }
    
    func styleButtons() {
        let buttonCornerRadius: CGFloat = 10
        let buttonShadowOpacity: Float = 0.3
        
        // Style Next Button
        nextButton.backgroundColor = UIColor.init(cgColor: CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1))
        nextButton.tintColor = .white
        nextButton.layer.cornerRadius = buttonCornerRadius
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOpacity = buttonShadowOpacity
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        nextButton.layer.shadowRadius = 5
        
        // Style Previous Button
        previousButton.backgroundColor = UIColor.init(cgColor: CGColor(red: 0.5, green: 0.5, blue: 1, alpha: 1))
        previousButton.tintColor = .white
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
        } else {
            imageView.image = .none
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
            logo.transform = CGAffineTransform(scaleX: 3, y: 3)
            logoTopConstraint.constant = 80
            logoBottomConstraint.constant = 80
        } else if currentStepIndex == tutorialSteps.count - 1 {
            logo.transform = CGAffineTransform(scaleX: 3, y: 3)
            logoTopConstraint.constant = 80
            logoBottomConstraint.constant = 80
        } else {
            previousButton.isHidden = false
            logo.transform = .identity
            logoTopConstraint.constant = 20
            logoBottomConstraint.constant = 20
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if currentStepIndex < tutorialSteps.count - 1 {
            currentStepIndex += 1
            animateTransitionToNextStep()
        } else {
            UserDefaults.standard.set(true, forKey: "tutorialCompleted")
            dismiss(animated: true, completion: nil)
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
