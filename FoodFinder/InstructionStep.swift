//
//  Step.swift
//  RecipeFinder
//
//  Created by Zack Obied on 01/10/2020.
//

import Foundation

class InstructionStep: NSObject, Codable, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(step, forKey: "step")
    }
    
    required init?(coder: NSCoder) {
        step = coder.decodeObject(forKey: "step") as? String ?? ""
    }
    
    var step: String
    
    private enum CodingKeys: String, CodingKey {
        case step = "step"
    }
}
