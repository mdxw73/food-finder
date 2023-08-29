//
//  TabBarController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 27/09/2020.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !UserDefaults.standard.bool(forKey: "tutorialCompleted") {
            showTutorial()
        }
    }
    
    func showTutorial() {
        if let tutorialVC = storyboard!.instantiateViewController(withIdentifier: "TutorialViewController") as? TutorialViewController {
            tutorialVC.modalPresentationStyle = .popover
            present(tutorialVC, animated: true, completion: nil)
        }
    }

}
