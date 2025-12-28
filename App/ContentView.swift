import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.tip")
                .font(.largeTitle)
            Text("DoodleGuess")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
