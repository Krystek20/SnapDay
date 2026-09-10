import Foundation
import StoreKitTest
@testable import Payment
import Testing

@Suite(.serialized)
struct StoreKitConfigurationTests {
  @Test
  @MainActor
  func snapDayPlusCatalogMatchesProductContract() throws {
    let configurationURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("SnapDayPlus.storekit")
    _ = try SKTestSession(contentsOf: configurationURL)
    let configuration = try JSONDecoder().decode(
      StoreKitConfiguration.self,
      from: Data(contentsOf: configurationURL)
    )

    let expectedIDs = Set(SnapDayPlusProduct.allCases.map(\.rawValue))
    let products = configuration.subscriptionGroups.flatMap(\.subscriptions)

    #expect(Set(products.map(\.productID)) == expectedIDs)

    let monthly = try #require(
      products.first { $0.productID == SnapDayPlusProduct.monthly.rawValue }
    )
    let annual = try #require(
      products.first { $0.productID == SnapDayPlusProduct.annual.rawValue }
    )

    #expect(monthly.recurringSubscriptionPeriod == "P1M")
    #expect(monthly.displayPrice == "4.99")
    #expect(monthly.introductoryOffers.isEmpty)
    #expect(annual.recurringSubscriptionPeriod == "P1Y")
    #expect(annual.displayPrice == "29.99")
    #expect(annual.introductoryOffers.count == 1)
    #expect(annual.introductoryOffers.first?.paymentMode == "free")
    #expect(annual.introductoryOffers.first?.duration == "P2W")
  }
}

private struct StoreKitConfiguration: Decodable {
  let subscriptionGroups: [SubscriptionGroup]
}

private struct SubscriptionGroup: Decodable {
  let subscriptions: [StoreSubscription]
}

private struct StoreSubscription: Decodable {
  let displayPrice: String
  let introductoryOffers: [IntroductoryOffer]
  let productID: String
  let recurringSubscriptionPeriod: String
}

private struct IntroductoryOffer: Decodable {
  let duration: String
  let paymentMode: String
}
