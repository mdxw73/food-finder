//
//  RecipeCell.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import UIKit

class RecipeCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var mealName: UILabel!
    @IBOutlet var checkmark: UIButton!
    @IBOutlet var checkmarkConstraintOne: NSLayoutConstraint!
    @IBOutlet var checkmarkConstraintTwo: NSLayoutConstraint!
}
