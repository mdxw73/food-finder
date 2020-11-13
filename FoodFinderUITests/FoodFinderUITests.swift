//
//  FoodFinderUITests.swift
//  FoodFinderUITests
//
//  Created by Zack Obied on 13/11/2020.
//

import XCTest

class FoodFinderUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //MARK: Detector View
    
    func testOpeningViewDisablesStoreButtonAndSetsLabelTextToDefault() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars["Tab Bar"].buttons["Detector"].tap()
        
        XCTAssertEqual(app.staticTexts["Choose or Take a Photo"].exists, true)
        XCTAssertEqual(app.buttons["Store"].isEnabled, false)
    }
    
    func testStoreButtonSeguesUserToHomeView() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars["Tab Bar"].buttons["Detector"].tap()
        app.buttons["photo"].tap()
        XCUIApplication().scrollViews.otherElements.images["Photo, November 09, 11:51 PM"].tap()
        
        // Wait for loading text to be replaced by "Store"
        _ = app.navigationBars.buttons["Store"].waitForExistence(timeout: 5)
        
        app.navigationBars.buttons["Store"].tap()
        
        // Wait for views to change by checking whether an element exists
        _ = app.buttons["Edit"].waitForExistence(timeout: 1)
        
        XCTAssertEqual(app.tabBars["Tab Bar"].buttons["Home"].isSelected, true)
        
        removeIngredient(app: app)
    }
    
    //MARK: Home View

    func testBarButtonItemsAreDisabledWhenSearchingIngredients() throws {
        let app = XCUIApplication()
        app.launch()
        app.tables.children(matching: .searchField).element.tap()
        app.typeText("carrot")
        
        XCTAssertEqual(app.navigationBars["Home"].buttons["Edit"].isEnabled, false)
        XCTAssertEqual(app.navigationBars["Home"].buttons["add"].isEnabled, false)
    }
    
    //MARK: Selected Recipe View
    
    func testPresenceOfAllViews() {
        let app = XCUIApplication()
        app.launch()
        addIngredient(app: app)
        app.tabBars["Tab Bar"].buttons["Recipes"].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 5)
        app.collectionViews.cells.firstMatch.tap()
        
        XCTAssert(app.staticTexts.matching(identifier: "ingredientsText").firstMatch.exists) // Ingredients text
        XCTAssert(app.staticTexts.matching(identifier: "durationLabel").firstMatch.exists) // Duration text
        XCTAssert(app.staticTexts.matching(identifier: "textLabel").firstMatch.exists) // Text label
        XCTAssert(app.buttons["heart"].exists) // Favourite button
        XCTAssert(app.buttons["clock.arrow"].exists) // Meal image view
        XCTAssert(app.images.firstMatch.exists) // Meal image view
        XCTAssert(app.buttons["person"].exists) // People button
        XCTAssert(app.staticTexts.matching(identifier: "servingsLabel").firstMatch.exists) // Servings label
        
        removeIngredient(app: app)
    }
    
    //MARK: Favourites View
    
    func testFavouritesViewLoadsCorrectData() {
        let app = XCUIApplication()
        app.launch()
        addIngredient(app: app)

        app.tabBars["Tab Bar"].buttons["Recipes"].tap()
        _ = app.collectionViews.firstMatch.waitForExistence(timeout: 5)
        app.collectionViews.cells.firstMatch.tap()
        app.buttons["heart"].tap()
        app.tabBars["Tab Bar"].buttons["Favourites"].tap()
        app.collectionViews.cells.firstMatch.tap()
        
        XCTAssert(app.staticTexts["Carrot, Ginger, and Lime Juice"].exists)
        
        app.buttons["heart"].tap() // Select favourite button
        removeIngredient(app: app)
    }
    
    //MARK: Recipes View
    
    func testOpeningViewWithIngredients() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        addIngredient(app: app)
        app.tabBars["Tab Bar"].buttons["Recipes"].tap()
        
        XCTAssertNotNil(app.collectionViews.cells.count)
        
        removeIngredient(app: app)
    }
    
    func testOpeningViewWithoutIngredients() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars["Tab Bar"].buttons["Recipes"].tap()
        
        XCTAssertNotNil(app.staticTexts["No Ingredients"])
    }
    
    func addIngredient(app: XCUIApplication) {
        app.tabBars["Tab Bar"].buttons["Home"].tap()
        app.tables.children(matching: .searchField).element.tap()
        app.typeText("carrot")
        app.buttons["Store"].tap()
        app/*@START_MENU_TOKEN@*/.buttons["Search"]/*[[".keyboards",".buttons[\"search\"]",".buttons[\"Search\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["carrot"]/*[[".cells.staticTexts[\"carrot\"]",".staticTexts[\"carrot\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func removeIngredient(app: XCUIApplication) {
        app.tabBars["Tab Bar"].buttons["Home"].tap()
        app.navigationBars["Home"].buttons["Edit"].tap()
        app.tables/*@START_MENU_TOKEN@*/.buttons["Delete carrot"]/*[[".cells.buttons[\"Delete carrot\"]",".buttons[\"Delete carrot\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tables/*@START_MENU_TOKEN@*/.buttons["Delete"]/*[[".cells.buttons[\"Delete\"]",".buttons[\"Delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.navigationBars.buttons["Done"].tap()
    }
    
}
