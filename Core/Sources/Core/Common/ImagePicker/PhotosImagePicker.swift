//
//  PhotosImagePicker.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI
import PhotosUI

struct PhotosImagePicker: UIViewControllerRepresentable {
    
    @Binding var pickerImage: ImagePickerImage
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(imagePicker: self)
    }
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        let imagePicker: PhotosImagePicker
        
        init(imagePicker: PhotosImagePicker) {
            self.imagePicker = imagePicker
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            if let itemProvider = results.first?.itemProvider {
                
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    
                    itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        
                        if let error {
                            print(error)
                        }
                        else if let image = image as? UIImage {
                            
                            guard let data = image.jpegData(compressionQuality: 0.1),
                                  let compressedImage = UIImage(data: data) else {
                                
                                return
                            }
                            
                            DispatchQueue.main.async { [weak self] in
                                self?.imagePicker.pickerImage.image = compressedImage
                                self?.imagePicker.pickerImage.imageData = data
                            }
                        }
                    }
                }
            }
            
            picker.dismiss(animated: true)
        }
    }
}
