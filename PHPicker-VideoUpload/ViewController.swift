//
//  ViewController.swift
//  PHPicker-VideoUpload
//
//  Created by Jason Dubon on 4/1/23.
//

import UIKit
import PhotosUI
import FirebaseStorage

class ViewController: UIViewController {

    lazy var uploadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(systemName: "photo.artframe")
        imageView.tintColor = .systemGray
        
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapUploadImage))
        imageView.addGestureRecognizer(gesture)
        return imageView
    }()
    
    let storage = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureUI()
    }

    private func configureUI() {
        view.addSubview(uploadImageView)
        
        NSLayoutConstraint.activate([
            uploadImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            uploadImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadImageView.widthAnchor.constraint(equalToConstant: 300),
            uploadImageView.heightAnchor.constraint(equalToConstant: 250),
        
        ])
        
    }

    @objc func didTapUploadImage() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        let photoPicker = PHPickerViewController(configuration: configuration)
        photoPicker.delegate = self
        present(photoPicker, animated: true)
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider else { return }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] fileURL, error in
                guard let fileURL = fileURL, error == nil else { return }
                
                self?.uploadVideoToStorage(videoURL: fileURL) { downloadURLString in
                    guard let downloadURLString = downloadURLString else {
                        print("noooo")
                        return
                    }
                    print(downloadURLString)
                    print("yaaay")
                }
            }
        }
    }
        
    func uploadVideoToStorage(videoURL: URL, completion: @escaping (String?) -> Void) {
        guard let videoData = try? Data(contentsOf: videoURL) else {
            print("unable to create video data")
            completion(nil)
            return
        }
        
        let fileName = videoURL.lastPathComponent
        let videoRef = storage.child("videos/\(fileName)")
        
        videoRef.putData(videoData) { metadata, error in
            guard let metadata = metadata, error == nil else {
                print("error uploading to firebase storage")
                completion(nil)
                return
            }
            
            videoRef.downloadURL { downloadURL, error in
                guard let downloadURL = downloadURL, error == nil else {
                    completion(nil)
                    return
                }
                
                completion(downloadURL.absoluteString)
            }
        }
        
    }
    
}
