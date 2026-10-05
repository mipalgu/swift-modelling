/**
 */
package org.example.alarm.documented.impl;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EDataType;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

import org.example.alarm.documented.*;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class DocumentedFactoryImpl extends EFactoryImpl implements DocumentedFactory
{
  /**
   * Creates the default factory implementation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static DocumentedFactory init()
  {
    try
    {
      DocumentedFactory theDocumentedFactory = (DocumentedFactory)EPackage.Registry.INSTANCE.getEFactory(DocumentedPackage.eNS_URI);
      if (theDocumentedFactory != null)
      {
        return theDocumentedFactory;
      }
    }
    catch (Exception exception)
    {
      EcorePlugin.INSTANCE.log(exception);
    }
    return new DocumentedFactoryImpl();
  }

  /**
   * Creates an instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public DocumentedFactoryImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EObject create(EClass eClass)
  {
    switch (eClass.getClassifierID())
    {
      default:
        throw new IllegalArgumentException("The class '" + eClass.getName() + "' is not a valid classifier");
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object createFromString(EDataType eDataType, String initialValue)
  {
    switch (eDataType.getClassifierID())
    {
      case DocumentedPackage.LEVEL:
        return createLevelFromString(eDataType, initialValue);
      default:
        throw new IllegalArgumentException("The datatype '" + eDataType.getName() + "' is not a valid classifier");
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String convertToString(EDataType eDataType, Object instanceValue)
  {
    switch (eDataType.getClassifierID())
    {
      case DocumentedPackage.LEVEL:
        return convertLevelToString(eDataType, instanceValue);
      default:
        throw new IllegalArgumentException("The datatype '" + eDataType.getName() + "' is not a valid classifier");
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public Level createLevelFromString(EDataType eDataType, String initialValue)
  {
    Level result = Level.get(initialValue);
    if (result == null) throw new IllegalArgumentException("The value '" + initialValue + "' is not a valid enumerator of '" + eDataType.getName() + "'");
    return result;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public String convertLevelToString(EDataType eDataType, Object instanceValue)
  {
    return instanceValue == null ? null : instanceValue.toString();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public DocumentedPackage getDocumentedPackage()
  {
    return (DocumentedPackage)getEPackage();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @deprecated
   * @generated
   */
  @Deprecated
  public static DocumentedPackage getPackage()
  {
    return DocumentedPackage.eINSTANCE;
  }

} //DocumentedFactoryImpl
