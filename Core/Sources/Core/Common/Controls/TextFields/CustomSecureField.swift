//
//  CustomSecureField.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomSecureField: View {
    
    @FocusState private var isFocused: Bool
    
    enum FocusedField {
        case plain, secure
    }
    
    @FocusState private var focusedField: FocusedField?
    
    @State var isSecured: Bool = true
    
    var title: String?
    var placeholder: String
    @Binding var value: String
    @Binding var checker: ViewChecker
    var borderStateColor: ColorStyle
    var needsCapitalization: Bool
    var isOptional: Bool
    var leadingValue: CGFloat
    var disable: Bool
    var leftIcon: Image?
    
    // New properties for border customization
    var defaultBorderColor: ColorStyle = .surface
    var focusedBorderColor: ColorStyle = .primary
    var activeBorderColor: ColorStyle = .primary
    
    public init(title: String? = nil,
                placeholder: String = "",
                value: Binding<String>,
                checker: Binding<ViewChecker> = .constant(.emptyChecker),
                borderStateColor: ColorStyle = .secondary40,
                needsCapitalization: Bool = false,
                isOptional: Bool = false,
                leadingValue: CGFloat = 14,
                disable: Bool = false,
                leftIcon: Image? = nil,
                defaultBorderColor: ColorStyle = .secondary,
                focusedBorderColor: ColorStyle = .primary,
                activeBorderColor: ColorStyle = .primary) {
        self.title = title
        self.placeholder = placeholder
        self._value = value
        self._checker = checker
        self.borderStateColor = borderStateColor
        self.needsCapitalization = needsCapitalization
        self.isOptional = isOptional
        self.leadingValue = leadingValue
        self.disable = disable
        self.leftIcon = leftIcon
        self.defaultBorderColor = defaultBorderColor
        self.focusedBorderColor = focusedBorderColor
        self.activeBorderColor = activeBorderColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            if title != nil {
                titleView
            }
            
            textField
            
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
                Text("(Optional)")
                    .customStyle(.caption1, .subtitle)
            }
        }
    }
    
    private var textField: some View {
        HStack(spacing: 0) {
            if let leftIcon = leftIcon {
                leftIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .customForeground(.onSurface)
                    .padding(.leading, leadingValue)
                    .padding(.trailing, 8)
            }
            
            ZStack(alignment: .leading) {
                SecureField(placeholder, text: $value)
                    .customStyle(.bodySmall, .black)
                    .focused($focusedField, equals: .secure)
                    .opacity(isSecured ? 1 : 0)
                
                TextField(placeholder, text: $value)
                    .customStyle(.bodySmall, .black)
                    .focused($focusedField, equals: .plain)
                    .opacity(isSecured ? 0 : 1)
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(needsCapitalization ? .none : .never)
            .customStyle(.bodySmall, .background)
            .padding(.leading, leftIcon == nil ? leadingValue : 0)
            .padding(.vertical, 16)
            
            // Eye toggle button
            Button(action: {
                // Maintain focus when toggling visibility
                let wasFocused = focusedField != nil
                isSecured.toggle()
                
                if wasFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = isSecured ? .secure : .plain
                    }
                }
            }, label: {
                (isSecured ? Image.eye : Image.eyeSlash)
                    .customForeground(.onSurface)
            })
            .padding(.trailing, 16)
        }
        .frame(height: 48)
        .withCardBorder(backgroundColor: .white,
                        cornerRadius: 8,
                        borderColor: borderColor)
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFieldFocused)
        .animation(.easeInOut(duration: 0.2), value: value.isEmpty)
    }
    
    // Helper computed property to check if any field is focused
    private var isFieldFocused: Bool {
        focusedField != nil
    }
    
    private var borderColor: ColorStyle {
        // Priority: Error state first
        if checker.state == .wrong {
            return .error
        }
        
        // Success/Correct state
        if checker.state == .correct {
            return borderStateColor
        }
        
        // Focus state - when user is actively typing
        if isFieldFocused {
            return focusedBorderColor
        }
        
        // Active state - when field has content but not focused
        if !value.isEmpty {
            return activeBorderColor
        }
        
        // Default empty state
        return defaultBorderColor
    }
}

// Updated Preview
#Preview {
    TitledSecureFieldTest()
}

struct TitledSecureFieldTest: View {
    
    @State var value = ""
    @State var passwordValue = ""
    @State var filledPasswordValue = "password123"
    
    @State var normalChecker = ViewChecker(state: .normal, messages: [.correct : "Correct", .wrong : "Wrong", .empty : "Empty", .normal : "Normal"])
    
    @State var errorChecker = ViewChecker(state: .wrong, messages: [.correct : "Correct", .wrong : "Password must be at least 8 characters", .empty : "Empty", .normal : "Normal"])
    
    @State var successChecker = ViewChecker(state: .correct, messages: [.correct : "Strong password!", .wrong : "Wrong", .empty : "Empty", .normal : "Normal"])
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("CustomSecureField Border States")
                    .customStyle(.heading2)                    .fontWeight(.bold)
                    .padding(.top)
                
                // Empty field (default border)
                CustomSecureField(
                    title: "Default State",
                    placeholder: "Enter password to see border change",
                    value: $passwordValue,
                    checker: $normalChecker
                )
                
                // Field with content (active border)
                CustomSecureField(
                    title: "Field with Content",
                    placeholder: "This field has password",
                    value: $filledPasswordValue,
                    checker: $normalChecker
                )
                
                // Password field with lock icon
                CustomSecureField(
                    title: "Password with Icon",
                    placeholder: "Enter your password",
                    value: $passwordValue,
                    checker: $normalChecker,
                    leftIcon: Image(systemName: "lock")
                )
                
                // Error state
                CustomSecureField(
                    title: "Error State",
                    placeholder: "Password with error",
                    value: $passwordValue,
                    checker: $errorChecker,
                    leftIcon: Image(systemName: "lock")
                )
                
                // Success state
                CustomSecureField(
                    title: "Success State",
                    placeholder: "Valid password",
                    value: $filledPasswordValue,
                    checker: $successChecker,
                    leftIcon: Image(systemName: "lock")
                )
                
                // Custom border colors
                CustomSecureField(
                    title: "Custom Colors",
                    placeholder: "Custom border colors",
                    value: $passwordValue,
                    checker: $normalChecker,
                    leftIcon: Image(systemName: "key"),
                    defaultBorderColor: .surface,
                    focusedBorderColor: .secondary,
                    activeBorderColor: .secondary
                )
                
                // Without title but with icon
                CustomSecureField(
                    placeholder: "Confirm Password",
                    value: $passwordValue,
                    checker: $normalChecker,
                    leftIcon: Image(systemName: "lock.shield")
                )
                
                // Optional field
                CustomSecureField(
                    title: "Current Password",
                    placeholder: "Leave blank if new account",
                    value: $passwordValue,
                    checker: $normalChecker,
                    isOptional: true,
                    leftIcon: Image(systemName: "lock.open")
                )
            }
            .padding(.horizontal)
        }
    }
}
