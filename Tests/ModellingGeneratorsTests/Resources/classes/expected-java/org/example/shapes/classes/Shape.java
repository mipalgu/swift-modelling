/**
 */
package org.example.shapes.classes;


import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Shape</b></em>'.
 * <!-- end-user-doc -->
 *
 * <!-- begin-model-doc -->
 * A shape on a canvas.
 * Shapes know their bounds.
 * @since 1.2
 * <!-- end-model-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.Shape#getLabel <em>Label</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#isVisible <em>Visible</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getWeight <em>Weight</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getTags <em>Tags</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getLevels <em>Levels</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getColour <em>Colour</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getDescription <em>Description</em>}</li>
 *   <li>{@link org.example.shapes.classes.Shape#getCanvas <em>Canvas</em>}</li>
 * </ul>
 *
 * @see org.example.shapes.classes.ClassesPackage#getShape()
 * @model abstract="true"
 * @generated
 */
public interface Shape extends EObject
{
  /**
   * Returns the value of the '<em><b>Label</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * <!-- begin-model-doc -->
   * The label of the shape.
   * <!-- end-model-doc -->
   * @return the value of the '<em>Label</em>' attribute.
   * @see #isSetLabel()
   * @see #unsetLabel()
   * @see #setLabel(String)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Label()
   * @model unsettable="true"
   * @generated
   */
  String getLabel();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#getLabel <em>Label</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Label</em>' attribute.
   * @see #isSetLabel()
   * @see #unsetLabel()
   * @see #getLabel()
   * @generated
   */
  void setLabel(String value);

  /**
   * Unsets the value of the '{@link org.example.shapes.classes.Shape#getLabel <em>Label</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isSetLabel()
   * @see #getLabel()
   * @see #setLabel(String)
   * @generated
   */
  void unsetLabel();

  /**
   * Returns whether the value of the '{@link org.example.shapes.classes.Shape#getLabel <em>Label</em>}' attribute is set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return whether the value of the '<em>Label</em>' attribute is set.
   * @see #unsetLabel()
   * @see #getLabel()
   * @see #setLabel(String)
   * @generated
   */
  boolean isSetLabel();

  /**
   * Returns the value of the '<em><b>Visible</b></em>' attribute.
   * The default value is <code>"true"</code>.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Visible</em>' attribute.
   * @see #setVisible(boolean)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Visible()
   * @model default="true"
   * @generated
   */
  boolean isVisible();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#isVisible <em>Visible</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Visible</em>' attribute.
   * @see #isVisible()
   * @generated
   */
  void setVisible(boolean value);

  /**
   * Returns the value of the '<em><b>Weight</b></em>' attribute.
   * The default value is <code>"1.5"</code>.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Weight</em>' attribute.
   * @see #isSetWeight()
   * @see #unsetWeight()
   * @see #setWeight(double)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Weight()
   * @model default="1.5" unsettable="true"
   * @generated
   */
  double getWeight();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#getWeight <em>Weight</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Weight</em>' attribute.
   * @see #isSetWeight()
   * @see #unsetWeight()
   * @see #getWeight()
   * @generated
   */
  void setWeight(double value);

  /**
   * Unsets the value of the '{@link org.example.shapes.classes.Shape#getWeight <em>Weight</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isSetWeight()
   * @see #getWeight()
   * @see #setWeight(double)
   * @generated
   */
  void unsetWeight();

  /**
   * Returns whether the value of the '{@link org.example.shapes.classes.Shape#getWeight <em>Weight</em>}' attribute is set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return whether the value of the '<em>Weight</em>' attribute is set.
   * @see #unsetWeight()
   * @see #getWeight()
   * @see #setWeight(double)
   * @generated
   */
  boolean isSetWeight();

  /**
   * Returns the value of the '<em><b>Tags</b></em>' attribute list.
   * The list contents are of type {@link java.lang.String}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Tags</em>' attribute list.
   * @see org.example.shapes.classes.ClassesPackage#getShape_Tags()
   * @model
   * @generated
   */
  EList<String> getTags();

  /**
   * Returns the value of the '<em><b>Levels</b></em>' attribute list.
   * The list contents are of type {@link java.lang.Integer}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Levels</em>' attribute list.
   * @see #isSetLevels()
   * @see #unsetLevels()
   * @see org.example.shapes.classes.ClassesPackage#getShape_Levels()
   * @model unique="false" unsettable="true"
   * @generated
   */
  EList<Integer> getLevels();

  /**
   * Unsets the value of the '{@link org.example.shapes.classes.Shape#getLevels <em>Levels</em>}' attribute list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isSetLevels()
   * @see #getLevels()
   * @generated
   */
  void unsetLevels();

  /**
   * Returns whether the value of the '{@link org.example.shapes.classes.Shape#getLevels <em>Levels</em>}' attribute list is set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return whether the value of the '<em>Levels</em>' attribute list is set.
   * @see #unsetLevels()
   * @see #getLevels()
   * @generated
   */
  boolean isSetLevels();

  /**
   * Returns the value of the '<em><b>Colour</b></em>' attribute.
   * The default value is <code>"Green"</code>.
   * The literals are from the enumeration {@link org.example.shapes.classes.Colour}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Colour</em>' attribute.
   * @see org.example.shapes.classes.Colour
   * @see #setColour(Colour)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Colour()
   * @model default="Green"
   * @generated
   */
  Colour getColour();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#getColour <em>Colour</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Colour</em>' attribute.
   * @see org.example.shapes.classes.Colour
   * @see #getColour()
   * @generated
   */
  void setColour(Colour value);

  /**
   * Returns the value of the '<em><b>Description</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Description</em>' attribute.
   * @see #setDescription(String)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Description()
   * @model transient="true" volatile="true" derived="true"
   *        annotation="http://www.eclipse.org/emf/2002/GenModel get='return getLabel() + \&quot; shape\&quot;;'"
   * @generated
   */
  String getDescription();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#getDescription <em>Description</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Description</em>' attribute.
   * @see #getDescription()
   * @generated
   */
  void setDescription(String value);

  /**
   * Returns the value of the '<em><b>Canvas</b></em>' container reference.
   * It is bidirectional and its opposite is '{@link org.example.shapes.classes.Canvas#getShapes <em>Shapes</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Canvas</em>' container reference.
   * @see #setCanvas(Canvas)
   * @see org.example.shapes.classes.ClassesPackage#getShape_Canvas()
   * @see org.example.shapes.classes.Canvas#getShapes
   * @model opposite="shapes" transient="false"
   * @generated
   */
  Canvas getCanvas();

  /**
   * Sets the value of the '{@link org.example.shapes.classes.Shape#getCanvas <em>Canvas</em>}' container reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Canvas</em>' container reference.
   * @see #getCanvas()
   * @generated
   */
  void setCanvas(Canvas value);

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * <!-- begin-model-doc -->
   * The area of the shape.
   * <!-- end-model-doc -->
   * @model annotation="http://www.eclipse.org/emf/2002/GenModel body='return 0.0;'"
   * @generated
   */
  double area();

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * <!-- begin-model-doc -->
   * Moves the shape.
   * @param dx The horizontal distance.
   * <!-- end-model-doc -->
   * @model
   * @generated
   */
  void move(int dx, int dy);

} // Shape
