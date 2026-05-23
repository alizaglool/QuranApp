//
//  BarcodeView.swift
//  QuranApp
//
//  Created by Mohamed Mostafa on 9/19/25.
//


import SwiftUI
import CoreImage.CIFilterBuiltins

extension AddStockItemDetailsView {
    
    private var barCodeSection: some View {
        VStack(spacing: 16) {
            if let barcodeImage = generateGreenBarcode(from: "1234567890") {
                Image(uiImage: barcodeImage)
                    .interpolation(.none) // keeps it sharp
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
            } else {
                Text("Failed to generate barcode")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func generateGreenBarcode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Apply green color using CIFalseColor filter
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = outputImage
        colorFilter.color0 = CIColor(red: 0, green: 1, blue: 0) // Green for bars
        colorFilter.color1 = CIColor(red: 1, green: 1, blue: 1) // White background
        
        guard let coloredImage = colorFilter.outputImage,
              let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}
