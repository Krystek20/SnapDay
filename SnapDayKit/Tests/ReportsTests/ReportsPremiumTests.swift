import Models
import Testing
@testable import Reports

struct ReportsPremiumTests {

  @Test
  func freeUserSelectingMonthRequestsPremiumAccess() {
    var state = ReportsFeature.State()

    #expect(state.selectPeriod(.month) == .requiresPremiumAccess)
    #expect(state.pendingPremiumPeriod == .month)
    #expect(state.selectedPeriod == .week)
  }

  @Test
  func premiumGrantContinuesPendingPeriodSelection() {
    var state = ReportsFeature.State()
    state.pendingPremiumPeriod = .year

    #expect(state.grantPremiumAccess() == .year)
    #expect(state.hasPremiumAccess)
    #expect(state.pendingPremiumPeriod == nil)
    #expect(state.selectedPeriod == .year)
  }

  @Test
  func onlyExtendedReportPeriodsRequirePremiumAccess() {
    #expect(!Period.week.requiresPremiumAccess)
    #expect(Period.month.requiresPremiumAccess)
    #expect(Period.quarter.requiresPremiumAccess)
    #expect(Period.year.requiresPremiumAccess)
  }

  @Test
  func losingPremiumAccessReturnsExtendedReportToCurrentWeek() {
    var state = ReportsFeature.State(selectedFilterDate: .year)
    state.hasPremiumAccess = true
    state.periodShift = -1

    let didChangePeriod = state.updatePremiumAccess(false)

    #expect(didChangePeriod)
    #expect(!state.hasPremiumAccess)
    #expect(state.selectedPeriod == .week)
    #expect(state.periodShift == 0)
  }
}
