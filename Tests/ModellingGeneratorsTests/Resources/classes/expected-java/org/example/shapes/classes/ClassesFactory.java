/**
 */
package org.example.shapes.classes;


import org.eclipse.emf.ecore.EFactory;


/**
 * <!-- begin-user-doc -->
 * The <b>Factory</b> for the model.
 * It provides a create method for each non-abstract class of the model.
 * <!-- end-user-doc -->
 * @see org.example.shapes.classes.ClassesPackage
 * @generated
 */
public interface ClassesFactory extends EFactory
{
  /**
   * The singleton instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  ClassesFactory eINSTANCE = org.example.shapes.classes.impl.ClassesFactoryImpl.init();

  /**
   * Returns a new object of class '<em>Canvas</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Canvas</em>'.
   * @generated
   */
  Canvas createCanvas();

  /**
   * Returns a new object of class '<em>Circle</em>'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return a new object of class '<em>Circle</em>'.
   * @generated
   */
  Circle createCircle();

  /**
   * Returns the package supported by this factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the package supported by this factory.
   * @generated
   */
  ClassesPackage getClassesPackage();

} //ClassesFactory
