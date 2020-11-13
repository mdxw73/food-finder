//
//  Ingredient.swift
//  RecipeFinder
//
//  Created by Zack Obied on 01/10/2020.
//

import Foundation

class Ingredient: NSObject, Codable, NSCoding {
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(original, forKey: "original")
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        original = coder.decodeObject(forKey: "original") as? String ?? ""
    }
    
    var name: String
    var original: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case original = "original"
    }
}
