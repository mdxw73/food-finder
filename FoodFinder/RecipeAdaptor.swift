//
//  RecipeAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import Foundation

// temp: 057dc14550194bba943af6b075031715
// mine: 45216d9690b142a6921321f38ce6dfd1

class RecipeAdaptor {
    let baseUrl = "https://api.spoonacular.com/recipes/"
    let decoder = JSONDecoder()
    
    // Establish URL path based on search string and initialise data session
    func getRecipes(_ search: String, directory: String, completion: @escaping ([Recipe]?, Bool) -> Void) {
        let path = "\(search.replacingOccurrences(of: " ", with: "+"))&number=20&apiKey=45216d9690b142a6921321f38ce6dfd1"
        
        guard let url = URL(string: baseUrl + directory + path) else {
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
    
    // Try to decode the JSON data using the Recipe codable class and return the instance, otherwise return nil
    func parseJson(json: Data) -> [Recipe]? {
        if let recipeResponse = try? decoder.decode(RecipeSearchResults.self, from: json) {
            return recipeResponse.results
        } else if let recipeResponse = try? decoder.decode([Recipe].self, from: json) {
            return recipeResponse
        } else {
            print("Unable to decode data")
            return nil
        }
    }
    
}
