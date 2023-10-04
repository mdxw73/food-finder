//
//  RecipeAdaptor.swift
//  RecipeFinder
//
//  Created by Zack Obied on 26/09/2020.
//

import Foundation
import Security

class TokenManager {
    private let userTokensKey = "com.PantryView.userTokens"
    private let lastResetDateKey = "com.PantryView.lastResetDate"
    let dailyTokenLimit: Double = 50.0

    func updateUserTokens(cost: Double) -> Double {
        let currentDate = Date()
        var initialUserTokens = readUserTokensFromKeychain()

        if let lastResetDate = readLastResetDateFromKeychain() {
            if Calendar.current.isDate(currentDate, inSameDayAs: lastResetDate) || lastResetDate > currentDate {
                // Tokens have already been reset today
                if initialUserTokens > cost {
                    initialUserTokens -= cost
                    saveUserTokensToKeychain(initialUserTokens)
                } else {
                    saveUserTokensToKeychain(-1.0)
                }
            } else {
                // Reset tokens for the new day
                initialUserTokens = dailyTokenLimit - cost
                saveUserTokensToKeychain(initialUserTokens)
                saveLastResetDateToKeychain(currentDate)
            }
        } else {
            // First-time setup or if "lastResetDate" doesn't exist
            initialUserTokens = dailyTokenLimit - cost
            saveUserTokensToKeychain(initialUserTokens)
            saveLastResetDateToKeychain(currentDate)
        }

        return initialUserTokens
    }

    private func readUserTokensFromKeychain() -> Double {
        guard let data = readFromKeychain(key: userTokensKey) else {
            return 0.0 // Default value when the key is not found
        }

        return (data as AnyObject).doubleValue ?? 0.0
    }

    private func saveUserTokensToKeychain(_ tokens: Double) {
        writeToKeychain(key: userTokensKey, value: NSNumber(value: tokens))
    }

    private func readLastResetDateFromKeychain() -> Date? {
        return readFromKeychain(key: lastResetDateKey) as? Date
    }

    private func saveLastResetDateToKeychain(_ date: Date) {
        writeToKeychain(key: lastResetDateKey, value: date)
    }

    private func readFromKeychain(key: String) -> Any? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ] as [String: Any]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
            let existingItem = item as? [String: Any],
            let data = existingItem[kSecValueData as String] as? Data,
            let value = NSKeyedUnarchiver.unarchiveObject(with: data) else {
                return nil
        }

        return value
    }

    private func writeToKeychain(key: String, value: Any) {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ] as [String: Any]

        let update = [
            kSecValueData as String: data
        ] as [String: Any]

        var status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            status = SecItemAdd(newQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            print("Error writing to Keychain: \(status)")
            return
        }
    }
}

let apiKey = "64878309292b4875b14e980eae9c6496"
let tokenManager = TokenManager()

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
        
        if tokenManager.updateUserTokens(cost: 1.1) == -1 {
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
