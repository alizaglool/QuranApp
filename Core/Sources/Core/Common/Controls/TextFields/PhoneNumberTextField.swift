//
//  PhoneNumberTextField.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct PhoneNumberTextField: View {
    
    @FocusState private var isFocused: Bool
    
    var title: String?
    
    var placeholder: String
    
    @Binding var value: String
    
    @Binding var checker: ViewChecker
    
    @Binding var selectedCountry: String
    
    var selectedAction: EmptyAction
    
    var borderStateColor: ColorStyle
    
    var isOptional: Bool
    
    var leadingValue: CGFloat
    
    var disable: Bool
    
    // New parameter for left icon
    var leftIcon: Image?
    
    public init(title: String? = nil,
                placeholder: String = "",
                value: Binding<String>,
                checker: Binding<ViewChecker> = .constant(.emptyChecker),
                selectedCountry: Binding<String>,
                selectedAction: EmptyAction = nil,
                borderStateColor: ColorStyle = .surface,
                leftIcon: Image? = nil,
                isOptional: Bool = false,
                leadingValue: CGFloat = 14,
                disable: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._value = value
        self._checker = checker
        self._selectedCountry = selectedCountry
        self.selectedAction = selectedAction
        self.borderStateColor = borderStateColor
        self.isOptional = isOptional
        self.leadingValue = leadingValue
        self.disable = disable
        self.leftIcon = leftIcon
    }
    
    public var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            if title != nil {
                titleView
            }
            
            HStack(spacing: 0) {
                // Left icon
                if let leftIcon = leftIcon {
                    leftIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .customForeground(.onSurface)
                        .padding(.leading, leadingValue)
                        .padding(.trailing, 8)
                }
                
                // Country code section
//                countryCode
                
                // Phone number text field
                textField
            }
            .frame(height: 48)
            .withCardBorder(backgroundColor: .white,
                            cornerRadius: 8,
                            borderColor: borderColor)
            .focused($isFocused)
            
            if checker.state == .wrong {
                ErrorText(text: checker.message)
            }
        }
        .disabled(disable)
    }
    
    private var titleView: some View {
        HStack(spacing: 4) {
            
            Text(title!)
                .customStyle(.subheadline, .onSurface)
            
            if isOptional {
                
                Text("()")
                    .customStyle(.caption1, .subtitle)
            }
        }
    }
    
    private var textField: some View {
        TextField(placeholder, text: $value)
            .multilineTextAlignment(.leading)
            .customStyle(.bodySmall, .black)
            .autocorrectionDisabled()
            .keyboardType(.phonePad)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
            .focused($isFocused)
            .onChange(of: value) { newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    value = filtered
                }
            }
    }
    
    private var countryCode: some View {
        Button {
            selectedAction?()
            isFocused = false
        } label: {
            HStack(spacing: 4) {
                Text(selectedCountry)
                    .customStyle(.bodySmall, .onSurface)
                
                Image.chevronDown
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .customForeground(.onSurface)
            }
            .padding(.leading, leftIcon == nil ? leadingValue : 0)
            .padding(.trailing, 8)
            .padding(.vertical, 16)
        }
        .frame(width: 80)
    }
    
    private var borderColor: ColorStyle {
        switch checker.state {
        case .correct:
            return borderStateColor
        case .normal:
            return value.isEmpty ? .secondary : borderStateColor
        case .wrong:
            return .error
        case .empty:
            return .surface
        }
    }
}

#Preview {
    PhoneNumberTextFieldTest()
}

struct PhoneNumberTextFieldTest: View {
    
    @State var phoneValue = ""
    @State var phoneValue2 = "1121491064"
    @State var selectedCountry = "+20"
    
    @State var checker = ViewChecker(
        state: .correct,
        messages: [
            .correct: "Valid phone number",
            .wrong: "Invalid phone number format",
            .empty: "Phone number is required",
            .normal: ""
        ]
    )
    
    @State var checker2 = ViewChecker(
        state: .wrong,
        messages: [
            .correct: "Phone number verified",
            .wrong: "Please enter a valid phone number",
            .empty: "Mobile number is required",
            .normal: ""
        ]
    )
    
    @State var checker3 = ViewChecker(
        state: .normal,
        messages: [
            .correct: "Correct",
            .wrong: "Wrong",
            .empty: "Empty",
            .normal: "Normal"
        ]
    )
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Phone field with correct state (green border)
            PhoneNumberTextField(
                value: $phoneValue2,
                checker: $checker,
                selectedCountry: $selectedCountry,
                borderStateColor: .primary
            )
            
            // Phone field with wrong state (red border + error)
            PhoneNumberTextField(
                title: "Mobile Number",
                placeholder: "Enter phone number",
                value: $phoneValue,
                checker: $checker2,
                selectedCountry: $selectedCountry,
                borderStateColor: .primary
            )
            
            // Phone field with normal state
            PhoneNumberTextField(
                title: "Phone Number",
                placeholder: "Mobile Number",
                value: $phoneValue,
                checker: $checker3,
                selectedCountry: $selectedCountry,
                borderStateColor: .primary,
                leftIcon: Image(systemName: "phone")
            )
            
            // Optional phone field
            PhoneNumberTextField(
                title: "Alternative Number",
                placeholder: "Mobile Number",
                value: $phoneValue,
                checker: $checker3,
                selectedCountry: $selectedCountry,
                borderStateColor: .secondary,
                leftIcon: Image(systemName: "phone.fill"),
                isOptional: true
            )
        }
        .padding(.horizontal)
    }
}
