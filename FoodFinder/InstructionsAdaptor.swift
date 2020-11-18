//
//  InstructionsAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 01/10/2020.
//

import Foundation

class InstructionsAdaptor {
    let baseUrl = "https://api.spoonacular.com/recipes/"
    let decoder = JSONDecoder()
    
    func getInstructions(_ mealId: Int, completion: @escaping ([Instructions]?, Bool) -> Void) {
        let path = "\(mealId)/analyzedInstructions?&apiKey=\(apiKey)"
        
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            completion(nil, false)
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                if let response = self.parseJson(json: data) {
                    // Return recipes and false for error
                    completion(response, false)
                } else {
                    // Return false for error and no recipes
                    completion(nil, false)
                }
            }
            // Return true for error and no recipes
            if error != nil {
                completion(nil, true)
            }
        }.resume()
    }
    
    func parseJson(json: Data) -> [Instructions]? {
        if let recipeResponse = try? decoder.decode([Instructions].self, from: json) {
            return recipeResponse
        } else {
            print("Unable to decode data")
            return nil
        }
    }
}
