import SwiftUI

struct AdminScreen: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var streamUrl = ""
    @State private var showSuccessMessage = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.bottom)
                }
                
                // Stream Settings Card
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stream Settings")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Stream URL", text: $streamUrl)
                                .textFieldStyle(.roundedBorder)
                                .disabled(viewModel.isLoading)
                            
                            if let settings = viewModel.streamSettings {
                                Text("Last updated: \(formatDate(settings.lastUpdated))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Button {
                                Task {
                                    await viewModel.updateStreamUrl(streamUrl)
                                    showSuccessMessage = true
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save Changes")
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadStreamSettings()
        }
        .onChange(of: viewModel.streamSettings) { settings in
            if let url = settings?.streamUrl {
                streamUrl = url
            }
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Stream URL has been updated successfully.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm"
        return formatter.string(from: date)
    }
}


