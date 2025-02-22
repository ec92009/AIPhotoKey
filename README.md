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

### User Interface
- Modern SwiftUI interface with native macOS look and feel
- Interactive controls for scanning and analysis
- Real-time results display
- Status line for operation feedback
- Easy directory selection with native folder picker
- Clear database option for fresh starts

## Getting Started

### Prerequisites
- macOS 11.0 or later
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

4. Build and run the application in Xcode

## Project Structure

### Core Components
- `PhotoScanner`: Core scanning engine for recursive photo discovery
- `ContentView`: Main application view orchestrating all components
- `ControlButtonsView`: UI controls for scanning operations
- `ResultsView`: Display of scanned photo results

### UI Components
- `TitleView`: Application header and version display
- `PhotosSourceView`: Directory selection interface
- `ModelSelectionView`: AI model selection interface
- `ConfidenceSliderView`: Confidence threshold adjustment
- `StatusLineView`: Operation status display
- `FolderPicker`: Native macOS folder selection

## Usage

1. Launch AIPhotoKey
2. Select your photos directory using the folder picker
3. Choose your preferred AI model
4. Adjust the confidence threshold as needed
5. Click "Scan" to begin processing
6. Use the pause/resume button to control scanning
7. View results in real-time as photos are processed

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is private and proprietary. All rights reserved.

## Acknowledgments

- Built with SwiftUI
- Uses XcodeGen for project management
- Implements native macOS design patterns
