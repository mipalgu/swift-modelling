import Foundation
import Testing

// Test suite for generated SalesReport API
// Demonstrates validation of MTL-generated code

@Suite("Generated Sales Report API Tests")
struct GeneratedAPITests {

    // MARK: - Test Data

    let sampleCategoryMetric = CategoryMetricAPI(
        categoryName: "Electronics",
        productCount: 3,
        totalSales: 8897.00,
        avgProductPrice: 2965.67
    )

    let sampleCustomerMetric = CustomerMetricAPI(
        customerId: "C001",
        customerName: "Alice Johnson",
        orderCount: 2,
        totalSpent: 2798.00,
        avgOrderValue: 1399.00
    )

    let sampleProductMetric = ProductMetricAPI(
        productId: "P001",
        productName: "Laptop Pro",
        unitsSold: 5,
        revenue: 4995.00,
        averageRating: 4.8
    )

    // MARK: - SalesReportAPI Tests

    @Test("SalesReportAPI calculates average order value correctly")
    func testAverageOrderValue() {
        let report = SalesReportAPI(
            reportId: "REPORT-001",
            generatedDate: "2024-01-15",
            totalRevenue: 15000.00,
            totalOrders: 10,
            categoryMetrics: [],
            customerMetrics: [],
            productMetrics: []
        )

        #expect(report.averageOrderValue == 1500.00)
    }

    @Test("SalesReportAPI handles zero orders gracefully")
    func testZeroOrders() {
        let report = SalesReportAPI(
            reportId: "REPORT-002",
            generatedDate: "2024-01-15",
            totalRevenue: 0.00,
            totalOrders: 0,
            categoryMetrics: [],
            customerMetrics: [],
            productMetrics: []
        )

        #expect(report.averageOrderValue == 0.00)
    }

    @Test("SalesReportAPI identifies top category")
    func testTopCategory() {
        let categories = [
            CategoryMetricAPI(categoryName: "Electronics", productCount: 3, totalSales: 8897.00, avgProductPrice: 2965.67),
            CategoryMetricAPI(categoryName: "Computers", productCount: 4, totalSales: 5450.00, avgProductPrice: 1362.50),
            CategoryMetricAPI(categoryName: "Accessories", productCount: 3, totalSales: 1500.00, avgProductPrice: 500.00)
        ]

        let report = SalesReportAPI(
            reportId: "REPORT-003",
            generatedDate: "2024-01-15",
            totalRevenue: 15847.00,
            totalOrders: 10,
            categoryMetrics: categories,
            customerMetrics: [],
            productMetrics: []
        )

        #expect(report.topCategory?.categoryName == "Electronics")
        #expect(report.topCategory?.totalSales == 8897.00)
    }

    @Test("SalesReportAPI generates summary text")
    func testGenerateSummary() {
        let report = SalesReportAPI(
            reportId: "REPORT-004",
            generatedDate: "2024-01-15",
            totalRevenue: 15847.00,
            totalOrders: 10,
            categoryMetrics: [sampleCategoryMetric],
            customerMetrics: [sampleCustomerMetric],
            productMetrics: [sampleProductMetric]
        )

        let summary = report.generateSummary()

        #expect(summary.contains("REPORT-004"))
        #expect(summary.contains("2024-01-15"))
        #expect(summary.contains("15847.00"))
        #expect(summary.contains("10"))
    }

    // MARK: - CategoryMetricAPI Tests

    @Test("CategoryMetricAPI provides market share")
    func testCategoryMarketShare() {
        #expect(sampleCategoryMetric.marketShare == 8897.00)
    }

    // MARK: - CustomerMetricAPI Tests

    @Test("CustomerMetricAPI segments bronze customers correctly")
    func testBronzeSegment() {
        let bronzeCustomer = CustomerMetricAPI(
            customerId: "C100",
            customerName: "Test User",
            orderCount: 1,
            totalSpent: 250.00,
            avgOrderValue: 250.00
        )

        #expect(bronzeCustomer.customerSegment == "Bronze")
    }

    @Test("CustomerMetricAPI segments silver customers correctly")
    func testSilverSegment() {
        let silverCustomer = CustomerMetricAPI(
            customerId: "C101",
            customerName: "Test User",
            orderCount: 2,
            totalSpent: 1200.00,
            avgOrderValue: 600.00
        )

        #expect(silverCustomer.customerSegment == "Silver")
    }

    @Test("CustomerMetricAPI segments gold customers correctly")
    func testGoldSegment() {
        let goldCustomer = CustomerMetricAPI(
            customerId: "C102",
            customerName: "Test User",
            orderCount: 5,
            totalSpent: 3500.00,
            avgOrderValue: 700.00
        )

        #expect(goldCustomer.customerSegment == "Gold")
    }

    @Test("CustomerMetricAPI segments platinum customers correctly")
    func testPlatinumSegment() {
        let platinumCustomer = CustomerMetricAPI(
            customerId: "C103",
            customerName: "Test User",
            orderCount: 10,
            totalSpent: 8000.00,
            avgOrderValue: 800.00
        )

        #expect(platinumCustomer.customerSegment == "Platinum")
    }

    // MARK: - ProductMetricAPI Tests

    @Test("ProductMetricAPI rates excellent performance")
    func testExcellentPerformance() {
        let excellentProduct = ProductMetricAPI(
            productId: "P999",
            productName: "Bestseller",
            unitsSold: 15,
            revenue: 7500.00,
            averageRating: 4.8
        )

        #expect(excellentProduct.performanceRating == "Excellent")
    }

    @Test("ProductMetricAPI rates good performance")
    func testGoodPerformance() {
        let goodProduct = ProductMetricAPI(
            productId: "P998",
            productName: "Popular Item",
            unitsSold: 7,
            revenue: 2100.00,
            averageRating: 4.2
        )

        #expect(goodProduct.performanceRating == "Good")
    }

    @Test("ProductMetricAPI rates fair performance")
    func testFairPerformance() {
        let fairProduct = ProductMetricAPI(
            productId: "P997",
            productName: "Moderate Seller",
            unitsSold: 3,
            revenue: 600.00,
            averageRating: 3.5
        )

        #expect(fairProduct.performanceRating == "Fair")
    }

    @Test("ProductMetricAPI identifies products needing improvement")
    func testNeedsImprovement() {
        let poorProduct = ProductMetricAPI(
            productId: "P996",
            productName: "Slow Seller",
            unitsSold: 1,
            revenue: 100.00,
            averageRating: 3.0
        )

        #expect(poorProduct.performanceRating == "Needs Improvement")
    }

    // MARK: - Integration Tests

    @Test("Full report integration test")
    func testFullReportIntegration() {
        let categories = [
            CategoryMetricAPI(categoryName: "Electronics", productCount: 3, totalSales: 8897.00, avgProductPrice: 2965.67),
            CategoryMetricAPI(categoryName: "Computers", productCount: 4, totalSales: 5450.00, avgProductPrice: 1362.50)
        ]

        let customers = [
            CustomerMetricAPI(customerId: "C001", customerName: "Alice", orderCount: 2, totalSpent: 2798.00, avgOrderValue: 1399.00),
            CustomerMetricAPI(customerId: "C002", customerName: "Bob", orderCount: 1, totalSpent: 1299.00, avgOrderValue: 1299.00)
        ]

        let products = [
            ProductMetricAPI(productId: "P001", productName: "Laptop", unitsSold: 5, revenue: 4995.00, averageRating: 4.8),
            ProductMetricAPI(productId: "P002", productName: "Mouse", unitsSold: 12, revenue: 348.00, averageRating: 4.5)
        ]

        let report = SalesReportAPI(
            reportId: "REPORT-INTEGRATION",
            generatedDate: "2024-01-15",
            totalRevenue: 15847.00,
            totalOrders: 10,
            categoryMetrics: categories,
            customerMetrics: customers,
            productMetrics: products
        )

        // Verify computed properties
        #expect(report.averageOrderValue == 1584.70)
        #expect(report.topCategory?.categoryName == "Electronics")
        #expect(report.topCustomer?.customerName == "Alice")
        #expect(report.topProduct?.productName == "Laptop")

        // Verify summary generation
        let summary = report.generateSummary()
        #expect(summary.contains("REPORT-INTEGRATION"))
        #expect(summary.contains("Electronics"))
        #expect(summary.contains("Alice"))
        #expect(summary.contains("Laptop"))
    }
}
