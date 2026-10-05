/**
 */
package org.example.shapes.classes;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Canvas</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.Canvas#getShapes <em>Shapes</em>}</li>
 *   <li>{@link org.example.shapes.classes.Canvas#getBackground <em>Background</em>}</li>
 *   <li>{@link org.example.shapes.classes.Canvas#getFavourites <em>Favourites</em>}</li>
 *   <li>{@link org.example.shapes.classes.Canvas#getSelected <em>Selected</em>}</li>
 *   <li>{@link org.example.shapes.classes.Canvas#getPrimary <em>Primary</em>}</li>
 * </ul>
 *
 * @see org.example.shapes.classes.ClassesPackage#getCanvas()
 * @model
 * @generated
 */
public interface Canvas extends EObject {
	/**
	 * Returns the value of the '<em><b>Shapes</b></em>' containment reference list.
	 * The list contents are of type {@link org.example.shapes.classes.Shape}.
	 * It is bidirectional and its opposite is '{@link org.example.shapes.classes.Shape#getCanvas <em>Canvas</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Shapes</em>' containment reference list.
	 * @see org.example.shapes.classes.ClassesPackage#getCanvas_Shapes()
	 * @see org.example.shapes.classes.Shape#getCanvas
	 * @model opposite="canvas" containment="true"
	 * @generated
	 */
	EList<Shape> getShapes();

	/**
	 * Returns the value of the '<em><b>Background</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Background</em>' containment reference.
	 * @see #isSetBackground()
	 * @see #unsetBackground()
	 * @see #setBackground(Shape)
	 * @see org.example.shapes.classes.ClassesPackage#getCanvas_Background()
	 * @model containment="true" unsettable="true"
	 * @generated
	 */
	Shape getBackground();

	/**
	 * Sets the value of the '{@link org.example.shapes.classes.Canvas#getBackground <em>Background</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Background</em>' containment reference.
	 * @see #isSetBackground()
	 * @see #unsetBackground()
	 * @see #getBackground()
	 * @generated
	 */
	void setBackground(Shape value);

	/**
	 * Unsets the value of the '{@link org.example.shapes.classes.Canvas#getBackground <em>Background</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isSetBackground()
	 * @see #getBackground()
	 * @see #setBackground(Shape)
	 * @generated
	 */
	void unsetBackground();

	/**
	 * Returns whether the value of the '{@link org.example.shapes.classes.Canvas#getBackground <em>Background</em>}' containment reference is set.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return whether the value of the '<em>Background</em>' containment reference is set.
	 * @see #unsetBackground()
	 * @see #getBackground()
	 * @see #setBackground(Shape)
	 * @generated
	 */
	boolean isSetBackground();

	/**
	 * Returns the value of the '<em><b>Favourites</b></em>' reference list.
	 * The list contents are of type {@link org.example.shapes.classes.Shape}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Favourites</em>' reference list.
	 * @see org.example.shapes.classes.ClassesPackage#getCanvas_Favourites()
	 * @model
	 * @generated
	 */
	EList<Shape> getFavourites();

	/**
	 * Returns the value of the '<em><b>Selected</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Selected</em>' reference.
	 * @see #setSelected(Shape)
	 * @see org.example.shapes.classes.ClassesPackage#getCanvas_Selected()
	 * @model resolveProxies="false"
	 * @generated
	 */
	Shape getSelected();

	/**
	 * Sets the value of the '{@link org.example.shapes.classes.Canvas#getSelected <em>Selected</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Selected</em>' reference.
	 * @see #getSelected()
	 * @generated
	 */
	void setSelected(Shape value);

	/**
	 * Returns the value of the '<em><b>Primary</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Primary</em>' reference.
	 * @see #isSetPrimary()
	 * @see #unsetPrimary()
	 * @see #setPrimary(Shape)
	 * @see org.example.shapes.classes.ClassesPackage#getCanvas_Primary()
	 * @model unsettable="true" required="true"
	 * @generated
	 */
	Shape getPrimary();

	/**
	 * Sets the value of the '{@link org.example.shapes.classes.Canvas#getPrimary <em>Primary</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Primary</em>' reference.
	 * @see #isSetPrimary()
	 * @see #unsetPrimary()
	 * @see #getPrimary()
	 * @generated
	 */
	void setPrimary(Shape value);

	/**
	 * Unsets the value of the '{@link org.example.shapes.classes.Canvas#getPrimary <em>Primary</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isSetPrimary()
	 * @see #getPrimary()
	 * @see #setPrimary(Shape)
	 * @generated
	 */
	void unsetPrimary();

	/**
	 * Returns whether the value of the '{@link org.example.shapes.classes.Canvas#getPrimary <em>Primary</em>}' reference is set.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return whether the value of the '<em>Primary</em>' reference is set.
	 * @see #unsetPrimary()
	 * @see #getPrimary()
	 * @see #setPrimary(Shape)
	 * @generated
	 */
	boolean isSetPrimary();

} // Canvas
