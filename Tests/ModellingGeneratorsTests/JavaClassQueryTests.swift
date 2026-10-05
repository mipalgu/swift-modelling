import Foundation
import Testing

@testable import ModellingGenerators

/// Checks the queries that decide the contents of the Java files of a class.
@Suite("Java class queries")
struct JavaClassQueryTests {
    /// The expressions for the classes fixture.
    static let shapes = FixtureExpressions(
        fixture: "classes", stem: "classes",
        options: GenModelImportOptions(basePackage: "org.example.shapes", defaults: .wizard),
        bindings: [
            ("p", "GenPackage", "genModel.allGenPackages()->first()"),
            ("shape", "GenClass", "p.genClasses->at(1)"),
            ("canvas", "GenClass", "p.genClasses->at(2)"),
            ("named", "GenClass", "p.genClasses->at(3)"),
            ("circle", "GenClass", "p.genClasses->at(4)"),
            ("label", "GenFeature", "shape.genFeatures->at(1)"),
            ("visible", "GenFeature", "shape.genFeatures->at(2)"),
            ("tags", "GenFeature", "shape.genFeatures->at(4)"),
            ("shapes", "GenFeature", "canvas.genFeatures->at(1)"),
            ("canvasOfShape", "GenFeature", "shape.genFeatures->at(8)"),
            ("primary", "GenFeature", "canvas.genFeatures->at(5)"),
        ])

    @Test("Class names and supertypes follow the rules of the interface and the class")
    @MainActor
    func supertypes() async throws {
        let values = try await Self.shapes.evaluate([
            "shape.interfaceExtendsList()->join(',')", "circle.interfaceExtendsList()->join(',')",
            "circle.classExtendsName()", "shape.classExtendsName()", "circle.classImplementsList()->join(',')",
            "circle.mixinGenClasses()->collect(m | m.name())->join(',')", "shape.isExternalInterface()",
            "named.isModelRoot()", "circle.isModelRoot()",
        ])
        #expect(
            values == [
                "org.eclipse.emf.ecore.EObject",
                "org.example.shapes.classes.Shape,org.example.shapes.classes.Named",
                "org.example.shapes.classes.impl.ShapeImpl", "org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container",
                "org.example.shapes.classes.Circle", "Named", "false", "true", "false",
            ])
    }

    @Test("Feature kinds decide the accessors, the lists and the flags")
    @MainActor
    func featureKinds() async throws {
        let values = try await Self.shapes.evaluate([
            "label.getterName()", "visible.getterName()", "label.isUnsettableFeature()",
            "label.isESetFeature()", "tags.isMany()", "shapes.isEffectiveContains()", "canvasOfShape.isContainer()",
            "canvasOfShape.isBasicSet()", "primary.isBasicGet()", "label.featureKind()", "shapes.featureKind()",
            "canvasOfShape.featureKind()", "tags.featureKind()", "visible.isBooleanFeature()",
        ])
        #expect(
            values == [
                "getLabel", "isVisible", "true", "true", "true", "true", "true", "true", "true", "attribute",
                "containment reference list", "container reference", "attribute list", "true",
            ])
    }

    @Test("Without a flags field no feature is a flag; with one flags follow the order of the features")
    @MainActor
    func flags() async throws {
        let values = try await Self.shapes.evaluate([
            "shape.isFlagOf(visible)", "shape.isESetFlagOf(label)", "shape.flagIndex(visible)",
        ])
        #expect(values == ["false", "false", "0"])
    }

    @Test("Model information lists the settings that differ from the defaults")
    @MainActor
    func modelInfo() async throws {
        let values = try await Self.shapes.evaluate([
            "shape.modelInfo()->join(' | ')", "label.modelInfo()->join(' | ')", "visible.modelInfo()->join(' | ')",
            "canvasOfShape.modelInfo()->join(' | ')", "primary.modelInfo()->join(' | ')",
            "shape.genOperations->at(2).modelInfo()->join(' | ')",
        ])
        #expect(
            values == [
                #"abstract="true""#, #"unsettable="true""#, #"default="true""#, #"opposite="shapes" transient="false""#,
                #"unsettable="true" required="true""#, "",
            ])
    }

    @Test("Operations are named by identifiers that carry the parameter types")
    @MainActor
    func operationIdentifiers() async throws {
        let values = try await Self.shapes.evaluate([
            "shape.operationIDName(shape.genOperations->at(2))", "shape.operationIDName(shape.genOperations->at(1))",
            "shape.implementedOperations()->collect(o | o.name())->join(',')",
            "circle.implementedOperations()->collect(o | o.name())->join(',')",
        ])
        #expect(values == ["SHAPE___MOVE__INT_INT", "SHAPE___AREA", "area,move", ""])
    }
}
