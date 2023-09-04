//
//  RecipeAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import Foundation

let apiKey = "64878309292b4875b14e980eae9c6496"

// safeguard against scripts that abuse API access
func updateUserTokens(cost: Double) -> Double {
    let dailyTokenLimit: Double = 100
    let currentDate = Date()
    let initialUserTokens = UserDefaults.standard.double(forKey: "userTokens")
    
    if let lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date {
        // Check if a new day has started
        if Calendar.current.isDate(currentDate, inSameDayAs: lastResetDate) {
            // Tokens have already been reset today
            if initialUserTokens > cost {
                UserDefaults.standard.set(initialUserTokens - cost, forKey: "userTokens")
            } else {
                UserDefaults.standard.set(-1, forKey: "userTokens")
            }
        } else {
            // Reset tokens for the new day
            UserDefaults.standard.set(dailyTokenLimit - cost, forKey: "userTokens")
            UserDefaults.standard.set(currentDate, forKey: "lastResetDate")
        }
    } else {
        // First-time setup or if "lastResetDate" doesn't exist
        UserDefaults.standard.set(dailyTokenLimit - cost, forKey: "userTokens")
        UserDefaults.standard.set(currentDate, forKey: "lastResetDate")
    }
    return initialUserTokens
}

class RecipeAdaptor {
    let baseUrl = "https://api.spoonacular.com/recipes/"
    let decoder = JSONDecoder()
    
    // Establish URL path based on search string and initialise data session
    func getRecipes(_ search: String, directory: String, completion: @escaping ([Recipe]?, Bool) -> Void) {
        let path = "\(search.replacingOccurrences(of: " ", with: "+"))&number=20&apiKey=\(apiKey)&ranking=2"
        
        guard let url = URL(string: baseUrl + directory + path) else {
            print("Invalid URL")
            completion(nil, false)
            return
        }
        
        if updateUserTokens(cost: 1.1) == -1 {
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
