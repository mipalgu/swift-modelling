/**
 */
package org.example.traffic.enumerations;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.Enumerator;

/**
 * <!-- begin-user-doc -->
 * A representation of the literals of the enumeration '<em><b>Mode</b></em>',
 * and utility methods for working with them.
 * <!-- end-user-doc -->
 * @see org.example.traffic.enumerations.EnumerationsPackage#getMode()
 * @model
 * @generated
 */
public enum Mode implements Enumerator
{
  /**
   * The '<em><b>Default</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #DEFAULT_VALUE
   * @generated
   * @ordered
   */
  DEFAULT(0, "default", "default"),
  /**
   * The '<em><b>Fast Forward</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #FAST_FORWARD_VALUE
   * @generated
   * @ordered
   */
  FAST_FORWARD(1, "fastForward", "fastForward"),
  /**
   * The '<em><b>HTTP Server</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #HTTP_SERVER_VALUE
   * @generated
   * @ordered
   */
  HTTP_SERVER(2, "HTTPServer", "HTTPServer"),
  /**
   * The '<em><b></b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #___VALUE
   * @generated
   * @ordered
   */
  __(3, "__", "_"),
  /**
   * The '<em><b>Quote</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #QUOTE_VALUE
   * @generated
   * @ordered
   */
  QUOTE(4, "quote", "say \"hi\"");
  /**
   * The '<em><b>Default</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #DEFAULT
   * @model name="default"
   * @generated
   * @ordered
   */
  public static final int DEFAULT_VALUE = 0;

  /**
   * The '<em><b>Fast Forward</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #FAST_FORWARD
   * @model name="fastForward"
   * @generated
   * @ordered
   */
  public static final int FAST_FORWARD_VALUE = 1;

  /**
   * The '<em><b>HTTP Server</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #HTTP_SERVER
   * @model name="HTTPServer"
   * @generated
   * @ordered
   */
  public static final int HTTP_SERVER_VALUE = 2;

  /**
   * The '<em><b></b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #__
   * @model literal="_"
   * @generated
   * @ordered
   */
  public static final int ___VALUE = 3;

  /**
   * The '<em><b>Quote</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #QUOTE
   * @model name="quote"
   *        literal="say \&quot;hi\&quot;"
   * @generated
   * @ordered
   */
  public static final int QUOTE_VALUE = 4;

  /**
   * An array of all the '<em><b>Mode</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private static final Mode[] VALUES_ARRAY =
    new Mode[]
    {
      DEFAULT,
      FAST_FORWARD,
      HTTP_SERVER,
      __,
      QUOTE,
    };

  /**
   * A public read-only list of all the '<em><b>Mode</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static final List<Mode> VALUES = Collections.unmodifiableList(Arrays.asList(VALUES_ARRAY));

  /**
   * Returns the '<em><b>Mode</b></em>' literal with the specified literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param literal the literal.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Mode get(String literal)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Mode result = VALUES_ARRAY[i];
      if (result.toString().equals(literal))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Mode</b></em>' literal with the specified name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param name the name.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Mode getByName(String name)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Mode result = VALUES_ARRAY[i];
      if (result.getName().equals(name))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Mode</b></em>' literal with the specified integer value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the integer value.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Mode get(int value)
  {
    switch (value)
    {
      case DEFAULT_VALUE: return DEFAULT;
      case FAST_FORWARD_VALUE: return FAST_FORWARD;
      case HTTP_SERVER_VALUE: return HTTP_SERVER;
      case ___VALUE: return __;
      case QUOTE_VALUE: return QUOTE;
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
  private Mode(int value, String name, String literal)
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
