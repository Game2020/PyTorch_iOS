import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var resultView: UITextView!

    private lazy var imagePicker = ImagePicker()

    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "model", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    private lazy var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Can't find the text file!")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self

        //        let image = UIImage(named: "image.png")!
        let image = UIImage(named: "IMG_2559.JPG")!
        predict(image: image)
    }

    func predict(image: UIImage) {
        imageView.image = image
        let resizedImage = image.resized(to: CGSize(width: 224, height: 224))
        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
        guard let outputs = module.predict(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
            return
        }
        let zippedResults = zip(labels.indices, outputs)
        let sortedResults = zippedResults.sorted { $0.1.floatValue > $1.1.floatValue }.prefix(3)
        var text = ""
        for result in sortedResults {
            text += "\u{2022} \(labels[result.0]) \n\n"
        }
        resultView.text = text
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        imagePicker.present(parent: self, sourceType: sourceType)
    }

    @IBAction func takePhoto(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.cameraButtonTapped(nil)
            }))

            alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                self.photoButtonTapped(nil)
            }))

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
        } else {
            photoButtonTapped(sender)
        }
    }

    @objc func photoButtonTapped(_ sender: UIButton?) { imagePicker.photoGalleryAsscessRequest() }
    @objc func cameraButtonTapped(_ sender: UIButton?) { imagePicker.cameraAsscessRequest() }
}

extension ViewController: ImagePickerDelegate {
    func imagePickerDelegate(didSelect image: UIImage, delegatedForm: ImagePicker) {
        predict(image: image)
        imagePicker.dismiss()
    }

    func imagePickerDelegate(didCancel delegatedForm: ImagePicker) { imagePicker.dismiss() }

    func imagePickerDelegate(canUseGallery accessIsAllowed: Bool, delegatedForm: ImagePicker) {
        if accessIsAllowed { presentImagePicker(sourceType: .photoLibrary) }
    }

    func imagePickerDelegate(canUseCamera accessIsAllowed: Bool, delegatedForm: ImagePicker) {
        // works only on real device (crash on simulator)
        if accessIsAllowed { presentImagePicker(sourceType: .camera) }
    }
}
