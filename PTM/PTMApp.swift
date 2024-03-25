import SwiftUI

@main
struct PTMApp: App {
    @State var isShowingSettingsWindow = false
    
    var body: some Scene {
        WindowGroup {
            ContentView().toolbar {
                ToolbarItemGroup(placement: .primaryAction, content: {
                    Button(action: {self.isShowingSettingsWindow = true}, label: {
                        Image(systemName: "gear")
                        Text(verbatim: "Ustawienia")
                    }).sheet(isPresented: $isShowingSettingsWindow, content: {
                        SettingsWindow(isShowingSettingsWindow: $isShowingSettingsWindow)
                    })
                })
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
    }
}
