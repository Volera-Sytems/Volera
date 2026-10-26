import SwiftUI

struct AppSidebar: View {
    @Binding var destination: AppDestination
    let accent: Color

    var body: some View {
        List(selection: $destination) {
            Section("Volera") {
                ForEach(AppDestination.allCases) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .tint(accent)
        .navigationSplitViewColumnWidth(min: 180, ideal: 208, max: 260)
    }
}
