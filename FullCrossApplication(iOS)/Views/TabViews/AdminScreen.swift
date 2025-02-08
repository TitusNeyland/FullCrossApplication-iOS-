import SwiftUI

struct AdminScreen: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var streamUrl = ""
    @State private var monthlyTheme = ""
    @State private var showSuccessMessage = false
    @State private var showAddPreviousService = false
    @State private var selectedDate = Date()
    @State private var previousServiceUrl = ""
    
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
                
                // Monthly Theme Card
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Monthly Theme")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Enter this month's theme", text: $monthlyTheme)
                                .textFieldStyle(.roundedBorder)
                                .disabled(viewModel.isLoading)
                        }
                        
                        HStack {
                            Spacer()
                            Button {
                                Task {
                                    await viewModel.updateMonthlyTheme(monthlyTheme)
                                    showSuccessMessage = true
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save Theme")
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding()
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
                
                // Previous Services Card
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Previous Services")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button {
                                showAddPreviousService = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        if let settings = viewModel.streamSettings,
                           !settings.previousServices.isEmpty {
                            ForEach(settings.previousServices.sorted(by: { $0.date > $1.date })) { service in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(formatDate(service.date))
                                            .font(.headline)
                                        Text(service.url)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        Task {
                                            await viewModel.deletePreviousService(service.id)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 8)
                                Divider()
                            }
                        } else {
                            Text("No previous services added")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddPreviousService) {
            NavigationView {
                Form {
                    DatePicker("Service Date", selection: $selectedDate, displayedComponents: [.date])
                    TextField("Service URL", text: $previousServiceUrl)
                }
                .navigationTitle("Add Previous Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddPreviousService = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            Task {
                                await viewModel.addPreviousService(
                                    date: selectedDate,
                                    url: previousServiceUrl
                                )
                                showAddPreviousService = false
                                previousServiceUrl = ""
                            }
                        }
                        .disabled(previousServiceUrl.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadStreamSettings()
        }
        .onChange(of: viewModel.streamSettings) { settings in
            if let url = settings?.streamUrl {
                streamUrl = url
            }
            monthlyTheme = settings?.monthlyTheme ?? ""
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


