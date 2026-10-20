import ECore
import Testing

@testable import ModellingGenerators

/// Tests for the setting that chooses how the import and the templates read unset features.
@Suite("Generation options - reading unset features")
struct UnsetFeatureReadsOptionTests {
    @Test("generation options read unset features as their defaults unless told otherwise")
    func generationOptionsDefault() {
        #expect(GenerationOptions().unsetFeatureReads == .defaults)
        #expect(GenerationOptions(unsetFeatureReads: .undefined).unsetFeatureReads == .undefined)
    }

    @Test("import options read unset features as their defaults unless told otherwise")
    func importOptionsDefault() {
        #expect(GenModelImportOptions().unsetFeatureReads == .defaults)
        #expect(GenModelImportOptions(unsetFeatureReads: .undefined).unsetFeatureReads == .undefined)
    }

    @Test("options that differ only in how unset features read are not equal")
    func equality() {
        var undefined = GenerationOptions()
        undefined.unsetFeatureReads = .undefined
        var importUndefined = GenModelImportOptions()
        importUndefined.unsetFeatureReads = .undefined

        #expect(undefined != GenerationOptions())
        #expect(importUndefined != GenModelImportOptions())
    }
}
