# TextFieldTrans

## Overview
TextFieldTrans is a macOS utility application that provides instant text translation capabilities directly from any text field on your system. With a simple keyboard shortcut (Command+Shift+E), you can translate text in any active text input field without having to copy and paste or switch between applications.

## Features
- **Instant Translation**: Translate text in any focused text field with a global keyboard shortcut
- **Seamless Integration**: Works with any application that uses standard macOS text fields
- **Customizable API Endpoint**: Configure your preferred translation API
- **Application Sandboxing**: Secure implementation with proper macOS entitlements
- **Detailed Logging**: Activity logging for troubleshooting

## How It Works
TextFieldTrans uses macOS Accessibility APIs to detect the currently focused text field, retrieves its content, sends it to a configured translation API endpoint, and then replaces the original text with the translated version - all with a single keyboard shortcut.

## Requirements
- macOS 10.15 or later
- Network connection (for API access)
- Accessibility permissions (required to access text fields in other applications)

## Getting Started
1. Download and install TextFieldTrans
2. Launch the application
3. Enter your translation API endpoint URL
4. Grant Accessibility permissions when prompted
5. Use Command+Shift+E in any text field to translate text

## Privacy
TextFieldTrans only accesses text from fields when you explicitly trigger the translation shortcut. All text is sent only to the API endpoint you configure, and no text is stored by the application itself.


