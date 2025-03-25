//
//  OTPTextField.swift
//  Yes
//
//  Created by justin casler on 3/22/25.
//

import SwiftUI

struct OTPTextField: View {
    let numberOfFields: Int
    @Binding var enterValue: [String]
    @FocusState private var fieldFocus: Int?
    @State var oldValue = ""

    init(numberOfFields: Int, enterValue: Binding<[String]>) {
        self.numberOfFields = numberOfFields
        self._enterValue = enterValue
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<numberOfFields, id: \.self) { index in
                TextField("", text: $enterValue[index], onEditingChanged: { editing in
                    if editing {
                        oldValue = enterValue[index]
                    }
                })
                .keyboardType(.numberPad)
                .frame(width: 48, height: 48)
                .foregroundColor(.black)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                .multilineTextAlignment(.center)
                .focused($fieldFocus, equals: index)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 1)
                )
                .onChange(of: enterValue[index]) { newValue in
                    if !newValue.isEmpty {
                        if enterValue[index].count > 1 {
                            let currentValue = Array(enterValue[index])
                            if currentValue[0] == Character(oldValue) {
                                enterValue[index] = String(enterValue[index].suffix(1))
                            } else {
                                enterValue[index] = String(enterValue[index].prefix(1))
                            }
                        }
                        
                        // Move to next field or dismiss keyboard
                        if index == numberOfFields - 1 {
                            fieldFocus = nil
                        } else {
                            fieldFocus = (fieldFocus ?? 0) + 1
                        }
                    } else {
                        // Move focus back if field is cleared
                        fieldFocus = (fieldFocus ?? 0) - 1
                    }
                }
            }
        }
    }
}
