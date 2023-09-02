//
//  Instructions.swift
//  RecipeFinder
//
//  Created by Zack Obied on 02/10/2020.
//

import Foundation

class Instruction: NSObject, Codable, NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(steps, forKey: "steps")
    }
    
    required init?(coder: NSCoder) {
        steps = coder.decodeObject(forKey: "steps") as? [InstructionStep] ?? []
    }
    
    var steps: [InstructionStep]
    
    private enum CodingKeys: String, CodingKey {
        case steps = "steps"
    }
}
