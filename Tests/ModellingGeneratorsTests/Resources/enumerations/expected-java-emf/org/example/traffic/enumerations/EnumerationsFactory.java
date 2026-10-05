/**
 */
package org.example.traffic.enumerations;

import org.eclipse.emf.ecore.EFactory;

/**
 * <!-- begin-user-doc -->
 * The <b>Factory</b> for the model.
 * It provides a create method for each non-abstract class of the model.
 * <!-- end-user-doc -->
 * @see org.example.traffic.enumerations.EnumerationsPackage
 * @generated
 */
public interface EnumerationsFactory extends EFactory
{
  /**
   * The singleton instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  EnumerationsFactory eINSTANCE = org.example.traffic.enumerations.impl.EnumerationsFactoryImpl.init();

  /**
   * Returns a new object of class '<em>Light</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Light</em>'.
   * @generated
   */
  Light createLight();

  /**
   * Returns the package supported by this factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the package supported by this factory.
   * @generated
   */
  EnumerationsPackage getEnumerationsPackage();

} //EnumerationsFactory
