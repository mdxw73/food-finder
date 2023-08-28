//
//  SubscriptionViewController.swift
//  FoodFinder
//
//  Created by Zack Obied on 28/08/2023.
//

import UIKit

class SubscriptionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Choose a Subscription"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        let freeTrialBox = createSubscriptionBox(title: "Free Trial", price: "Free", description: "Access to all features for 30 days")
        let subscriptionBox = createSubscriptionBox(title: "Standard", price: "$4.99/month", description: "Access to all features")
        
        view.addSubview(freeTrialBox)
        view.addSubview(subscriptionBox)
        
        NSLayoutConstraint.activate([
            freeTrialBox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            freeTrialBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            freeTrialBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subscriptionBox.topAnchor.constraint(equalTo: freeTrialBox.bottomAnchor, constant: 20),
            subscriptionBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subscriptionBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add tap gesture recognizers to the subscription boxes
        let freeTrialTapGesture = UITapGestureRecognizer(target: self, action: #selector(subscriptionBoxTapped(_:)))
        freeTrialBox.addGestureRecognizer(freeTrialTapGesture)
        freeTrialBox.tag = 0
        
        let subscriptionTapGesture = UITapGestureRecognizer(target: self, action: #selector(subscriptionBoxTapped(_:)))
        subscriptionBox.addGestureRecognizer(subscriptionTapGesture)
        subscriptionBox.tag = 1
    }
    
    @objc private func subscriptionBoxTapped(_ sender: UITapGestureRecognizer) {
        // Remove border from all subscription boxes
        for subview in view.subviews {
            if subview.tag == 0 || subview.tag == 1 {
                subview.layer.borderWidth = 0
            }
        }

        guard let tag = sender.view?.tag else { return }
        let subscriptionName = tag == 0 ? "Free Trial" : "Standard"

        let alert = UIAlertController(title: "Subscription Selected", message: "You selected \(subscriptionName)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)

        // Highlight the selected subscription box with a light green border
        sender.view?.layer.borderWidth = 2
        sender.view?.layer.borderColor = UIColor.green.cgColor
    }
    
    private func createSubscriptionBox(title: String, price: String, description: String) -> UIView {
        let boxView = UIView()
        boxView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        boxView.layer.cornerRadius = 10
        boxView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        boxView.addSubview(titleLabel)
        
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        boxView.addSubview(priceLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .gray
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        boxView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: boxView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: boxView.leadingAnchor, constant: 10),
            
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            priceLabel.leadingAnchor.constraint(equalTo: boxView.leadingAnchor, constant: 10),
            
            descriptionLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 5),
            descriptionLabel.leadingAnchor.constraint(equalTo: boxView.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: boxView.trailingAnchor, constant: -10),
            descriptionLabel.bottomAnchor.constraint(equalTo: boxView.bottomAnchor, constant: -10)
        ])
        
        return boxView
    }
}
