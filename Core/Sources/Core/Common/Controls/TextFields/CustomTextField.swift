//
//  CustomTextField.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomTextField: View {
    
    @FocusState private var isFocused: Bool
    
    var title: String?
    var placeholder: String
    @Binding var value: String
    @Binding var checker: ViewChecker
    var borderStateColor: ColorStyle
    var needsCapitalization: Bool
    var isOptional: Bool
    var leadingValue: CGFloat
    var hasChevron: Bool
    var disable: Bool
    public var leftIcon: Image?
    public var rightIcon: Image?
    
    // New properties for border customization
    var defaultBorderColor: ColorStyle = .surface
    var focusedBorderColor: ColorStyle = .primary
    var activeBorderColor: ColorStyle = .primary
    
    public init(title: String? = nil,
                placeholder: String = "",
                value: Binding<String>,
                checker: Binding<ViewChecker> = .constant(.emptyChecker),
                borderStateColor: ColorStyle = .surface,
                needsCapitalization: Bool = false,
                isOptional: Bool = false,
                leadingValue: CGFloat = 14,
                hasChevron: Bool = false,
                disable: Bool = false,
                leftIcon: Image? = nil,
                rightIcon: Image? = nil,
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
        self.hasChevron = hasChevron
        self.disable = disable
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
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
            
            // TextField
            TextField(placeholder, text: $value)
                .multilineTextAlignment(.leading)
                .customStyle(.bodySmall, .black)
                .autocorrectionDisabled()
                .textInputAutocapitalization(needsCapitalization ? .none : .never)
                .padding(.leading, leftIcon == nil ? leadingValue : 0)
                .padding(.vertical, 16)
                .padding(.trailing, trailingPadding)
            
            if hasChevron {
                Image.chevronDown
                    .customForeground(.onSurface)
                    .padding(.trailing, 10)
            } else if let rightIcon = rightIcon {
                rightIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .customForeground(.onSurface)
                    .padding(.trailing, 10)
            }
        }
        .frame(height: 48)
        .withCardBorder(backgroundColor: .white,
                        cornerRadius: 8,
                        borderColor: borderColor)
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: value.isEmpty)
    }
    
    // Calculate trailing padding based on what icon is present
    private var trailingPadding: CGFloat {
        if hasChevron || rightIcon != nil {
            return 38
        } else {
            return 14
        }
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
        if isFocused {
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
    CustomTextFieldTest()
}

struct CustomTextFieldTest: View {
    
    @State var value = ""
    @State var emailValue = ""
    @State var passwordValue = ""
    @State var filledValue = "Filled Text"
    
    @State var normalChecker = ViewChecker(state: .normal, messages: [.correct : "Correct", .wrong : "Wrong", .empty : "Empty", .normal : "Normal"])
    
    @State var errorChecker = ViewChecker(state: .wrong, messages: [.correct : "Correct", .wrong : "This field has an error", .empty : "Empty", .normal : "Normal"])
    
    @State var successChecker = ViewChecker(state: .correct, messages: [.correct : "Looks good!", .wrong : "Wrong", .empty : "Empty", .normal : "Normal"])
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("CustomTextField with Right Icon")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Default field without icons
                CustomTextField(
                    title: "Default State",
                    placeholder: "Type here to see border change",
                    value: $value,
                    checker: $normalChecker
                )
                
                // Field with left icon only
                CustomTextField(
                    title: "Email Address",
                    placeholder: "Enter your email",
                    value: $emailValue,
                    checker: $normalChecker,
                    leftIcon: Image(systemName: "envelope")
                )
                
                // Field with right icon only
                CustomTextField(
                    title: "Search Field",
                    placeholder: "Search...",
                    value: $value,
                    checker: $normalChecker,
                    rightIcon: Image(systemName: "magnifyingglass")
                )
                
                // Field with both left and right icons
                CustomTextField(
                    title: "Password",
                    placeholder: "Enter password",
                    value: $passwordValue,
                    checker: $normalChecker,
                    leftIcon: Image(systemName: "lock"),
                    rightIcon: Image(systemName: "eye")
                )
                
                // Field with right icon (chevron takes priority)
                CustomTextField(
                    title: "Dropdown with Chevron Priority",
                    placeholder: "Chevron shows instead of icon",
                    value: $filledValue,
                    checker: $normalChecker,
                    hasChevron: true,
                    rightIcon: Image(systemName: "star") // This won't show because hasChevron is true
                )
                
                // Field with right icon only (no chevron)
                CustomTextField(
                    title: "Right Icon Only",
                    placeholder: "Custom icon shows",
                    value: $value,
                    checker: $normalChecker,
                    rightIcon: Image(systemName: "checkmark.circle")
                )
                
                // Error state with right icon
                CustomTextField(
                    title: "Error with Right Icon",
                    placeholder: "This field has an error",
                    value: $value,
                    checker: $errorChecker,
                    rightIcon: Image(systemName: "exclamationmark.triangle")
                )
                
                // Success state with right icon
                CustomTextField(
                    title: "Success with Right Icon",
                    placeholder: "This field is validated",
                    value: $filledValue,
                    checker: $successChecker,
                    rightIcon: Image(systemName: "checkmark.circle.fill")
                )
            }
            .padding(.horizontal)
        }
    }
}
