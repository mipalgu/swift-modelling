/**
 */
package org.example.shapes.classes.impl;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EOperation;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.impl.EPackageImpl;
import org.example.shapes.classes.Canvas;
import org.example.shapes.classes.Circle;
import org.example.shapes.classes.ClassesFactory;
import org.example.shapes.classes.ClassesPackage;
import org.example.shapes.classes.Colour;
import org.example.shapes.classes.Named;
import org.example.shapes.classes.Shape;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class ClassesPackageImpl extends EPackageImpl implements ClassesPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  private EClass shapeEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass canvasEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass namedEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass circleEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum colourEEnum = null;

  /**
   * Creates an instance of the model <b>Package</b>, registered with
   * {@link org.eclipse.emf.ecore.EPackage.Registry EPackage.Registry} by the package
   * package URI value.
   * <p>Note: the correct way to create the package is via the static
   * factory method {@link #init init()}, which also performs
   * initialization of the package, or returns the registered package,
   * if one already exists.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.eclipse.emf.ecore.EPackage.Registry
   * @see org.example.shapes.classes.ClassesPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private ClassesPackageImpl()
  {
    super(eNS_URI, ClassesFactory.eINSTANCE);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private static boolean isInited = false;

  /**
   * Creates, registers, and initializes the <b>Package</b> for this model, and for any others upon which it depends.
   *
   * <p>This method is used to initialize {@link ClassesPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static ClassesPackage init()
  {
    if (isInited) return (ClassesPackage)EPackage.Registry.INSTANCE.getEPackage(ClassesPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredClassesPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    ClassesPackageImpl theClassesPackage = registeredClassesPackage instanceof ClassesPackageImpl ? (ClassesPackageImpl)registeredClassesPackage : new ClassesPackageImpl();

    isInited = true;

    // Create package meta-data objects
    theClassesPackage.createPackageContents();

    // Initialize created meta-data
    theClassesPackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theClassesPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(ClassesPackage.eNS_URI, theClassesPackage);
    return theClassesPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EClass getShape()
  {
    return shapeEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Label()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Visible()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Weight()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(2);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Tags()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(3);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Levels()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(4);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Colour()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(5);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EAttribute getShape_Description()
  {
    return (EAttribute)shapeEClass.getEStructuralFeatures().get(6);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EReference getShape_Canvas()
  {
    return (EReference)shapeEClass.getEStructuralFeatures().get(7);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EOperation getShape__Area()
  {
    return shapeEClass.getEOperations().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @since 1.2
   * @generated
   */
  @Override
  public EOperation getShape__Move__int_int()
  {
    return shapeEClass.getEOperations().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getCanvas()
  {
    return canvasEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCanvas_Shapes()
  {
    return (EReference)canvasEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCanvas_Background()
  {
    return (EReference)canvasEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCanvas_Favourites()
  {
    return (EReference)canvasEClass.getEStructuralFeatures().get(2);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCanvas_Selected()
  {
    return (EReference)canvasEClass.getEStructuralFeatures().get(3);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCanvas_Primary()
  {
    return (EReference)canvasEClass.getEStructuralFeatures().get(4);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getNamed()
  {
    return namedEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getNamed_Name()
  {
    return (EAttribute)namedEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getCircle()
  {
    return circleEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getCircle_Radius()
  {
    return (EAttribute)circleEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getCircle_Filled()
  {
    return (EAttribute)circleEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EEnum getColour()
  {
    return colourEEnum;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public ClassesFactory getClassesFactory()
  {
    return (ClassesFactory)getEFactoryInstance();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private boolean isCreated = false;

  /**
   * Creates the meta-model objects for the package.  This method is
   * guarded to have no affect on any invocation but its first.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void createPackageContents()
  {
    if (isCreated) return;
    isCreated = true;

    // Create classes and their features
    shapeEClass = createEClass(SHAPE);
    createEAttribute(shapeEClass, SHAPE__LABEL);
    createEAttribute(shapeEClass, SHAPE__VISIBLE);
    createEAttribute(shapeEClass, SHAPE__WEIGHT);
    createEAttribute(shapeEClass, SHAPE__TAGS);
    createEAttribute(shapeEClass, SHAPE__LEVELS);
    createEAttribute(shapeEClass, SHAPE__COLOUR);
    createEAttribute(shapeEClass, SHAPE__DESCRIPTION);
    createEReference(shapeEClass, SHAPE__CANVAS);
    createEOperation(shapeEClass, SHAPE___AREA);
    createEOperation(shapeEClass, SHAPE___MOVE__INT_INT);

    canvasEClass = createEClass(CANVAS);
    createEReference(canvasEClass, CANVAS__SHAPES);
    createEReference(canvasEClass, CANVAS__BACKGROUND);
    createEReference(canvasEClass, CANVAS__FAVOURITES);
    createEReference(canvasEClass, CANVAS__SELECTED);
    createEReference(canvasEClass, CANVAS__PRIMARY);

    namedEClass = createEClass(NAMED);
    createEAttribute(namedEClass, NAMED__NAME);

    circleEClass = createEClass(CIRCLE);
    createEAttribute(circleEClass, CIRCLE__RADIUS);
    createEAttribute(circleEClass, CIRCLE__FILLED);

    // Create enums
    colourEEnum = createEEnum(COLOUR);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private boolean isInitialized = false;

  /**
   * Complete the initialization of the package and its meta-model.  This
   * method is guarded to have no affect on any invocation but its first.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void initializePackageContents()
  {
    if (isInitialized) return;
    isInitialized = true;

    // Initialize package
    setName(eNAME);
    setNsPrefix(eNS_PREFIX);
    setNsURI(eNS_URI);

    // Create type parameters

    // Set bounds for type parameters

    // Add supertypes to classes
    circleEClass.getESuperTypes().add(this.getShape());
    circleEClass.getESuperTypes().add(this.getNamed());

    // Initialize classes, features, and operations; add parameters
    initEClass(shapeEClass, Shape.class, "Shape", IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getShape_Label(), ecorePackage.getEString(), "label", null, 0, 1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Visible(), ecorePackage.getEBoolean(), "visible", "true", 0, 1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Weight(), ecorePackage.getEDouble(), "weight", "1.5", 0, 1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Tags(), ecorePackage.getEString(), "tags", null, 0, -1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Levels(), ecorePackage.getEInt(), "levels", null, 0, -1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_UNSETTABLE, !IS_ID, !IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Colour(), this.getColour(), "colour", "Green", 0, 1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getShape_Description(), ecorePackage.getEString(), "description", null, 0, 1, Shape.class, IS_TRANSIENT, IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, IS_DERIVED, IS_ORDERED);
    initEReference(getShape_Canvas(), this.getCanvas(), this.getCanvas_Shapes(), "canvas", null, 0, 1, Shape.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEOperation(getShape__Area(), ecorePackage.getEDouble(), "area", 0, 1, IS_UNIQUE, IS_ORDERED);

    EOperation op = initEOperation(getShape__Move__int_int(), null, "move", 0, 1, IS_UNIQUE, IS_ORDERED);
    addEParameter(op, ecorePackage.getEInt(), "dx", 0, 1, IS_UNIQUE, IS_ORDERED);
    addEParameter(op, ecorePackage.getEInt(), "dy", 0, 1, IS_UNIQUE, IS_ORDERED);

    initEClass(canvasEClass, Canvas.class, "Canvas", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEReference(getCanvas_Shapes(), this.getShape(), this.getShape_Canvas(), "shapes", null, 0, -1, Canvas.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCanvas_Background(), this.getShape(), null, "background", null, 0, 1, Canvas.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCanvas_Favourites(), this.getShape(), null, "favourites", null, 0, -1, Canvas.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCanvas_Selected(), this.getShape(), null, "selected", null, 0, 1, Canvas.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCanvas_Primary(), this.getShape(), null, "primary", null, 1, 1, Canvas.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, IS_RESOLVE_PROXIES, IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEClass(namedEClass, Named.class, "Named", IS_ABSTRACT, IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getNamed_Name(), ecorePackage.getEString(), "name", null, 0, 1, Named.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEClass(circleEClass, Circle.class, "Circle", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getCircle_Radius(), ecorePackage.getEDouble(), "radius", null, 0, 1, Circle.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getCircle_Filled(), ecorePackage.getEBoolean(), "filled", null, 0, 1, Circle.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Initialize enums and add enum literals
    initEEnum(colourEEnum, Colour.class, "Colour");
    addEEnumLiteral(colourEEnum, Colour.RED);
    addEEnumLiteral(colourEEnum, Colour.GREEN);
    addEEnumLiteral(colourEEnum, Colour.BLUE);

    // Create resource
    createResource(eNS_URI);
  }

} //ClassesPackageImpl
