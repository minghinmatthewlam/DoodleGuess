import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Settings")
                        .font(Brand.display(30, weight: .bold))
                        .foregroundColor(Brand.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    BrandCard {
                        VStack(alignment: .leading, spacing: 10) {
                            BrandPill(text: "PARTNER")
                            Text("Partner")
                                .font(Brand.text(14, weight: .semibold))
                                .foregroundColor(Brand.inkSoft)
                            Text(app.pairing.partner?.name ?? "Not connected")
                                .font(Brand.text(18, weight: .semibold))
                                .foregroundColor(Brand.ink)
                        }
                    }

                    BrandCard {
                        VStack(alignment: .leading, spacing: 12) {
                            BrandPill(text: "CONNECTION")
                            Text("Connection")
                                .font(Brand.text(14, weight: .semibold))
                                .foregroundColor(Brand.inkSoft)

                            Button(role: .destructive) {
                                Task {
                                    if let me = app.auth.currentUser?.id {
                                        try? await app.pairing.disconnect(currentUserId: me)
                                    }
                                }
                            } label: {
                                Text("Disconnect")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(DangerButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
