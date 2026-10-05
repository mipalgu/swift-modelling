/**
 */
package org.example.traffic.enumerations;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EEnum;
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
 * @see org.example.traffic.enumerations.EnumerationsFactory
 * @model kind="package"
 * @generated
 */
public interface EnumerationsPackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "enumerations";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/enumerations";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "enums";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  EnumerationsPackage eINSTANCE = org.example.traffic.enumerations.impl.EnumerationsPackageImpl.init();

  /**
   * The meta object id for the '{@link org.example.traffic.enumerations.impl.LightImpl <em>Light</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.traffic.enumerations.impl.LightImpl
   * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getLight()
   * @generated
   */
  int LIGHT = 0;

  /**
   * The feature id for the '<em><b>Colour</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIGHT__COLOUR = 0;

  /**
   * The feature id for the '<em><b>Mode</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIGHT__MODE = 1;

  /**
   * The number of structural features of the '<em>Light</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIGHT_FEATURE_COUNT = 2;

  /**
   * The meta object id for the '{@link org.example.traffic.enumerations.Colour <em>Colour</em>}' enum.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.traffic.enumerations.Colour
   * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getColour()
   * @generated
   */
  int COLOUR = 1;

  /**
   * The meta object id for the '{@link org.example.traffic.enumerations.Mode <em>Mode</em>}' enum.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.traffic.enumerations.Mode
   * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getMode()
   * @generated
   */
  int MODE = 2;

  /**
   * The meta object id for the '{@link org.example.traffic.enumerations.Empty <em>Empty</em>}' enum.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.traffic.enumerations.Empty
   * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getEmpty()
   * @generated
   */
  int EMPTY = 3;


  /**
   * Returns the meta object for class '{@link org.example.traffic.enumerations.Light <em>Light</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Light</em>'.
   * @see org.example.traffic.enumerations.Light
   * @generated
   */
  EClass getLight();

  /**
   * Returns the meta object for the attribute '{@link org.example.traffic.enumerations.Light#getColour <em>Colour</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Colour</em>'.
   * @see org.example.traffic.enumerations.Light#getColour()
   * @see #getLight()
   * @generated
   */
  EAttribute getLight_Colour();

  /**
   * Returns the meta object for the attribute '{@link org.example.traffic.enumerations.Light#getMode <em>Mode</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Mode</em>'.
   * @see org.example.traffic.enumerations.Light#getMode()
   * @see #getLight()
   * @generated
   */
  EAttribute getLight_Mode();

  /**
   * Returns the meta object for enum '{@link org.example.traffic.enumerations.Colour <em>Colour</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for enum '<em>Colour</em>'.
   * @see org.example.traffic.enumerations.Colour
   * @generated
   */
  EEnum getColour();

  /**
   * Returns the meta object for enum '{@link org.example.traffic.enumerations.Mode <em>Mode</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for enum '<em>Mode</em>'.
   * @see org.example.traffic.enumerations.Mode
   * @generated
   */
  EEnum getMode();

  /**
   * Returns the meta object for enum '{@link org.example.traffic.enumerations.Empty <em>Empty</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for enum '<em>Empty</em>'.
   * @see org.example.traffic.enumerations.Empty
   * @generated
   */
  EEnum getEmpty();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  EnumerationsFactory getEnumerationsFactory();

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
     * The meta object literal for the '{@link org.example.traffic.enumerations.impl.LightImpl <em>Light</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.traffic.enumerations.impl.LightImpl
     * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getLight()
     * @generated
     */
    EClass LIGHT = eINSTANCE.getLight();

    /**
     * The meta object literal for the '<em><b>Colour</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute LIGHT__COLOUR = eINSTANCE.getLight_Colour();

    /**
     * The meta object literal for the '<em><b>Mode</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute LIGHT__MODE = eINSTANCE.getLight_Mode();

    /**
     * The meta object literal for the '{@link org.example.traffic.enumerations.Colour <em>Colour</em>}' enum.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.traffic.enumerations.Colour
     * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getColour()
     * @generated
     */
    EEnum COLOUR = eINSTANCE.getColour();

    /**
     * The meta object literal for the '{@link org.example.traffic.enumerations.Mode <em>Mode</em>}' enum.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.traffic.enumerations.Mode
     * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getMode()
     * @generated
     */
    EEnum MODE = eINSTANCE.getMode();

    /**
     * The meta object literal for the '{@link org.example.traffic.enumerations.Empty <em>Empty</em>}' enum.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.traffic.enumerations.Empty
     * @see org.example.traffic.enumerations.impl.EnumerationsPackageImpl#getEmpty()
     * @generated
     */
    EEnum EMPTY = eINSTANCE.getEmpty();

  }

} //EnumerationsPackage
