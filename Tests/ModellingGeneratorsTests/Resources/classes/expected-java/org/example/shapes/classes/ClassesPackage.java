/**
 */
package org.example.shapes.classes;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EOperation;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

/**
 * <!-- begin-user-doc -->
 * The <b>Package</b> for the model.
 * It contains accessors for the meta objects to represent
 * <ul>
 *   <li>each class,</li>
 *   <li>each feature of each class,</li>
 *   <li>each operation of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see org.example.shapes.classes.ClassesFactory
 * @model kind="package"
 * @generated
 */
public interface ClassesPackage extends EPackage {
	/**
	 * The package name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNAME = "classes";

	/**
	 * The package namespace URI.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_URI = "http://swift-modelling.org/test/classes";

	/**
	 * The package namespace name.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	String eNS_PREFIX = "cls";

	/**
	 * The singleton instance of the package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	ClassesPackage eINSTANCE = org.example.shapes.classes.impl.ClassesPackageImpl.init();

	/**
	 * The meta object id for the '{@link org.example.shapes.classes.impl.ShapeImpl <em>Shape</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.example.shapes.classes.impl.ShapeImpl
	 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getShape()
	 * @since 1.2
	 * @generated
	 */
	int SHAPE = 0;

	/**
	 * The feature id for the '<em><b>Label</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__LABEL = 0;

	/**
	 * The feature id for the '<em><b>Visible</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__VISIBLE = 1;

	/**
	 * The feature id for the '<em><b>Weight</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__WEIGHT = 2;

	/**
	 * The feature id for the '<em><b>Tags</b></em>' attribute list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__TAGS = 3;

	/**
	 * The feature id for the '<em><b>Levels</b></em>' attribute list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__LEVELS = 4;

	/**
	 * The feature id for the '<em><b>Colour</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__COLOUR = 5;

	/**
	 * The feature id for the '<em><b>Description</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__DESCRIPTION = 6;

	/**
	 * The feature id for the '<em><b>Canvas</b></em>' container reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE__CANVAS = 7;

	/**
	 * The number of structural features of the '<em>Shape</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE_FEATURE_COUNT = 8;

	/**
	 * The operation id for the '<em>Area</em>' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE___AREA = 0;

	/**
	 * The operation id for the '<em>Move</em>' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE___MOVE__INT_INT = 1;

	/**
	 * The number of operations of the '<em>Shape</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int SHAPE_OPERATION_COUNT = 2;

	/**
	 * The meta object id for the '{@link org.example.shapes.classes.impl.CanvasImpl <em>Canvas</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.example.shapes.classes.impl.CanvasImpl
	 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getCanvas()
	 * @generated
	 */
	int CANVAS = 1;

	/**
	 * The feature id for the '<em><b>Shapes</b></em>' containment reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS__SHAPES = 0;

	/**
	 * The feature id for the '<em><b>Background</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS__BACKGROUND = 1;

	/**
	 * The feature id for the '<em><b>Favourites</b></em>' reference list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS__FAVOURITES = 2;

	/**
	 * The feature id for the '<em><b>Selected</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS__SELECTED = 3;

	/**
	 * The feature id for the '<em><b>Primary</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS__PRIMARY = 4;

	/**
	 * The number of structural features of the '<em>Canvas</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS_FEATURE_COUNT = 5;

	/**
	 * The number of operations of the '<em>Canvas</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CANVAS_OPERATION_COUNT = 0;

	/**
	 * The meta object id for the '{@link org.example.shapes.classes.Named <em>Named</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.example.shapes.classes.Named
	 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getNamed()
	 * @generated
	 */
	int NAMED = 2;

	/**
	 * The feature id for the '<em><b>Name</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int NAMED__NAME = 0;

	/**
	 * The number of structural features of the '<em>Named</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int NAMED_FEATURE_COUNT = 1;

	/**
	 * The number of operations of the '<em>Named</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int NAMED_OPERATION_COUNT = 0;

	/**
	 * The meta object id for the '{@link org.example.shapes.classes.impl.CircleImpl <em>Circle</em>}' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.example.shapes.classes.impl.CircleImpl
	 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getCircle()
	 * @generated
	 */
	int CIRCLE = 3;

	/**
	 * The feature id for the '<em><b>Label</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__LABEL = SHAPE__LABEL;

	/**
	 * The feature id for the '<em><b>Visible</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__VISIBLE = SHAPE__VISIBLE;

	/**
	 * The feature id for the '<em><b>Weight</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__WEIGHT = SHAPE__WEIGHT;

	/**
	 * The feature id for the '<em><b>Tags</b></em>' attribute list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__TAGS = SHAPE__TAGS;

	/**
	 * The feature id for the '<em><b>Levels</b></em>' attribute list.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__LEVELS = SHAPE__LEVELS;

	/**
	 * The feature id for the '<em><b>Colour</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__COLOUR = SHAPE__COLOUR;

	/**
	 * The feature id for the '<em><b>Description</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__DESCRIPTION = SHAPE__DESCRIPTION;

	/**
	 * The feature id for the '<em><b>Canvas</b></em>' container reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE__CANVAS = SHAPE__CANVAS;

	/**
	 * The feature id for the '<em><b>Name</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CIRCLE__NAME = SHAPE_FEATURE_COUNT + 0;

	/**
	 * The feature id for the '<em><b>Radius</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CIRCLE__RADIUS = SHAPE_FEATURE_COUNT + 1;

	/**
	 * The feature id for the '<em><b>Filled</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CIRCLE__FILLED = SHAPE_FEATURE_COUNT + 2;

	/**
	 * The number of structural features of the '<em>Circle</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CIRCLE_FEATURE_COUNT = SHAPE_FEATURE_COUNT + 3;

	/**
	 * The operation id for the '<em>Area</em>' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE___AREA = SHAPE___AREA;

	/**
	 * The operation id for the '<em>Move</em>' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @since 1.2
	 * @generated
	 * @ordered
	 */
	int CIRCLE___MOVE__INT_INT = SHAPE___MOVE__INT_INT;

	/**
	 * The number of operations of the '<em>Circle</em>' class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @ordered
	 */
	int CIRCLE_OPERATION_COUNT = SHAPE_OPERATION_COUNT + 0;

	/**
	 * The meta object id for the '{@link org.example.shapes.classes.Colour <em>Colour</em>}' enum.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.example.shapes.classes.Colour
	 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getColour()
	 * @generated
	 */
	int COLOUR = 4;


	/**
	 * Returns the meta object for class '{@link org.example.shapes.classes.Shape <em>Shape</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Shape</em>'.
	 * @see org.example.shapes.classes.Shape
	 * @since 1.2
	 * @generated
	 */
	EClass getShape();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Shape#getLabel <em>Label</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Label</em>'.
	 * @see org.example.shapes.classes.Shape#getLabel()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Label();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Shape#isVisible <em>Visible</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Visible</em>'.
	 * @see org.example.shapes.classes.Shape#isVisible()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Visible();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Shape#getWeight <em>Weight</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Weight</em>'.
	 * @see org.example.shapes.classes.Shape#getWeight()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Weight();

	/**
	 * Returns the meta object for the attribute list '{@link org.example.shapes.classes.Shape#getTags <em>Tags</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute list '<em>Tags</em>'.
	 * @see org.example.shapes.classes.Shape#getTags()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Tags();

	/**
	 * Returns the meta object for the attribute list '{@link org.example.shapes.classes.Shape#getLevels <em>Levels</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute list '<em>Levels</em>'.
	 * @see org.example.shapes.classes.Shape#getLevels()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Levels();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Shape#getColour <em>Colour</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Colour</em>'.
	 * @see org.example.shapes.classes.Shape#getColour()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Colour();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Shape#getDescription <em>Description</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Description</em>'.
	 * @see org.example.shapes.classes.Shape#getDescription()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EAttribute getShape_Description();

	/**
	 * Returns the meta object for the container reference '{@link org.example.shapes.classes.Shape#getCanvas <em>Canvas</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the container reference '<em>Canvas</em>'.
	 * @see org.example.shapes.classes.Shape#getCanvas()
	 * @see #getShape()
	 * @since 1.2
	 * @generated
	 */
	EReference getShape_Canvas();

	/**
	 * Returns the meta object for the '{@link org.example.shapes.classes.Shape#area() <em>Area</em>}' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the '<em>Area</em>' operation.
	 * @see org.example.shapes.classes.Shape#area()
	 * @since 1.2
	 * @generated
	 */
	EOperation getShape__Area();

	/**
	 * Returns the meta object for the '{@link org.example.shapes.classes.Shape#move(int, int) <em>Move</em>}' operation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the '<em>Move</em>' operation.
	 * @see org.example.shapes.classes.Shape#move(int, int)
	 * @since 1.2
	 * @generated
	 */
	EOperation getShape__Move__int_int();

	/**
	 * Returns the meta object for class '{@link org.example.shapes.classes.Canvas <em>Canvas</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Canvas</em>'.
	 * @see org.example.shapes.classes.Canvas
	 * @generated
	 */
	EClass getCanvas();

	/**
	 * Returns the meta object for the containment reference list '{@link org.example.shapes.classes.Canvas#getShapes <em>Shapes</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference list '<em>Shapes</em>'.
	 * @see org.example.shapes.classes.Canvas#getShapes()
	 * @see #getCanvas()
	 * @generated
	 */
	EReference getCanvas_Shapes();

	/**
	 * Returns the meta object for the containment reference '{@link org.example.shapes.classes.Canvas#getBackground <em>Background</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the containment reference '<em>Background</em>'.
	 * @see org.example.shapes.classes.Canvas#getBackground()
	 * @see #getCanvas()
	 * @generated
	 */
	EReference getCanvas_Background();

	/**
	 * Returns the meta object for the reference list '{@link org.example.shapes.classes.Canvas#getFavourites <em>Favourites</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference list '<em>Favourites</em>'.
	 * @see org.example.shapes.classes.Canvas#getFavourites()
	 * @see #getCanvas()
	 * @generated
	 */
	EReference getCanvas_Favourites();

	/**
	 * Returns the meta object for the reference '{@link org.example.shapes.classes.Canvas#getSelected <em>Selected</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference '<em>Selected</em>'.
	 * @see org.example.shapes.classes.Canvas#getSelected()
	 * @see #getCanvas()
	 * @generated
	 */
	EReference getCanvas_Selected();

	/**
	 * Returns the meta object for the reference '{@link org.example.shapes.classes.Canvas#getPrimary <em>Primary</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the reference '<em>Primary</em>'.
	 * @see org.example.shapes.classes.Canvas#getPrimary()
	 * @see #getCanvas()
	 * @generated
	 */
	EReference getCanvas_Primary();

	/**
	 * Returns the meta object for class '{@link org.example.shapes.classes.Named <em>Named</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Named</em>'.
	 * @see org.example.shapes.classes.Named
	 * @generated
	 */
	EClass getNamed();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Named#getName <em>Name</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Name</em>'.
	 * @see org.example.shapes.classes.Named#getName()
	 * @see #getNamed()
	 * @generated
	 */
	EAttribute getNamed_Name();

	/**
	 * Returns the meta object for class '{@link org.example.shapes.classes.Circle <em>Circle</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for class '<em>Circle</em>'.
	 * @see org.example.shapes.classes.Circle
	 * @generated
	 */
	EClass getCircle();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Circle#getRadius <em>Radius</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Radius</em>'.
	 * @see org.example.shapes.classes.Circle#getRadius()
	 * @see #getCircle()
	 * @generated
	 */
	EAttribute getCircle_Radius();

	/**
	 * Returns the meta object for the attribute '{@link org.example.shapes.classes.Circle#isFilled <em>Filled</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for the attribute '<em>Filled</em>'.
	 * @see org.example.shapes.classes.Circle#isFilled()
	 * @see #getCircle()
	 * @generated
	 */
	EAttribute getCircle_Filled();

	/**
	 * Returns the meta object for enum '{@link org.example.shapes.classes.Colour <em>Colour</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the meta object for enum '<em>Colour</em>'.
	 * @see org.example.shapes.classes.Colour
	 * @generated
	 */
	EEnum getColour();

	/**
	 * Returns the factory that creates the instances of the model.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the factory that creates the instances of the model.
	 * @generated
	 */
	ClassesFactory getClassesFactory();

	/**
	 * <!-- begin-user-doc -->
	 * Defines literals for the meta objects that represent
	 * <ul>
	 *   <li>each class,</li>
	 *   <li>each feature of each class,</li>
	 *   <li>each operation of each class,</li>
	 *   <li>each enum,</li>
	 *   <li>and each data type</li>
	 * </ul>
	 * <!-- end-user-doc -->
	 * @generated
	 */
	interface Literals {
		/**
		 * The meta object literal for the '{@link org.example.shapes.classes.impl.ShapeImpl <em>Shape</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see org.example.shapes.classes.impl.ShapeImpl
		 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getShape()
		 * @since 1.2
		 * @generated
		 */
		EClass SHAPE = eINSTANCE.getShape();

		/**
		 * The meta object literal for the '<em><b>Label</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__LABEL = eINSTANCE.getShape_Label();

		/**
		 * The meta object literal for the '<em><b>Visible</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__VISIBLE = eINSTANCE.getShape_Visible();

		/**
		 * The meta object literal for the '<em><b>Weight</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__WEIGHT = eINSTANCE.getShape_Weight();

		/**
		 * The meta object literal for the '<em><b>Tags</b></em>' attribute list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__TAGS = eINSTANCE.getShape_Tags();

		/**
		 * The meta object literal for the '<em><b>Levels</b></em>' attribute list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__LEVELS = eINSTANCE.getShape_Levels();

		/**
		 * The meta object literal for the '<em><b>Colour</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__COLOUR = eINSTANCE.getShape_Colour();

		/**
		 * The meta object literal for the '<em><b>Description</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EAttribute SHAPE__DESCRIPTION = eINSTANCE.getShape_Description();

		/**
		 * The meta object literal for the '<em><b>Canvas</b></em>' container reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EReference SHAPE__CANVAS = eINSTANCE.getShape_Canvas();

		/**
		 * The meta object literal for the '<em><b>Area</b></em>' operation.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EOperation SHAPE___AREA = eINSTANCE.getShape__Area();

		/**
		 * The meta object literal for the '<em><b>Move</b></em>' operation.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @since 1.2
		 * @generated
		 */
		EOperation SHAPE___MOVE__INT_INT = eINSTANCE.getShape__Move__int_int();

		/**
		 * The meta object literal for the '{@link org.example.shapes.classes.impl.CanvasImpl <em>Canvas</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see org.example.shapes.classes.impl.CanvasImpl
		 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getCanvas()
		 * @generated
		 */
		EClass CANVAS = eINSTANCE.getCanvas();

		/**
		 * The meta object literal for the '<em><b>Shapes</b></em>' containment reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CANVAS__SHAPES = eINSTANCE.getCanvas_Shapes();

		/**
		 * The meta object literal for the '<em><b>Background</b></em>' containment reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CANVAS__BACKGROUND = eINSTANCE.getCanvas_Background();

		/**
		 * The meta object literal for the '<em><b>Favourites</b></em>' reference list feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CANVAS__FAVOURITES = eINSTANCE.getCanvas_Favourites();

		/**
		 * The meta object literal for the '<em><b>Selected</b></em>' reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CANVAS__SELECTED = eINSTANCE.getCanvas_Selected();

		/**
		 * The meta object literal for the '<em><b>Primary</b></em>' reference feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EReference CANVAS__PRIMARY = eINSTANCE.getCanvas_Primary();

		/**
		 * The meta object literal for the '{@link org.example.shapes.classes.Named <em>Named</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see org.example.shapes.classes.Named
		 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getNamed()
		 * @generated
		 */
		EClass NAMED = eINSTANCE.getNamed();

		/**
		 * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute NAMED__NAME = eINSTANCE.getNamed_Name();

		/**
		 * The meta object literal for the '{@link org.example.shapes.classes.impl.CircleImpl <em>Circle</em>}' class.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see org.example.shapes.classes.impl.CircleImpl
		 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getCircle()
		 * @generated
		 */
		EClass CIRCLE = eINSTANCE.getCircle();

		/**
		 * The meta object literal for the '<em><b>Radius</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute CIRCLE__RADIUS = eINSTANCE.getCircle_Radius();

		/**
		 * The meta object literal for the '<em><b>Filled</b></em>' attribute feature.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @generated
		 */
		EAttribute CIRCLE__FILLED = eINSTANCE.getCircle_Filled();

		/**
		 * The meta object literal for the '{@link org.example.shapes.classes.Colour <em>Colour</em>}' enum.
		 * <!-- begin-user-doc -->
		 * <!-- end-user-doc -->
		 * @see org.example.shapes.classes.Colour
		 * @see org.example.shapes.classes.impl.ClassesPackageImpl#getColour()
		 * @generated
		 */
		EEnum COLOUR = eINSTANCE.getColour();

	}

} //ClassesPackage
