//
//  CameraImagePicker.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import SwiftUI
import UIKit


struct CameraImagePicker: UIViewControllerRepresentable {
    
    @Binding var pickerImage: ImagePickerImage
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let imagePicker: CameraImagePicker
        
        init(_ imagePicker: CameraImagePicker) {
            self.imagePicker = imagePicker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.editedImage] as? UIImage {
                
                guard let data = image.jpegData(compressionQuality: 0.1), let compressedImage = UIImage(data: data) else {
                    
                    return
                }
                
                imagePicker.pickerImage.image = compressedImage
                imagePicker.pickerImage.imageData = data
            }
            
            picker.dismiss(animated: true)
        }
    }
}
