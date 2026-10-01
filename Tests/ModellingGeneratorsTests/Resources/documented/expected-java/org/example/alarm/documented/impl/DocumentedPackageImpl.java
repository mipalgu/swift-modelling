/**
 */
package org.example.alarm.documented.impl;


import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.alarm.documented.DocumentedFactory;
import org.example.alarm.documented.DocumentedPackage;
import org.example.alarm.documented.Level;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class DocumentedPackageImpl extends EPackageImpl implements DocumentedPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum levelEEnum = null;

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
   * @see org.example.alarm.documented.DocumentedPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private DocumentedPackageImpl()
  {
    super(eNS_URI, DocumentedFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link DocumentedPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static DocumentedPackage init()
  {
    if (isInited) return (DocumentedPackage)EPackage.Registry.INSTANCE.getEPackage(DocumentedPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredDocumentedPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    DocumentedPackageImpl theDocumentedPackage = registeredDocumentedPackage instanceof DocumentedPackageImpl ? (DocumentedPackageImpl)registeredDocumentedPackage : new DocumentedPackageImpl();

    isInited = true;

    // Create package meta-data objects
    theDocumentedPackage.createPackageContents();

    // Initialize created meta-data
    theDocumentedPackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theDocumentedPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(DocumentedPackage.eNS_URI, theDocumentedPackage);
    return theDocumentedPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EEnum getLevel()
  {
    return levelEEnum;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public DocumentedFactory getDocumentedFactory()
  {
    return (DocumentedFactory)getEFactoryInstance();
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

    // Create enums
    levelEEnum = createEEnum(LEVEL);
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
  @SuppressWarnings("deprecation")
  public void initializePackageContents()
  {
    if (isInitialized) return;
    isInitialized = true;

    // Initialize package
    setName(eNAME);
    setNsPrefix(eNS_PREFIX);
    setNsURI(eNS_URI);

    // Initialize enums and add enum literals
    initEEnum(levelEEnum, Level.class, "Level");
    addEEnumLiteral(levelEEnum, Level.LOW);
    addEEnumLiteral(levelEEnum, Level.HIGH);
    addEEnumLiteral(levelEEnum, Level.OLD);

    // Create resource
    createResource(eNS_URI);
  }

} //DocumentedPackageImpl
