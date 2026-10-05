/**
 */
package org.example.bridge.bridge;

import org.eclipse.emf.ecore.EFactory;

/**
 * <!-- begin-user-doc -->
 * The <b>Factory</b> for the model.
 * It provides a create method for each non-abstract class of the model.
 * <!-- end-user-doc -->
 * @see org.example.bridge.bridge.BridgePackage
 * @generated
 */
public interface BridgeFactory extends EFactory {
	/**
	 * The singleton instance of the factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	BridgeFactory eINSTANCE = org.example.bridge.bridge.impl.BridgeFactoryImpl.init();

	/**
	 * Returns a new object of class '<em>Span</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return a new object of class '<em>Span</em>'.
	 * @generated
	 */
	Span createSpan();

	/**
	 * Returns the package supported by this factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the package supported by this factory.
	 * @generated
	 */
	BridgePackage getBridgePackage();

} //BridgeFactory
