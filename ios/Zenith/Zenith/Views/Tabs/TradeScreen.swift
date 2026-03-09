import SwiftUI

struct TradeScreen: View {
    @EnvironmentObject private var session: SessionStore
    @State private var ticket: OrderTicket? = nil

    var body: some View {
        ZStack {
            ZenithColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let ticket {
                        ZenithCard {
                            OrderTicketView(ticket: ticket)
                        }
                    } else {
                        ZenithCard {
                            Text("Select an instrument from Quotes to trade.")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)
                        }
                    }

                    ZenithCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open Positions")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(ZenithColors.textPrimary)
                            Text("Positions and orders will appear here once connected to Topstep.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(ZenithColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }
}

struct OrderTicketView: View {
    let ticket: OrderTicket
    @State private var quantity: Double = 1
    @State private var side: OrderSide = .buy
    @State private var type: OrderType = .market
    @State private var limitPrice: String = ""
    @State private var stopPrice: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(ticket.instrument.symbol)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(ZenithColors.textPrimary)

            HStack(spacing: 8) {
                sidePicker
                typePicker
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                    Stepper(value: $quantity, in: 1...100, step: 1) {
                        Text("\(Int(quantity))")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(ZenithColors.textPrimary)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk (est.)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textMuted)
                    Text("Connect to account for live risk.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ZenithColors.textSecondary)
                }
            }

            if type == .limit || type == .stop {
                HStack(spacing: 10) {
                    if type == .limit {
                        ZenithTextField(title: "Limit Price", text: $limitPrice)
                    }
                    if type == .stop {
                        ZenithTextField(title: "Stop Price", text: $stopPrice)
                    }
                }
            }

            Button {
                // Order submission will be wired to backend Topstep proxy.
            } label: {
                HStack {
                    Spacer()
                    Text("Place Order")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.vertical, 10)
                .foregroundColor(ZenithColors.background)
                .background(side == .buy ? ZenithColors.positive : ZenithColors.negative)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var sidePicker: some View {
        HStack(spacing: 0) {
            sideToggle(side: .buy, label: "Buy")
            sideToggle(side: .sell, label: "Sell")
        }
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(ZenithColors.separator, lineWidth: 1)
        )
    }

    private func sideToggle(side option: OrderSide, label: String) -> some View {
        Button {
            side = option
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(side == option ? (option == .buy ? ZenithColors.positive : ZenithColors.negative) : Color.clear)
                .foregroundColor(side == option ? ZenithColors.background : ZenithColors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private var typePicker: some View {
        Picker("Type", selection: $type) {
            Text("MKT").tag(OrderType.market)
            Text("LMT").tag(OrderType.limit)
            Text("STP").tag(OrderType.stop)
        }
        .pickerStyle(.segmented)
    }
}

struct ZenithTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(ZenithColors.textMuted)

            TextField("", text: $text)
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(ZenithColors.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ZenithColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

