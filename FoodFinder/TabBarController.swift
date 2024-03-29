//
//  TabBarController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 27/09/2020.
//

import UIKit

let InTutorialDidChangeNotification = Notification.Name("InTutorialDidChangeNotification")
var inTutorial = false {
    didSet {
        if !inTutorial {
            NotificationCenter.default.post(name: InTutorialDidChangeNotification, object: nil)
        }
    }
}

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.selectedIndex = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !UserDefaults.standard.bool(forKey: "tutorialCompleted") {
            showTutorial()
        }
    }
    
    func showTutorial() {
        if let tutorialVC = storyboard!.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
            tutorialVC.modalPresentationStyle = .automatic
            tutorialVC.isModalInPresentation = true
            tutorialVC.popoverPresentationController?.sourceView = self.tabBar
            present(tutorialVC, animated: true, completion: nil)
        }
    }

}
