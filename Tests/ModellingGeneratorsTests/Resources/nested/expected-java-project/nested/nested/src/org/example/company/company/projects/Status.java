/**
 */
package org.example.company.company.projects;


import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.Enumerator;


/**
 * <!-- begin-user-doc -->
 * A representation of the literals of the enumeration '<em><b>Status</b></em>',
 * and utility methods for working with them.
 * <!-- end-user-doc -->
 * @see org.example.company.company.projects.ProjPackage#getStatus()
 * @model
 * @generated
 */
public enum Status implements Enumerator
{
  /**
   * The '<em><b>Proposed</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #PROPOSED_VALUE
   * @generated
   * @ordered
   */
  PROPOSED(0, "Proposed", "Proposed"),
  /**
   * The '<em><b>Active</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #ACTIVE_VALUE
   * @generated
   * @ordered
   */
  ACTIVE(1, "Active", "Active"),
  /**
   * The '<em><b>Finished</b></em>' literal object.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #FINISHED_VALUE
   * @generated
   * @ordered
   */
  FINISHED(2, "Finished", "Finished");
  /**
   * The '<em><b>Proposed</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #PROPOSED
   * @model name="Proposed"
   * @generated
   * @ordered
   */
  public static final int PROPOSED_VALUE = 0;

  /**
   * The '<em><b>Active</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #ACTIVE
   * @model name="Active"
   * @generated
   * @ordered
   */
  public static final int ACTIVE_VALUE = 1;

  /**
   * The '<em><b>Finished</b></em>' literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #FINISHED
   * @model name="Finished"
   * @generated
   * @ordered
   */
  public static final int FINISHED_VALUE = 2;

  /**
   * An array of all the '<em><b>Status</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private static final Status[] VALUES_ARRAY =
    new Status[]
    {
      PROPOSED,
      ACTIVE,
      FINISHED,
    };

  /**
   * A public read-only list of all the '<em><b>Status</b></em>' enumerators.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static final List<Status> VALUES = Collections.unmodifiableList(Arrays.asList(VALUES_ARRAY));

  /**
   * Returns the '<em><b>Status</b></em>' literal with the specified literal value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param literal the literal.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Status get(String literal)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Status result = VALUES_ARRAY[i];
      if (result.toString().equals(literal))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Status</b></em>' literal with the specified name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param name the name.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Status getByName(String name)
  {
    for (int i = 0; i < VALUES_ARRAY.length; ++i)
    {
      Status result = VALUES_ARRAY[i];
      if (result.getName().equals(name))
      {
        return result;
      }
    }
    return null;
  }

  /**
   * Returns the '<em><b>Status</b></em>' literal with the specified integer value.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the integer value.
   * @return the matching enumerator or <code>null</code>.
   * @generated
   */
  public static Status get(int value)
  {
    switch (value)
    {
      case PROPOSED_VALUE: return PROPOSED;
      case ACTIVE_VALUE: return ACTIVE;
      case FINISHED_VALUE: return FINISHED;
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
  private Status(int value, String name, String literal)
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
