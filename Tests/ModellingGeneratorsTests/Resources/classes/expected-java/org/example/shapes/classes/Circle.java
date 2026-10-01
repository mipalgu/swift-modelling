/**
 */
package org.example.shapes.classes;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Circle</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.Circle#getRadius <em>Radius</em>}</li>
 *   <li>{@link org.example.shapes.classes.Circle#isFilled <em>Filled</em>}</li>
 * </ul>
 *
 * @see org.example.shapes.classes.ClassesPackage#getCircle()
 * @model
 * @generated
 */
public interface Circle extends Shape, Named
{
  /**
   * Returns the value of the '<em><b>Radius</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Radius</em>' attribute.
   * @see #setRadius(double)
   * @see org.example.shapes.classes.ClassesPackage#getCircle_Radius()
   * @model
   * @generated
   */
  double getRadius();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Circle#getRadius <em>Radius</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Radius</em>' attribute.
   * @see #getRadius()
   * @generated
   */
  void setRadius(double value);

  /**
   * Returns the value of the '<em><b>Filled</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Filled</em>' attribute.
   * @see #setFilled(boolean)
   * @see org.example.shapes.classes.ClassesPackage#getCircle_Filled()
   * @model
   * @generated
   */
  boolean isFilled();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Circle#isFilled <em>Filled</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Filled</em>' attribute.
   * @see #isFilled()
   * @generated
   */
  void setFilled(boolean value);

} // Circle
