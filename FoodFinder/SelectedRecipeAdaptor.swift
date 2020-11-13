//
//  SelectedRecipeAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 30/09/2020.
//

import Foundation

class SelectedRecipeAdaptor {
    let baseUrl = "https://api.spoonacular.com/recipes/"
    let decoder = JSONDecoder()
    
    func getSelectedRecipe(_ mealId: Int, completion: @escaping (SelectedRecipe?, Bool) -> Void) {
        let path = "\(mealId)/information?&apiKey=45216d9690b142a6921321f38ce6dfd1"
        
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
    
    func parseJson(json: Data) -> SelectedRecipe? {
        if let recipeResponse = try? decoder.decode(SelectedRecipe.self, from: json) {
            return recipeResponse
        } else {
            print("Unable to decode data")
            return nil
        }
    }
}
