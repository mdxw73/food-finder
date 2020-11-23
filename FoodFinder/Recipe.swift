//
//  Recipe.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import Foundation

struct Recipe: Codable {
    var mealName: String
    var mealImage: URL
    var mealId: Int
    var mealLikes: Int?
    var usedIngredientCount: Int?
    var missedIngredientCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case mealName = "title"
        case mealImage = "image"
        case mealId = "id"
        case mealLikes = "likes"
        case usedIngredientCount = "usedIngredientCount"
        case missedIngredientCount = "missedIngredientCount"
    }
}
