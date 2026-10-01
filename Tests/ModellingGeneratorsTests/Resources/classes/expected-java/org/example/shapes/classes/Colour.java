/**
 */
package org.example.shapes.classes;


import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.Enumerator;


/**
 * <!-- begin-user-doc -->
 * A representation of the literals of the enumeration '<em><b>Colour</b></em>',
 * and utility methods for working with them.
 * <!-- end-user-doc -->
 * @see org.example.shapes.classes.ClassesPackage#getColour()
 * @model
 * @generated
 */
public enum Colour implements Enumerator
{
  /**
   * The '<em><b>Red</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #RED_VALUE
   * @generated
   * @ordered
   */
  RED(0, "Red", "Red"),
  /**
   * The '<em><b>Green</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #GREEN_VALUE
   * @generated
   * @ordered
   */
  GREEN(1, "Green", "Green"),
  /**
   * The '<em><b>Blue</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #BLUE_VALUE
   * @generated
   * @ordered
   */
  BLUE(2, "Blue", "Blue");
  /**
   * The '<em><b>Red</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #RED
   * @model name="Red"
   * @generated
   * @ordered
   */
  public static final int RED_VALUE = 0;

  /**
   * The '<em><b>Green</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #GREEN
   * @model name="Green"
   * @generated
   * @ordered
   */
  public static final int GREEN_VALUE = 1;

  /**
   * The '<em><b>Blue</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #BLUE
   * @model name="Blue"
   * @generated
   * @ordered
   */
  public static final int BLUE_VALUE = 2;

  /**
   * An array of all the '<em><b>Colour</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private static final Colour[] VALUES_ARRAY =
    new Colour[]
    {
      RED,
      GREEN,
      BLUE,
    };

  /**
   * A public read-only list of all the '<em><b>Colour</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static final List<Colour> VALUES = Collections.unmodifiableList(Arrays.asList(VALUES_ARRAY));

  /**
   * Returns the '<em><b>Colour</b></em>' literal with the specified literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param literal the literal.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Colour get(String literal)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Colour result = VALUES_ARRAY[i];
      if (result.toString().equals(literal))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Colour</b></em>' literal with the specified name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param name the name.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Colour getByName(String name)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Colour result = VALUES_ARRAY[i];
      if (result.getName().equals(name))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Colour</b></em>' literal with the specified integer value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the integer value.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Colour get(int value)
  {
    switch (value)
    {
      case RED_VALUE: return RED;
      case GREEN_VALUE: return GREEN;
      case BLUE_VALUE: return BLUE;
    }
    return null;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private final int value;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private final String name;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private final String literal;

  /**
   * Only this class can construct instances.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private Colour(int value, String name, String literal)
  {
    this.value = value;
    this.name = name;
    this.literal = literal;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public int getValue()
  {
    return value;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getName()
  {
    return name;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getLiteral()
  {
    return literal;
  }

  /**
   * Returns the literal value of the enumerator, which is its string representation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String toString()
  {
    return literal;
  }
}
