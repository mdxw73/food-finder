//
//  DetectorViewController.swift
//  RecipeFinder
//
//  Created by Zack Obied on 27/09/2020.
//

import UIKit
import CoreML
import Vision

var detectedIngredients: [HomeIngredient] = []

class DetectorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var photosButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add navigation bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Store", style: .plain, target: self, action: #selector(self.storeObject))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        navigationItem.title = "Choose or Take a Photo"
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // Reset label, image view and disable button
    override func viewDidDisappear(_ animated: Bool) {
        self.navigationItem.title = "Choose or Take a Photo"
        self.imageView.image = nil
        navigationItem.rightBarButtonItem?.isEnabled = false
        self.imageView.layer.sublayers = nil // Remove old bounding boxes
    }
    
    // Instantiate an image picker controller using the source type passed in
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // Call method with camera source type
    @IBAction func takePicture(_ sender: Any) {
        presentPhotoPicker(sourceType: .camera)
    }
    
    // Call method with photo library source type
    @IBAction func choosePhoto(_ sender: Any) {
        presentPhotoPicker(sourceType: .photoLibrary)
    }
    
    // Save objects detected to ingredients array and segue to HomeViewController
    @objc func storeObject() {
        if let queries = navigationItem.title?.split(separator: ",") { // Generate individual ingredients from many
            var formattedQueries = queries
            for count in 0..<formattedQueries.count {
                if formattedQueries[count].first == " " {
                    formattedQueries[count].removeFirst() // Remove spaces at the end of the ingredients
                }
                AutocompleteIngredientsAdaptor().getAutocompleteIngredients(String(formattedQueries[count])+"&number=1") { (autocompleteIngredients, error) in // Create an autocomplete query and get the first response
                    if error == false {
                        if autocompleteIngredients?.count != 0 { // Unwrap response
                            detectedIngredients.append(HomeIngredient(name: autocompleteIngredients![0].name, imageDirectory: autocompleteIngredients![0].image)) // Successful response
                        } else {
                            detectedIngredients.append(HomeIngredient(name: String(formattedQueries[count]), imageDirectory: "\(String(formattedQueries[count])).jpg")) // Unsuccessful response
                        }
                    } else {
                        detectedIngredients.append(HomeIngredient(name: String(formattedQueries[count]), imageDirectory: "\(String(formattedQueries[count])).jpg")) // Unsuccessful response
                    }
                    if detectedIngredients.count == formattedQueries.count {
                        DispatchQueue.main.async {
                            self.tabBarController?.selectedIndex = 1 // Return to home view if last ingredient
                        }
                    }
                }
            }
        } else {
            // Single ingredient case
            AutocompleteIngredientsAdaptor().getAutocompleteIngredients(navigationItem.title!+"&number=1") { (autocompleteIngredients, error) in
                if error == false {
                    if let autocompleteIngredient = autocompleteIngredients?[0] {
                        detectedIngredients.append(HomeIngredient(name: autocompleteIngredient.name, imageDirectory: autocompleteIngredient.image))
                    } else {
                        detectedIngredients.append(HomeIngredient(name: "\(self.navigationItem.title!)", imageDirectory: "\(self.navigationItem.title!).jpg"))
                    }
                } else {
                    detectedIngredients.append(HomeIngredient(name: "\(self.navigationItem.title!)", imageDirectory: "\(self.navigationItem.title!).jpg"))
                }
                DispatchQueue.main.async {
                    self.tabBarController?.selectedIndex = 1
                }
            }
        }
    }
    
    func isImageLandscape(image: UIImage) -> Bool {
        return image.size.width > image.size.height
    }
    
    func rotateImage(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
        context.rotate(by: CGFloat.pi / 2) // Rotate by 90 degrees clockwise
        
        context.scaleBy(x: 1.0, y: -1.0) // Flip vertically (optional, depending on desired output)
        
        context.draw(image.cgImage!, in: CGRect(x: -image.size.height / 2, y: -image.size.width / 2, width: image.size.height, height: image.size.width))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
    
    private func cropToSquare(image: UIImage) -> UIImage {
        let sideLength = min(image.size.width, image.size.height)
        let squareRect = CGRect(x: 0, y: 0, width: sideLength, height: sideLength)
        
        if let cgImage = image.cgImage?.cropping(to: squareRect) {
            if isImageLandscape(image: image) {
                return UIImage(cgImage: cgImage)
            } else {
                return rotateImage(image: UIImage(cgImage: cgImage))!
            }
        }
        
        return image
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //Remove the picker view from the screen
        picker.dismiss(animated: true)
        
        // Set the chosen image to UIImageView's attribute image and classify it
        let image = cropToSquare(image: info[.originalImage] as! UIImage)
        imageView.image = image
        classify(image: image)
    }
    
    // Create image request handler and perform requests
    func classify(image: UIImage) {
        self.imageView.layer.sublayers = nil // Remove old bounding boxes
        navigationItem.rightBarButtonItem?.isEnabled = true
        generateLoadingIcon()
        // Vision requests are time consuming and so send it on a background thread to avoid blocking main thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Prepare an input image for Vision
            let ciImage = CIImage(image: image)!
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
            
            // The image handler request to be processed by Vision
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            
            // Schedule requests and return results once all have been completed
            try! handler.perform([self.classificationRequest])
        }
    }
    
    func generateLoadingIcon() {
        let loadingButton = UIButton() // Create new button
        loadingButton.setImage(UIImage(systemName: "circle.grid.cross.fill"), for: .normal) // Assign an image
        loadingButton.imageView?.tintColor = UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        navigationItem.rightBarButtonItem?.customView = loadingButton // Set as barButton's customView
        UIView.animate(withDuration: 1, delay: 0, options: .repeat, animations: {
            self.navigationItem.rightBarButtonItem?.customView?.transform = CGAffineTransform(rotationAngle: .pi)
                }, completion: nil)
    }
    //MARK: Choose Core ML Model
    // Calculated when referenced (lazy) and returns the current request to be performed
    lazy var classificationRequest: VNCoreMLRequest = {
        let visionModel = try! VNCoreMLModel(for: IngredientObjectDetector(configuration: .init()).model)
        
        // Specify model to be used
        let request = VNCoreMLRequest(model: visionModel) { [unowned self] request, _ in
            // Completion handler
            self.processObservations(for: request)
        }
        request.imageCropAndScaleOption = .centerCrop
        return request
    }()
    
    //MARK: Image Classifier Methods
//    func processObservations(for request: VNRequest) {
//        DispatchQueue.main.async {
//            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Store", style: .plain, target: self, action: #selector(self.storeObject))
//        }
//
//        // Process UI changes on main thread
//        DispatchQueue.main.async {
//            // Assign most confident observation to "result"
//            guard let result = request.results?.first as? VNClassificationObservation else { return }
//
//            self.navigationItem.rightBarButtonItem?.isEnabled = true
//
//            let object = result.identifier
//            let firstObject: String
//
//            // Remove all synonyms
//            if let firstIndexOfComma = object.firstIndex(of: ",") {
//                firstObject = String(object[..<firstIndexOfComma])
//            } else {
//                firstObject = object
//            }
//            self.navigationItem.title = "\(firstObject)"
//        }
//    }
    
    //MARK: Object Detector Methods
    func processObservations(for request: VNRequest) {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Store", style: .plain, target: self, action: #selector(self.storeObject))
        }
        
        // Process UI changes on main thread
        DispatchQueue.main.async {
            // Assign most confident observation to "result"
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }

            if results.count == 0 {
                self.navigationItem.title = "No Objects Detected"
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                // Choose the most confident object for each detection and stop repeats by checking to see if the label already contains that object
                self.navigationItem.title = ""
                var text = ""
                for object in results {
                    if text.contains(object.labels[0].identifier) == false {
                        text += "\(object.labels[0].identifier), "
                    }
                    self.draw(rectangle: object.boundingBox, onImageWithBounds: self.imageView.contentClippingRect) // Add in bounding boxes
                }
                self.navigationItem.title = text
                // Remove last comma
                if self.navigationItem.title!.contains(",") {
                    self.navigationItem.title!.removeLast()
                }
            }
        }
    }
    
    //MARK: Bounding Box Setup
    
    func draw(rectangle: CGRect, onImageWithBounds bounds: CGRect) {
        CATransaction.begin()
        let rectBox = boundingBox(forRegionOfInterest: rectangle, withinImageBounds: bounds)
        let rectLayer = shapeLayer(color: .init(red: 0, green: 1, blue: 0, alpha: 1), frame: rectBox)
        
        // Add to pathLayer on top of image.
        imageView.layer.addSublayer(rectLayer)
        CATransaction.commit()
    }
    
    func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {
        
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = forRegionOfInterest
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2
        
        // Vary the line color according to input.
        layer.borderColor = color.cgColor
        
        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true
        
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        
        return layer
    }
    
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }

        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = bounds.width / bounds.height

        var scaledSize: CGSize = .zero
        var origin: CGPoint = .zero

        if imageAspectRatio > viewAspectRatio {
            // Fit horizontally
            scaledSize.width = bounds.width
            scaledSize.height = bounds.width / imageAspectRatio
            origin.y = (bounds.height - scaledSize.height) / 2.0
        } else {
            // Fit vertically or perfectly
            scaledSize.height = bounds.height
            scaledSize.width = bounds.height * imageAspectRatio
            origin.x = (bounds.width - scaledSize.width) / 2.0
        }

        return CGRect(origin: origin, size: scaledSize)
    }
}
