//
//  HomeIngredient.swift
//  FoodFinder
//
//  Created by Zack Obied on 17/11/2020.
//

import Foundation

class HomeIngredient: NSObject, Codable, NSCoding {
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(imageDirectory, forKey: "imageDirectory")
    }
    
    init(name: String, imageDirectory: String) {
        self.name = name
        self.imageDirectory = imageDirectory
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        imageDirectory = coder.decodeObject(forKey: "imageDirectory") as? String ?? ""
    }
    
    var name: String
    var imageDirectory: String
}
