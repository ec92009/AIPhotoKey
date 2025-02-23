# AIPhotoKey

AIPhotoKey is a powerful macOS application that revolutionizes photo organization using AI technology. It helps you scan, analyze, and categorize your photo collection, making it easier to find and manage your images.

## Features

### Photo Scanning
- Fast recursive directory scanning
- Support for multiple image formats:
  - Standard: JPG, JPEG, PNG, HEIC, HEIF, GIF, TIFF, TIF, BMP
  - RAW: RAW, CR2, CR3, NEF, ARW, DNG, ORF, RW2, PEF, SRW
  - Professional: PSD, PSB
- Real-time scanning progress and status updates
- Pause and resume scanning capability
- Automatic handling of large photo collections (>3000 photos)

### AI Analysis
- Multiple AI model selection options
- Adjustable confidence threshold (0-100%)
- Intelligent photo categorization
- Fast processing with batch operations
- Preview thumbnails with confidence scores
- Detailed image metadata display

### User Interface
- Modern SwiftUI interface with native macOS look and feel
- Interactive controls for scanning and analysis
- Real-time results display with thumbnails
- Status line for operation feedback
- Easy directory selection with native folder picker
- Clear database option for fresh starts
- Popup view with 512x512 thumbnails showing:
  - High-quality image preview
  - Confidence percentage
  - File name

### Session Management
- Persistent session preferences across app launches:
  - Last used photos source folder
  - Selected AI model
  - Confidence threshold setting
- Preferences automatically saved using macOS UserDefaults
- Easy preference management via defaults command-line tool

## Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ec92009/AIPhotoKey.git
   cd AIPhotoKey
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open the generated Xcode project:
   ```bash
   open AIPhotoKey.xcodeproj
   ```

### Managing Preferences

You can view or modify app preferences using the defaults command:

```bash
# View all preferences
defaults read com.aiphotokey.AIPhotoKey

# View photos source folder
defaults read com.aiphotokey.AIPhotoKey photosSourceFolder

# Set photos source folder
defaults write com.aiphotokey.AIPhotoKey photosSourceFolder "/path/to/photos"

# Reset all preferences
defaults delete com.aiphotokey.AIPhotoKey
```

## Current State

The application is fully functional with the following key features implemented:
- Complete photo scanning system with pause/resume capability
- AI model integration with adjustable confidence settings
- Persistent session preferences
- Modern UI with thumbnail previews and detailed image information
- Real-time scanning status updates
- Comprehensive error handling and user feedback

## Next Steps

Planned improvements include:
- Additional AI models for enhanced photo analysis
- Batch processing optimization
- Advanced filtering and search capabilities
- Export functionality for analysis results
- Integration with Photos.app and other image management tools

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is private and proprietary. All rights reserved.

## Acknowledgments

- Built with SwiftUI
- Uses XcodeGen for project management
- Implements native macOS design patterns
