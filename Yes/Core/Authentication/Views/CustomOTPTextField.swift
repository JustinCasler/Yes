//
//  CustomOTPTextField.swift
//  Yes
//
//  Created by justin casler on 3/22/25.
//

import SwiftUI
import UIKit

struct CustomOTPTextField: UIViewRepresentable {
    @Binding var text: String
    var index: Int
    @Binding var focusedIndex: Int?
    var onDeleteBackward: (() -> Void)?

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomOTPTextField

        init(parent: CustomOTPTextField) {
            self.parent = parent
        }
        
        // This delegate method captures changes to the text.
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            // Automatically move to next field when a digit is entered.
            if let text = textField.text, !text.isEmpty {
                DispatchQueue.main.async {
                    self.parent.focusedIndex = self.parent.index + 1
                }
            }
        }
        
        // This method intercepts character changes.
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            // Allow only one character.
            let currentText = textField.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
            if newText.count > 1 {
                return false
            }
            
            // Detect backspace when text is already empty.
            if currentText.isEmpty && string.isEmpty {
                DispatchQueue.main.async {
                    self.parent.onDeleteBackward?()
                }
                return false // We handle the deletion ourselves.
            }
            return true
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.parent.focusedIndex = parent.index
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.clear
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        if focusedIndex == index {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }
}
