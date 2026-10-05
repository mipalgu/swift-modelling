/**
 */
package org.example.traffic.enumerations.impl;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.traffic.enumerations.Colour;
import org.example.traffic.enumerations.Empty;
import org.example.traffic.enumerations.EnumerationsFactory;
import org.example.traffic.enumerations.EnumerationsPackage;
import org.example.traffic.enumerations.Light;
import org.example.traffic.enumerations.Mode;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class EnumerationsPackageImpl extends EPackageImpl implements EnumerationsPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass lightEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum colourEEnum = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum modeEEnum = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum emptyEEnum = null;

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
   * @see org.example.traffic.enumerations.EnumerationsPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private EnumerationsPackageImpl()
  {
    super(eNS_URI, EnumerationsFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link EnumerationsPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static EnumerationsPackage init()
  {
    if (isInited) return (EnumerationsPackage)EPackage.Registry.INSTANCE.getEPackage(EnumerationsPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredEnumerationsPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    EnumerationsPackageImpl theEnumerationsPackage = registeredEnumerationsPackage instanceof EnumerationsPackageImpl ? (EnumerationsPackageImpl)registeredEnumerationsPackage : new EnumerationsPackageImpl();

    isInited = true;

    // Create package meta-data objects
    theEnumerationsPackage.createPackageContents();

    // Initialize created meta-data
    theEnumerationsPackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theEnumerationsPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(EnumerationsPackage.eNS_URI, theEnumerationsPackage);
    return theEnumerationsPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getLight()
  {
    return lightEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getLight_Colour()
  {
    return (EAttribute)lightEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getLight_Mode()
  {
    return (EAttribute)lightEClass.getEStructuralFeatures().get(1);
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
  public EEnum getMode()
  {
    return modeEEnum;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EEnum getEmpty()
  {
    return emptyEEnum;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EnumerationsFactory getEnumerationsFactory()
  {
    return (EnumerationsFactory)getEFactoryInstance();
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
    lightEClass = createEClass(LIGHT);
    createEAttribute(lightEClass, LIGHT__COLOUR);
    createEAttribute(lightEClass, LIGHT__MODE);

    // Create enums
    colourEEnum = createEEnum(COLOUR);
    modeEEnum = createEEnum(MODE);
    emptyEEnum = createEEnum(EMPTY);
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

    // Initialize classes and features; add operations and parameters
    initEClass(lightEClass, Light.class, "Light", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getLight_Colour(), this.getColour(), "colour", null, 0, 1, Light.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getLight_Mode(), this.getMode(), "mode", null, 0, 1, Light.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Initialize enums and add enum literals
    initEEnum(colourEEnum, Colour.class, "Colour");
    addEEnumLiteral(colourEEnum, Colour.RED);
    addEEnumLiteral(colourEEnum, Colour.AMBER);
    addEEnumLiteral(colourEEnum, Colour.YELLOW);
    addEEnumLiteral(colourEEnum, Colour.GREEN);

    initEEnum(modeEEnum, Mode.class, "Mode");
    addEEnumLiteral(modeEEnum, Mode.DEFAULT);
    addEEnumLiteral(modeEEnum, Mode.FAST_FORWARD);
    addEEnumLiteral(modeEEnum, Mode.HTTP_SERVER);
    addEEnumLiteral(modeEEnum, Mode.__);
    addEEnumLiteral(modeEEnum, Mode.QUOTE);

    initEEnum(emptyEEnum, Empty.class, "Empty");

    // Create resource
    createResource(eNS_URI);
  }

} //EnumerationsPackageImpl
