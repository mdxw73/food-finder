//
//  AutocompleteIngredientsAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 06/11/2020.
//

import Foundation

class AutocompleteIngredientsAdaptor {
    let baseUrl = "https://api.spoonacular.com/food/ingredients/autocomplete?query="
    let decoder = JSONDecoder()
    
    func getAutocompleteIngredients(_ search: String, completion: @escaping ([AutocompleteIngredient]?, Bool) -> Void) {
        let path = "\(search.replacingOccurrences(of: " ", with: "+"))&apiKey=\(apiKey)"
        
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            completion(nil, false)
            return
        }
        
        if updateUserTokens(cost: 0.1) == -1 {
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
    
    func parseJson(json: Data) -> [AutocompleteIngredient]? {
        if let recipeResponse = try? decoder.decode([AutocompleteIngredient].self, from: json) {
            return recipeResponse
        } else {
            print("Unable to decode data")
            return nil
        }
    }
}
