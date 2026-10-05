/**
 */
package maps.impl;


import java.util.Map.Entry;

import maps.Dictionary;
import maps.MapsFactory;
import maps.MapsPackage;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

import org.eclipse.emf.ecore.impl.EPackageImpl;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class MapsPackageImpl extends EPackageImpl implements MapsPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass dictionaryEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass stringToIntEntryEClass = null;

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
   * @see maps.MapsPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private MapsPackageImpl()
  {
    super(eNS_URI, MapsFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link MapsPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static MapsPackage init()
  {
    if (isInited) return (MapsPackage)EPackage.Registry.INSTANCE.getEPackage(MapsPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredMapsPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    MapsPackageImpl theMapsPackage = registeredMapsPackage instanceof MapsPackageImpl ? (MapsPackageImpl)registeredMapsPackage : new MapsPackageImpl();

    isInited = true;

    // Create package meta-data objects
    theMapsPackage.createPackageContents();

    // Initialize created meta-data
    theMapsPackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theMapsPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(MapsPackage.eNS_URI, theMapsPackage);
    return theMapsPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getDictionary()
  {
    return dictionaryEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getDictionary_Entries()
  {
    return (EReference)dictionaryEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getStringToIntEntry()
  {
    return stringToIntEntryEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getStringToIntEntry_Key()
  {
    return (EAttribute)stringToIntEntryEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getStringToIntEntry_Value()
  {
    return (EAttribute)stringToIntEntryEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public MapsFactory getMapsFactory()
  {
    return (MapsFactory)getEFactoryInstance();
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
    dictionaryEClass = createEClass(DICTIONARY);
    createEReference(dictionaryEClass, DICTIONARY__ENTRIES);

    stringToIntEntryEClass = createEClass(STRING_TO_INT_ENTRY);
    createEAttribute(stringToIntEntryEClass, STRING_TO_INT_ENTRY__KEY);
    createEAttribute(stringToIntEntryEClass, STRING_TO_INT_ENTRY__VALUE);
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
    initEClass(dictionaryEClass, Dictionary.class, "Dictionary", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEReference(getDictionary_Entries(), this.getStringToIntEntry(), null, "entries", null, 0, -1, Dictionary.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEClass(stringToIntEntryEClass, Entry.class, "StringToIntEntry", !IS_ABSTRACT, !IS_INTERFACE, !IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getStringToIntEntry_Key(), ecorePackage.getEString(), "key", null, 0, 1, Entry.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getStringToIntEntry_Value(), ecorePackage.getEInt(), "value", null, 0, 1, Entry.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Create resource
    createResource(eNS_URI);
  }

} //MapsPackageImpl
