import SwiftUI
import CoreImage.CIFilterBuiltins

struct SurveyCreatedSuccessView: View {
    let survey: Survey
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Success animation placeholder
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.top)
                    
                    VStack(spacing: 12) {
                        Text("Survey Created!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(survey.title)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // QR Code
                    VStack(spacing: 16) {
                        Text("Share this QR code")
                            .font(.headline)
                        
                        if let qrImage = generateQRCode(from: survey.shareURL.absoluteString) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        }
                        
                        Text("or share the link")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Share URL
                    VStack(spacing: 12) {
                        HStack {
                            Text(survey.shareURL.absoluteString)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            
                            Button {
                                copyToClipboard()
                            } label: {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        if copiedToClipboard {
                            Text("Copied to clipboard!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Important reminder
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remember")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Results will only be visible after \(survey.minResponses) people respond")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share Survey", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showShareSheet) {
                if let qrImage = generateQRCode(from: survey.shareURL.absoluteString) {
                    ShareSheet(items: [
                        survey.shareURL,
                        qrImage,
                        "Please take my survey: \(survey.title)\n\nYour feedback is completely anonymous.\n\n\(survey.shareURL.absoluteString)"
                    ])
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                
                // Scale up the image
                let scale: CGFloat = 10
                let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
                uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return scaledImage
            }
        }
        
        return nil
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = survey.shareURL.absoluteString
        
        withAnimation {
            copiedToClipboard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedToClipboard = false
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SurveyCreatedSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyCreatedSuccessView(
            survey: Survey(
                id: "1",
                userId: "1",
                templateType: .individual,
                minResponses: 10,
                urlToken: "abc123def456",
                createdAt: Date(),
                title: "Q4 Performance Review",
                questions: []
            )
        )
    }
} 