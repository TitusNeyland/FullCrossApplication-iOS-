import SwiftUI

struct HelpAndFaqScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItems: Set<UUID> = []
    
    private var groupedFaqs: [String: [FaqItem]] {
        Dictionary(grouping: FaqItem.allItems) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(groupedFaqs.keys.sorted()), id: \.self) { category in
                    Section(header: Text(category).font(.headline)) {
                        if let items = groupedFaqs[category] {
                            ForEach(items) { item in
                                FaqCard(faqItem: item, isExpanded: expandedItems.contains(item.id)) {
                                    if expandedItems.contains(item.id) {
                                        expandedItems.remove(item.id)
                                    } else {
                                        expandedItems.insert(item.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FaqCard: View {
    let faqItem: FaqItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(faqItem.question)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(faqItem.answer)
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .padding(.vertical, 4)
    }
}

#Preview {
    HelpAndFaqScreen()
} 