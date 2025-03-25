//
//  PhoneNumberTextField.swift
//  Yes
//
//  Created by justin casler on 3/22/25.
//

import SwiftUI
import UIKit

struct PhoneNumberTextField: UIViewRepresentable {
    @Binding var rawText: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextField

        init(_ parent: PhoneNumberTextField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get the current text
            let currentText = textField.text ?? ""
            // Determine the range in the current text
            guard let textRange = Range(range, in: currentText) else { return false }
            // Create the updated text based on the proposed change
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            // Remove any non-digit characters
            let digits = updatedText.filter { $0.isNumber }
            // Save the raw digits in the binding
            parent.rawText = digits
            // Format the digits into the desired style
            let formatted = formatPhoneNumber(from: digits)
            // Set the text field’s text to the formatted string
            textField.text = formatted

            // For simplicity, move the caret to the end of the text.
            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: formatted.count) {
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
            
            // Return false because we have manually updated the text.
            return false
        }
        
        /// Formats a string of digits into (123) 456-7890 style.
        func formatPhoneNumber(from number: String) -> String {
            var result = ""
            let count = number.count
            let array = Array(number)
            
            if count > 0 {
                result.append("(")
                for i in 0..<min(count, 3) {
                    result.append(array[i])
                }
                if count >= 3 {
                    result.append(") ")
                }
            }
            
            if count > 3 {
                for i in 3..<min(count, 6) {
                    result.append(array[i])
                }
            }
            
            if count > 6 {
                result.append("-")
                for i in 6..<min(count, 10) {
                    result.append(array[i])
                }
            }
            return result
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.keyboardType = .phonePad
        textField.delegate = context.coordinator
        textField.textColor = .black
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        let formatted = context.coordinator.formatPhoneNumber(from: rawText)
        if uiView.text != formatted {
            uiView.text = formatted
        }
    }
}
