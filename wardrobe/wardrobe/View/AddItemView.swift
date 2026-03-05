//
//  AddItemView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddItemViewModel
    @ObservedObject var closetViewModel: ClosetViewModel  // Changed from StateObject
    
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false  // Add this
    @State private var showError = false  // Add this
    
    init(userId: String, closetViewModel: ClosetViewModel) {
        let visionService = VisionService()
        _viewModel = StateObject(wrappedValue: AddItemViewModel(
            visionService: visionService,
            userId: userId
        ))
        self.closetViewModel = closetViewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FAFAF8")
                    .ignoresSafeArea()
                
                if viewModel.capturedImage == nil {
                    // Camera/Photo Selection Screen
                    captureScreen
                } else {
                    // Edit Screen
                    editScreen
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    Task {
                        await viewModel.processImage(image)
                    }
                    showCamera = false
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.processImage(image)
                    }
                }
            }
        }
    }
    
    // MARK: - Capture Screen
    
    private var captureScreen: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#A8B5A3"))
            
            VStack(spacing: 12) {
                Text("Add a Clothing Item")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D2D2D"))
                
                Text("Take a photo or choose from your library")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Instructions Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Tips for best results:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D2D2D"))
                
                instructionRow(icon: "sun.max.fill", text: "Use good lighting")
                instructionRow(icon: "square.dashed", text: "Place item on flat surface")
                instructionRow(icon: "camera.viewfinder", text: "Center the item in frame")
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#A8B5A3"))
                    .cornerRadius(12)
                }
                
                Button {
                    showPhotoPicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Choose from Library")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D2D2D"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#2D2D2D"), lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#A8B5A3"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#2D2D2D"))
        }
    }
    
    // MARK: - Edit Screen
    
    private var editScreen: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image Preview
                imagePreviewSection
                
                // Processing Indicator
                if viewModel.isProcessing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Processing image...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                
                // Category Picker
                categorySection
                
                // Colors
                colorsSection
                
                // Seasons
                seasonsSection
                
                // Occasions
                occasionsSection
                
                // Brand
                brandSection
                
                // Notes
                notesSection
                
                // Save Button
                // Save Button (replace the existing one)
                Button {
                    Task {
                        await saveItem()
                    }
                } label: {
                    if isSaving {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Saving...")
                        }
                    } else {
                        Text("Save to Closet")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSaving ? Color.gray : Color(red: 168/255, green: 181/255, blue: 163/255))
                .cornerRadius(12)
                .disabled(isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .alert("Error Saving Item", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "Unknown error")
                }
            }
            .padding(.top, 20)
        }
    }
    
    // In AddItemView.swift, add this right after the image preview section:

    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            if let image = viewModel.processedImage ?? viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .background(Color(red: 245/255, green: 241/255, blue: 237/255))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
            
            HStack(spacing: 12) {
                Button {
                    viewModel.reset()
                } label: {
                    Text("Retake Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                }
                
                // Add this divider and toggle
                Text("•")
                    .foregroundColor(.gray)
                
                Toggle(isOn: $viewModel.useBackgroundRemoval) {
                    Text("Remove Background")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 168/255, green: 181/255, blue: 163/255)))
                .onChange(of: viewModel.useBackgroundRemoval) { newValue in
                    // Reprocess image when toggle changes
                    if let image = viewModel.capturedImage {
                        Task {
                            await viewModel.processImage(image)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Picker("Category", selection: $viewModel.category) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Colors")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            if viewModel.detectedColors.isEmpty {
                Text("No colors detected")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.detectedColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seasons")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            FlowLayout(spacing: 8) {
                ForEach(Season.allCases, id: \.self) { season in
                    SelectableChip(
                        title: season.rawValue.capitalized,
                        isSelected: viewModel.selectedSeasons.contains(season)
                    ) {
                        if viewModel.selectedSeasons.contains(season) {
                            viewModel.selectedSeasons.remove(season)
                        } else {
                            viewModel.selectedSeasons.insert(season)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var occasionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Occasions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            FlowLayout(spacing: 8) {
                ForEach(Occasion.allCases, id: \.self) { occasion in
                    SelectableChip(
                        title: occasion.rawValue.capitalized,
                        isSelected: viewModel.selectedOccasions.contains(occasion)
                    ) {
                        if viewModel.selectedOccasions.contains(occasion) {
                            viewModel.selectedOccasions.remove(occasion)
                        } else {
                            viewModel.selectedOccasions.insert(occasion)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brand (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            TextField("Enter brand", text: $viewModel.brand)
                .font(.system(size: 16))
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 20)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            TextEditor(text: $viewModel.notes)
                .font(.system(size: 16))
                .frame(height: 100)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .foregroundColor(.black)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    
    private func cropToSquare(_ image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        let squareSize = min(originalWidth, originalHeight)
        
        let x = (originalWidth - squareSize) / 2
        let y = (originalHeight - squareSize) / 2
        
        let cropRect = CGRect(x: x, y: y, width: squareSize, height: squareSize)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func saveItem() async {
        guard !isSaving else { return }
        isSaving = true
        
        print("🔵 Save item started")
        
        guard let originalImage = viewModel.processedImage ?? viewModel.capturedImage else {
            print("🔴 No image available")
            isSaving = false
            return
        }
        
        // Crop to square
        let image = cropToSquare(originalImage)
        
        print("🔵 Image cropped to square, creating item...")
        let item = viewModel.createItem()
        print("🔵 Item created with ID: \(item.id ?? "NO ID")")
        
        do {
            print("🔵 Attempting to add item to closet...")
            try await closetViewModel.addItem(item, image: image)
            print("✅ Item added successfully!")
            
            isSaving = false
            dismiss()
        } catch {
            print("🔴 Error saving item: \(error)")
            print("🔴 Error details: \(error.localizedDescription)")
            
            viewModel.error = error
            showError = true
            isSaving = false
        }
    }
}

// MARK: - Selectable Chip Component

struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#2D2D2D"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#A8B5A3") : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Flow Layout (for wrapping chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
