import SwiftUI
import Combine

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var input: String = ""
    @Published var isSending: Bool = false

    private let client = AIApiClient()

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = AIMessage(id: UUID(), role: .user, text: trimmed, createdAt: Date())
        messages.append(userMessage)
        input = ""

        isSending = true

        Task {
            do {
                let responseText = try await client.send(messages: messages)
                let response = AIMessage(
                    id: UUID(),
                    role: .assistant,
                    text: responseText,
                    createdAt: Date()
                )
                messages.append(response)
            } catch {
                let fallback = AIMessage(
                    id: UUID(),
                    role: .assistant,
                    text: "I couldn’t reach the macro engine just now. Once your NVIDIA key and backend are configured, I’ll summarize today’s news and economic drivers in real time.",
                    createdAt: Date()
                )
                messages.append(fallback)
            }
            isSending = false
        }
    }
}

struct AIAssistantSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AIChatViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ZenithColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    List {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.role == .assistant {
                                    bubble(text: message.text, isUser: false)
                                    Spacer()
                                } else {
                                    Spacer()
                                    bubble(text: message.text, isUser: true)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(ZenithColors.background)
                        }
                    }
                    .listStyle(.plain)

                    inputBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ZenithColors.surfaceElevated.ignoresSafeArea(edges: .bottom))
                }
            }
            .navigationTitle("Zenith AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(ZenithColors.accent)
                }
            }
        }
        .onAppear {
            if viewModel.messages.isEmpty {
                let intro = AIMessage(
                    id: UUID(),
                    role: .assistant,
                    text: "I’m here to translate today’s macro landscape, economic events, and news into plain language so you can make deliberate decisions. Ask about today’s key drivers or any event on your calendar.",
                    createdAt: Date()
                )
                viewModel.messages.append(intro)
            }
        }
    }

    private func bubble(text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(10)
            .background(isUser ? ZenithColors.accent : ZenithColors.surface)
            .foregroundColor(isUser ? ZenithColors.background : ZenithColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about today’s macro drivers…", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ZenithColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                viewModel.send()
            } label: {
                if viewModel.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ZenithColors.accent)
                        .frame(width: 26, height: 26)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ZenithColors.accent)
                }
            }
            .disabled(viewModel.isSending)
        }
    }
}

