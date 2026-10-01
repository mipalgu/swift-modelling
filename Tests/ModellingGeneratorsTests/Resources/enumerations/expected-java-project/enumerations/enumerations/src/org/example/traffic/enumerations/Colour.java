/**
 */
package org.example.traffic.enumerations;


import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.Enumerator;


/**
 * <!-- begin-user-doc -->
 * A representation of the literals of the enumeration '<em><b>Colour</b></em>',
 * and utility methods for working with them.
 * <!-- end-user-doc -->
 * @see org.example.traffic.enumerations.EnumerationsPackage#getColour()
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
  RED(0, "Red", "red"),
  /**
   * The '<em><b>Amber</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #AMBER_VALUE
   * @generated
   * @ordered
   */
  AMBER(1, "Amber", "amber"),
  /**
   * The '<em><b>Yellow</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #YELLOW_VALUE
   * @generated
   * @ordered
   */
  YELLOW(1, "Yellow", "yellow"),
  /**
   * The '<em><b>Green</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #GREEN_VALUE
   * @generated
   * @ordered
   */
  GREEN(5, "Green", "Green");
  /**
   * The '<em><b>Red</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #RED
   * @model name="Red"
   *        literal="red"
   * @generated
   * @ordered
   */
  public static final int RED_VALUE = 0;

  /**
   * The '<em><b>Amber</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #AMBER
   * @model name="Amber"
   *        literal="amber"
   * @generated
   * @ordered
   */
  public static final int AMBER_VALUE = 1;

  /**
   * The '<em><b>Yellow</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #YELLOW
   * @model name="Yellow"
   *        literal="yellow"
   * @generated
   * @ordered
   */
  public static final int YELLOW_VALUE = 1;

  /**
   * The '<em><b>Green</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #GREEN
   * @model name="Green"
   * @generated
   * @ordered
   */
  public static final int GREEN_VALUE = 5;

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
      AMBER,
      YELLOW,
      GREEN,
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
      case AMBER_VALUE: return AMBER;
      case GREEN_VALUE: return GREEN;
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
