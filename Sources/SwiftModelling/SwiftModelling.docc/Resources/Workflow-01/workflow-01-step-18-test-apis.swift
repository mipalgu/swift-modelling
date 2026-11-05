import Foundation
import SalesReport
import Testing

/// Tests of the Swift API that GenerateSwiftClasses.mtl generated from the sales report.
@Suite("Generated sales report API")
struct GeneratedAPITests {
    let report = SalesReportAPI.generated

    @Test("The key figures match the shop data")
    func keyFigures() {
        #expect(report.shopName == "Example Electronics")
        #expect(report.totalRevenue == 6815)
        #expect(report.totalOrders == 8)
        #expect(report.totalUnits == 20)
        #expect(report.averageOrderValue == 851.875)
    }

    @Test("Category, customer and product figures add up to the total revenue")
    func figuresAddUp() {
        #expect(report.isConsistent())
        #expect(report.categoryMetrics.map(\.unitsSold).reduce(0, +) == report.totalUnits)
        #expect(report.customerMetrics.map(\.orderCount).reduce(0, +) == report.totalOrders)
    }

    @Test("The top performers are found")
    func topPerformers() {
        #expect(report.topCategory()?.categoryName == "Computers")
        #expect(report.topCustomer()?.customerName == "Chloe Martin")
        #expect(report.outOfStockProducts().map(\.sku) == ["EAR-01"])
    }

    @Test("A report without orders has an average order value of zero")
    func emptyReport() {
        let empty = SalesReportAPI(
            shopName: "Empty", totalRevenue: 0, totalOrders: 0, totalUnits: 0,
            categoryMetrics: [], customerMetrics: [], productMetrics: [])
        #expect(empty.averageOrderValue == 0)
        #expect(empty.topCategory() == nil)
        #expect(empty.isConsistent())
    }

    @Test("The generated JSON data decode to the same report")
    func jsonMatchesSwift() throws {
        let url = try #require(Bundle.module.url(forResource: "sales-report", withExtension: "json"))
        let decoded = try JSONDecoder().decode(SalesReportAPI.self, from: Data(contentsOf: url))
        #expect(decoded == report)
    }
}
