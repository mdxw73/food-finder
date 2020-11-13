//
//  SelectedRecipe.swift
//  RecipeFinder
//
//  Created by Zack Obied on 30/09/2020.
//

import Foundation

class SelectedRecipe: NSObject, Codable, NSCoding {
    
    func encode(with coder: NSCoder) {
        coder.encode(mealName, forKey: "mealName")
        coder.encode(mealImage, forKey: "mealImage")
        coder.encode(summary, forKey: "summary")
        coder.encode(duration, forKey: "duration")
        coder.encode(ingredients, forKey: "ingredients")
        coder.encode(mealId, forKey: "mealId")
        coder.encode(servings, forKey: "servings")
    }
    
    required init?(coder: NSCoder) {
        mealName = coder.decodeObject(forKey: "mealName") as? String ?? ""
        mealImage = coder.decodeObject(forKey: "mealImage") as! URL
        summary = coder.decodeObject(forKey: "summary") as? String ?? ""
        duration = coder.decodeInteger(forKey: "duration")
        ingredients = coder.decodeObject(forKey: "ingredients") as! [Ingredient]
        mealId = coder.decodeInteger(forKey: "mealId")
        servings = coder.decodeInteger(forKey: "servings")
    }
    
    var mealName: String
    var mealImage: URL
    var summary: String
    var duration: Int
    var ingredients: [Ingredient]
    var mealId: Int
    var servings: Int
    
    private enum CodingKeys: String, CodingKey {
        case mealName = "title"
        case mealImage = "image"
        case summary = "summary"
        case duration = "readyInMinutes"
        case ingredients = "extendedIngredients"
        case mealId = "id"
        case servings = "servings"
    }
}
