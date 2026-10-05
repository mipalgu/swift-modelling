/**
 */
package org.example.bank.bank.util;

import java.math.BigDecimal;

import java.util.Collection;
import java.util.Map;

import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.DiagnosticChain;
import org.eclipse.emf.common.util.ResourceLocator;

import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.util.EObjectValidator;

import org.eclipse.emf.ecore.xml.type.util.XMLTypeUtil;

import org.example.bank.bank.*;

/**
 * <!-- begin-user-doc -->
 * The <b>Validator</b> for the model.
 * <!-- end-user-doc -->
 * @see org.example.bank.bank.BankPackage
 * @generated
 */
public class BankValidator extends EObjectValidator {
	/**
	 * The cached model package
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public static final BankValidator INSTANCE = new BankValidator();

	/**
	 * A constant for the {@link org.eclipse.emf.common.util.Diagnostic#getSource() source} of diagnostic {@link org.eclipse.emf.common.util.Diagnostic#getCode() codes} from this package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see org.eclipse.emf.common.util.Diagnostic#getSource()
	 * @see org.eclipse.emf.common.util.Diagnostic#getCode()
	 * @generated
	 */
	public static final String DIAGNOSTIC_SOURCE = "org.example.bank.bank";

	/**
	 * The {@link org.eclipse.emf.common.util.Diagnostic#getCode() code} for constraint 'Has Owner' of 'Account'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public static final int ACCOUNT__HAS_OWNER = 1;

	/**
	 * A constant with a fixed name that can be used as the base value for additional hand written constants.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	private static final int GENERATED_DIAGNOSTIC_CODE_COUNT = 1;

	/**
	 * A constant with a fixed name that can be used as the base value for additional hand written constants in a derived class.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected static final int DIAGNOSTIC_CODE_COUNT = GENERATED_DIAGNOSTIC_CODE_COUNT;

	/**
	 * Creates an instance of the switch.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public BankValidator() {
		super();
	}

	/**
	 * Returns the package of this validator switch.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EPackage getEPackage() {
		return BankPackage.eINSTANCE;
	}

	/**
	 * Calls <code>validateXXX</code> for the corresponding classifier of the model.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected boolean validate(int classifierID, Object value, DiagnosticChain diagnostics, Map<Object, Object> context) {
		switch (classifierID) {
			case BankPackage.ACCOUNT:
				return validateAccount((Account)value, diagnostics, context);
			case BankPackage.SAVINGS_ACCOUNT:
				return validateSavingsAccount((SavingsAccount)value, diagnostics, context);
			case BankPackage.BRANCH:
				return validateBranch((Branch)value, diagnostics, context);
			case BankPackage.PERCENTAGE:
				return validatePercentage((Integer)value, diagnostics, context);
			case BankPackage.BSB:
				return validateBsb((String)value, diagnostics, context);
			case BankPackage.CURRENCY:
				return validateCurrency((String)value, diagnostics, context);
			case BankPackage.MONEY:
				return validateMoney((BigDecimal)value, diagnostics, context);
			default:
				return true;
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateAccount(Account account, DiagnosticChain diagnostics, Map<Object, Object> context) {
		if (!validate_NoCircularContainment(account, diagnostics, context)) return false;
		boolean result = validate_EveryMultiplicityConforms(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryDataValueConforms(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryReferenceIsContained(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryBidirectionalReferenceIsPaired(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryProxyResolves(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_UniqueID(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryKeyUnique(account, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryMapEntryUnique(account, diagnostics, context);
		if (result || diagnostics != null) result &= validateAccount_PositiveBalance(account, diagnostics, context);
		if (result || diagnostics != null) result &= validateAccount_Described(account, diagnostics, context);
		if (result || diagnostics != null) result &= validateAccount_hasOwner(account, diagnostics, context);
		return result;
	}

	/**
	 * Validates the PositiveBalance constraint of '<em>Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateAccount_PositiveBalance(Account account, DiagnosticChain diagnostics, Map<Object, Object> context) {
		// TODO implement the constraint
		// -> specify the condition that violates the constraint
		// -> verify the diagnostic details, including severity, code, and message
		// Ensure that you remove @generated or mark it @generated NOT
		if (false) {
			if (diagnostics != null) {
				diagnostics.add
					(createDiagnostic
						(Diagnostic.ERROR,
						 DIAGNOSTIC_SOURCE,
						 0,
						 "_UI_GenericConstraint_diagnostic",
						 new Object[] { "PositiveBalance", getObjectLabel(account, context) },
						 new Object[] { account },
						 context));
			}
			return false;
		}
		return true;
	}

	/**
	 * The cached validation expression for the Described constraint of '<em>Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected static final String ACCOUNT__DESCRIBED__EEXPRESSION = "self.description <> null\n" +
				"and self.description.size() > 0";

	/**
	 * Validates the Described constraint of '<em>Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateAccount_Described(Account account, DiagnosticChain diagnostics, Map<Object, Object> context) {
		return
			validate
				(BankPackage.Literals.ACCOUNT,
				 account,
				 diagnostics,
				 context,
				 "http://example.org/delegate",
				 "Described",
				 ACCOUNT__DESCRIBED__EEXPRESSION,
				 Diagnostic.ERROR,
				 DIAGNOSTIC_SOURCE,
				 0);
	}

	/**
	 * Validates the hasOwner constraint of '<em>Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateAccount_hasOwner(Account account, DiagnosticChain diagnostics, Map<Object, Object> context) {
		return account.hasOwner(diagnostics, context);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateSavingsAccount(SavingsAccount savingsAccount, DiagnosticChain diagnostics, Map<Object, Object> context) {
		if (!validate_NoCircularContainment(savingsAccount, diagnostics, context)) return false;
		boolean result = validate_EveryMultiplicityConforms(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryDataValueConforms(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryReferenceIsContained(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryBidirectionalReferenceIsPaired(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryProxyResolves(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_UniqueID(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryKeyUnique(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validate_EveryMapEntryUnique(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validateSavingsAccount_PositiveBalance(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validateAccount_Described(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validateAccount_hasOwner(savingsAccount, diagnostics, context);
		if (result || diagnostics != null) result &= validateSavingsAccount_MinimumDeposit(savingsAccount, diagnostics, context);
		return result;
	}

	/**
	 * Validates the PositiveBalance constraint of '<em>Savings Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateSavingsAccount_PositiveBalance(SavingsAccount savingsAccount, DiagnosticChain diagnostics, Map<Object, Object> context) {
		// TODO override the constraint, if desired
		// -> uncomment the scaffolding
		// -> specify the condition that violates the constraint
		// -> verify the diagnostic details, including severity, code, and message
		// Ensure that you remove @generated or mark it @generated NOT
		if (false) {
			if (diagnostics != null) {
				diagnostics.add
					(createDiagnostic
						(Diagnostic.ERROR,
						 DIAGNOSTIC_SOURCE,
						 0,
						 "_UI_GenericConstraint_diagnostic",
						 new Object[] { "PositiveBalance", getObjectLabel(savingsAccount, context) },
						 new Object[] { savingsAccount },
						 context));
			}
			return false;
		}
		return validateAccount_PositiveBalance(savingsAccount, diagnostics, context);
	}

	/**
	 * Validates the MinimumDeposit constraint of '<em>Savings Account</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateSavingsAccount_MinimumDeposit(SavingsAccount savingsAccount, DiagnosticChain diagnostics, Map<Object, Object> context) {
		// TODO implement the constraint
		// -> specify the condition that violates the constraint
		// -> verify the diagnostic details, including severity, code, and message
		// Ensure that you remove @generated or mark it @generated NOT
		if (false) {
			if (diagnostics != null) {
				diagnostics.add
					(createDiagnostic
						(Diagnostic.ERROR,
						 DIAGNOSTIC_SOURCE,
						 0,
						 "_UI_GenericConstraint_diagnostic",
						 new Object[] { "MinimumDeposit", getObjectLabel(savingsAccount, context) },
						 new Object[] { savingsAccount },
						 context));
			}
			return false;
		}
		return true;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateBranch(Branch branch, DiagnosticChain diagnostics, Map<Object, Object> context) {
		return validate_EveryDefaultConstraint(branch, diagnostics, context);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validatePercentage(int percentage, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = validatePercentage_Min(percentage, diagnostics, context);
		if (result || diagnostics != null) result &= validatePercentage_Max(percentage, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validatePercentage_Min
	 */
	public static final int PERCENTAGE__MIN__VALUE = 0;

	/**
	 * Validates the Min constraint of '<em>Percentage</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validatePercentage_Min(int percentage, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = percentage >= PERCENTAGE__MIN__VALUE;
		if (!result && diagnostics != null)
			reportMinViolation(BankPackage.Literals.PERCENTAGE, percentage, PERCENTAGE__MIN__VALUE, true, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validatePercentage_Max
	 */
	public static final int PERCENTAGE__MAX__VALUE = 101;

	/**
	 * Validates the Max constraint of '<em>Percentage</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validatePercentage_Max(int percentage, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = percentage < PERCENTAGE__MAX__VALUE;
		if (!result && diagnostics != null)
			reportMaxViolation(BankPackage.Literals.PERCENTAGE, percentage, PERCENTAGE__MAX__VALUE, false, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateBsb(String bsb, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = validateBsb_Pattern(bsb, diagnostics, context);
		if (result || diagnostics != null) result &= validateBsb_MinLength(bsb, diagnostics, context);
		if (result || diagnostics != null) result &= validateBsb_MaxLength(bsb, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validateBsb_Pattern
	 */
	public static final  PatternMatcher [][] BSB__PATTERN__VALUES =
		new PatternMatcher [][] {
			new PatternMatcher [] {
				XMLTypeUtil.createPatternMatcher("[0-9]{3}-[0-9]{3}")
			}
		};

	/**
	 * Validates the Pattern constraint of '<em>Bsb</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateBsb_Pattern(String bsb, DiagnosticChain diagnostics, Map<Object, Object> context) {
		return validatePattern(BankPackage.Literals.BSB, bsb, BSB__PATTERN__VALUES, diagnostics, context);
	}

	/**
	 * Validates the MinLength constraint of '<em>Bsb</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateBsb_MinLength(String bsb, DiagnosticChain diagnostics, Map<Object, Object> context) {
		int length = bsb.length();
		boolean result = length >= 7;
		if (!result && diagnostics != null)
			reportMinLengthViolation(BankPackage.Literals.BSB, bsb, length, 7, diagnostics, context);
		return result;
	}

	/**
	 * Validates the MaxLength constraint of '<em>Bsb</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateBsb_MaxLength(String bsb, DiagnosticChain diagnostics, Map<Object, Object> context) {
		int length = bsb.length();
		boolean result = length <= 7;
		if (!result && diagnostics != null)
			reportMaxLengthViolation(BankPackage.Literals.BSB, bsb, length, 7, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateCurrency(String currency, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = validateCurrency_Enumeration(currency, diagnostics, context);
		if (result || diagnostics != null) result &= validateCurrency_MinLength(currency, diagnostics, context);
		if (result || diagnostics != null) result &= validateCurrency_MaxLength(currency, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validateCurrency_Enumeration
	 */
	public static final Collection<Object> CURRENCY__ENUMERATION__VALUES =
		wrapEnumerationValues
			(new Object[] {
				 "AUD",
				 "NZD",
				 "USD"
			 });

	/**
	 * Validates the Enumeration constraint of '<em>Currency</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateCurrency_Enumeration(String currency, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = CURRENCY__ENUMERATION__VALUES.contains(currency);
		if (!result && diagnostics != null)
			reportEnumerationViolation(BankPackage.Literals.CURRENCY, currency, CURRENCY__ENUMERATION__VALUES, diagnostics, context);
		return result;
	}

	/**
	 * Validates the MinLength constraint of '<em>Currency</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateCurrency_MinLength(String currency, DiagnosticChain diagnostics, Map<Object, Object> context) {
		int length = currency.length();
		boolean result = length >= 3;
		if (!result && diagnostics != null)
			reportMinLengthViolation(BankPackage.Literals.CURRENCY, currency, length, 3, diagnostics, context);
		return result;
	}

	/**
	 * Validates the MaxLength constraint of '<em>Currency</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateCurrency_MaxLength(String currency, DiagnosticChain diagnostics, Map<Object, Object> context) {
		int length = currency.length();
		boolean result = length <= 3;
		if (!result && diagnostics != null)
			reportMaxLengthViolation(BankPackage.Literals.CURRENCY, currency, length, 3, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateMoney(BigDecimal money, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = validateMoney_NotRounded(money, diagnostics, context);
		if (result || diagnostics != null) result &= validateMoney_TotalDigits(money, diagnostics, context);
		if (result || diagnostics != null) result &= validateMoney_FractionDigits(money, diagnostics, context);
		if (result || diagnostics != null) result &= validateMoney_Min(money, diagnostics, context);
		return result;
	}

	/**
	 * Validates the NotRounded constraint of '<em>Money</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateMoney_NotRounded(BigDecimal money, DiagnosticChain diagnostics, Map<Object, Object> context) {
		// TODO implement the constraint
		// -> specify the condition that violates the constraint
		// -> verify the diagnostic details, including severity, code, and message
		// Ensure that you remove @generated or mark it @generated NOT
		if (false) {
			if (diagnostics != null) {
				diagnostics.add
					(createDiagnostic
						(Diagnostic.ERROR,
						 DIAGNOSTIC_SOURCE,
						 0,
						 "_UI_GenericConstraint_diagnostic",
						 new Object[] { "NotRounded", getValueLabel(BankPackage.Literals.MONEY, money, context) },
						 new Object[] { money },
						 context));
			}
			return false;
		}
		return true;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validateMoney_TotalDigits
	 */
	public static final BigDecimal MONEY__TOTAL_DIGITS__UPPER_BOUND = new BigDecimal("1000000000000");

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validateMoney_TotalDigits
	 */
	public static final BigDecimal MONEY__TOTAL_DIGITS__LOWER_BOUND = new BigDecimal("-1000000000000");

	/**
	 * Validates the TotalDigits constraint of '<em>Money</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateMoney_TotalDigits(BigDecimal money, DiagnosticChain diagnostics, Map<Object, Object> context) {
		int scale = money.scale();
		int totalDigits = scale < 0 ? money.precision() - scale : money.precision();
		boolean result = totalDigits <= 12;
		if (!result && diagnostics != null)
			reportTotalDigitsViolation(BankPackage.Literals.MONEY, money, 12, diagnostics, context);
		return result;
	}

	/**
	 * Validates the FractionDigits constraint of '<em>Money</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateMoney_FractionDigits(BigDecimal money, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = money.scale() <= 2;
		if (!result && diagnostics != null)
			reportFractionDigitsViolation(BankPackage.Literals.MONEY, money, 2, diagnostics, context);
		return result;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 * @see #validateMoney_Min
	 */
	public static final BigDecimal MONEY__MIN__VALUE = new BigDecimal("0.00");

	/**
	 * Validates the Min constraint of '<em>Money</em>'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public boolean validateMoney_Min(BigDecimal money, DiagnosticChain diagnostics, Map<Object, Object> context) {
		boolean result = money.compareTo(MONEY__MIN__VALUE) >= 0;
		if (!result && diagnostics != null)
			reportMinViolation(BankPackage.Literals.MONEY, money, MONEY__MIN__VALUE, true, diagnostics, context);
		return result;
	}

	/**
	 * Returns the resource locator that will be used to fetch messages for this validator's diagnostics.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public ResourceLocator getResourceLocator() {
		// TODO
		// Specialize this to return a resource locator for messages specific to this validator.
		// Ensure that you remove @generated or mark it @generated NOT
		return super.getResourceLocator();
	}

} //BankValidator
