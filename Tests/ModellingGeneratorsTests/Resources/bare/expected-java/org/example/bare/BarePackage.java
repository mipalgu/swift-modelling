/**
 */
package org.example.bare;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;


/**
 * <!-- begin-user-doc -->
 * The <b>Package</b> for the model.
 * It contains accessors for the meta objects to represent
 * <ul>
 *   <li>each class,</li>
 *   <li>each feature of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see org.example.bare.BareFactory
 * @model kind="package"
 * @generated
 */
public interface BarePackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "bare";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/bare";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "bare";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  BarePackage eINSTANCE = org.example.bare.impl.BarePackageImpl.init();

  /**
   * The meta object id for the '{@link org.example.bare.impl.ThingImpl <em>Thing</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.bare.impl.ThingImpl
   * @see org.example.bare.impl.BarePackageImpl#getThing()
   * @generated
   */
  int THING = 0;

  /**
   * The number of structural features of the '<em>Thing</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int THING_FEATURE_COUNT = 0;

  /**
   * Returns the meta object for class '{@link org.example.bare.Thing <em>Thing</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Thing</em>'.
   * @see org.example.bare.Thing
   * @generated
   */
  EClass getThing();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  BareFactory getBareFactory();

  /**
   * <!-- begin-user-doc -->
   * Defines literals for the meta objects that represent
   * <ul>
   *   <li>each class,</li>
   *   <li>each feature of each class,</li>
   *   <li>each enum,</li>
   *   <li>and each data type</li>
   * </ul>
   * <!-- end-user-doc -->
   * @generated
   */
  interface Literals
  {
    /**
     * The meta object literal for the '{@link org.example.bare.impl.ThingImpl <em>Thing</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.bare.impl.ThingImpl
     * @see org.example.bare.impl.BarePackageImpl#getThing()
     * @generated
     */
    EClass THING = eINSTANCE.getThing();

  }

} //BarePackage
