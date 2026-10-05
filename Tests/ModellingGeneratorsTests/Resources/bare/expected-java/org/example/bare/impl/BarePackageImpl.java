/**
 */
package org.example.bare.impl;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.bare.BareFactory;
import org.example.bare.BarePackage;
import org.example.bare.Thing;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class BarePackageImpl extends EPackageImpl implements BarePackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass thingEClass = null;

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
   * @see org.example.bare.BarePackage#eNS_URI
   * @see #init()
   * @generated
   */
  private BarePackageImpl()
  {
    super(eNS_URI, BareFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link BarePackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static BarePackage init()
  {
    if (isInited) return (BarePackage)EPackage.Registry.INSTANCE.getEPackage(BarePackage.eNS_URI);

    // Obtain or create and register package
    Object registeredBarePackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    BarePackageImpl theBarePackage = registeredBarePackage instanceof BarePackageImpl ? (BarePackageImpl)registeredBarePackage : new BarePackageImpl();

    isInited = true;

    // Create package meta-data objects
    theBarePackage.createPackageContents();

    // Initialize created meta-data
    theBarePackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theBarePackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(BarePackage.eNS_URI, theBarePackage);
    return theBarePackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getThing()
  {
    return thingEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public BareFactory getBareFactory()
  {
    return (BareFactory)getEFactoryInstance();
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
    thingEClass = createEClass(THING);
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
    initEClass(thingEClass, Thing.class, "Thing", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);

    // Create resource
    createResource(eNS_URI);
  }

} //BarePackageImpl
