//
//  FoodFinderTests.swift
//  FoodFinderTests
//
//  Created by Zack Obied on 13/11/2020.
//

import XCTest
@testable import FoodFinder

class FoodFinderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseJSONMethodReturnsNonNilValueWhenGivenValidJSON() throws {
        let adaptor = RecipeAdaptor()
        let json = """
        [{"id":1075071,"title":"25 Chicken","image":"https://spoonacular.com/recipeImages/1075071-312x231.jpg","imageType":"jpg","usedIngredientCount":2,"missedIngredientCount":2,"missedIngredients":[{"id":10123,"amount":1.0,"unit":"can","unitLong":"can","unitShort":"can","aisle":"Meat","name":"bacon","original":"Bacon Wrapped Chicken â€“ No one can resist this cheese stuffed, bacon wrapped chicken! Brush on some bbq sauce and serve with mashed potatoes and corn and you're in business!","originalString":"Bacon Wrapped Chicken â€“ No one can resist this cheese stuffed, bacon wrapped chicken! Brush on some bbq sauce and serve with mashed potatoes and corn and you're in business!","originalName":"Bacon Wrapped Chicken â€“ No one resist this cheese stuffed, bacon wrapped chicken! Brush on some bbq sauce and serve with mashed potatoes and corn and you're in business","metaInformation":["with mashed potatoes and corn and you're in business!"],"meta":["with mashed potatoes and corn and you're in business!"],"extendedName":"canned bacon","image":"https://spoonacular.com/cdn/ingredients_100x100/raw-bacon.png"},{"id":20444,"amount":1.0,"unit":"serving","unitLong":"serving","unitShort":"serving","aisle":"Pasta and Rice","name":"rice","original":"Chicken & Wild Rice Casserole â€“ Comfort food all the way! This recipe remind of of Sunday supper at my grandma's house.","originalString":"Chicken & Wild Rice Casserole â€“ Comfort food all the way! This recipe remind of of Sunday supper at my grandma's house.","originalName":"Chicken & Wild Rice Casserole â€“ Comfort food all the way! This recipe remind of of Sunday supper at my grandma's house","metaInformation":["wild"],"meta":["wild"],"extendedName":"wild rice","image":"https://spoonacular.com/cdn/ingredients_100x100/uncooked-white-rice.png"}],"usedIngredients":[{"id":5006,"amount":1.0,"unit":"serving","unitLong":"serving","unitShort":"serving","aisle":"Meat","name":"chicken","original":"Brown Sugar Pineapple Chicken â€“ My favorite grilling recipe! I love the sweet glaze on this chicken and the pineapple is insanely good. Serve with rice or on a burger bun with lettuce!","originalString":"Brown Sugar Pineapple Chicken â€“ My favorite grilling recipe! I love the sweet glaze on this chicken and the pineapple is insanely good. Serve with rice or on a burger bun with lettuce!","originalName":"Brown Sugar Pineapple Chicken â€“ My favorite grilling recipe! I love the sweet glaze on this chicken and the pineapple is insanely good. Serve with rice or on a burger bun with lettuce","metaInformation":["sweet","with rice or on a burger bun with lettuce!"],"meta":["sweet","with rice or on a burger bun with lettuce!"],"extendedName":"sweet chicken","image":"https://spoonacular.com/cdn/ingredients_100x100/whole-chicken.jpg"},{"id":5006,"amount":1.0,"unit":"Sheet","unitLong":"Sheet","unitShort":"Sheet","aisle":"Meat","name":"chicken","original":"Sheet Pan Chicken Fajitas â€“ Easiest fajitas ever! Chop eveything up, toss in seasoning, and bake until done. Just add tortillas!","originalString":"Sheet Pan Chicken Fajitas â€“ Easiest fajitas ever! Chop eveything up, toss in seasoning, and bake until done. Just add tortillas!","originalName":"Pan Chicken Fajitas â€“ Easiest fajitas ever! Chop eveything up, toss in seasoning, and bake until done. Just add tortillas","metaInformation":[],"meta":[],"image":"https://spoonacular.com/cdn/ingredients_100x100/whole-chicken.jpg"}],"unusedIngredients":[],"likes":1}]
        """
        let actual = adaptor.parseJson(json: Data(json.utf8))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(actual)
    }
    
    func testParseJSONMethodReturnsNilValueWhenGivenInvalidJSON() throws {
        let adaptor = RecipeAdaptor()
        let json = "Hello World"
        let actual = adaptor.parseJson(json: Data(json.utf8))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNil(actual)
    }
    
    func testCheckRepeatedIngredientReturnsTrueWhenResponseIsInIngredients() throws {
        let ViewController = HomeViewController()
        ingredients = [HomeIngredient(name: "Chicken", imageDirectory: "chicken.jpg"), HomeIngredient(name: "Rice", imageDirectory: "rice.jpg"), HomeIngredient(name: "Pepper", imageDirectory: "pepper.jpg")]
        let actual = ViewController.checkRepeatedIngredient(HomeIngredient(name: "Chicken", imageDirectory: "chicken.jpg"))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(actual, true)
    }
    func testCheckRepeatedIngredientReturnsFalseWhenResponseIsNotInIngredients() throws {
        let ViewController = HomeViewController()
        ingredients = [HomeIngredient(name: "Chicken", imageDirectory: "chicken.jpg"), HomeIngredient(name: "Rice", imageDirectory: "rice.jpg"), HomeIngredient(name: "Pepper", imageDirectory: "pepper.jpg")]
        let actual = ViewController.checkRepeatedIngredient(HomeIngredient(name: "Cucumber", imageDirectory: "cucumber.jpg"))
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(actual, false)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
