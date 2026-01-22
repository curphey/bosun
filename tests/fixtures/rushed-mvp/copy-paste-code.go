// Payment processing - copied validation logic everywhere
// "I'll refactor it later" - narrator: they did not refactor it later

package payments

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

type CreditCard struct {
	Number     string
	Expiry     string
	CVV        string
	HolderName string
}

type BankAccount struct {
	AccountNumber string
	RoutingNumber string
	AccountName   string
}

type PayPalAccount struct {
	Email string
}

// Process credit card - has validation logic
func ProcessCreditCard(card CreditCard, amount float64) error {
	// Validate card number (copied to 3 places)
	cardNum := strings.ReplaceAll(card.Number, " ", "")
	cardNum = strings.ReplaceAll(cardNum, "-", "")
	if len(cardNum) < 13 || len(cardNum) > 19 {
		return fmt.Errorf("invalid card number length")
	}
	matched, _ := regexp.MatchString(`^\d+$`, cardNum)
	if !matched {
		return fmt.Errorf("card number must contain only digits")
	}

	// Validate expiry (copied to 3 places)
	parts := strings.Split(card.Expiry, "/")
	if len(parts) != 2 {
		return fmt.Errorf("invalid expiry format")
	}
	month := parts[0]
	year := parts[1]
	if len(month) != 2 || len(year) != 2 {
		return fmt.Errorf("expiry must be MM/YY format")
	}

	// Validate CVV (copied to 2 places)
	if len(card.CVV) < 3 || len(card.CVV) > 4 {
		return fmt.Errorf("invalid CVV length")
	}
	cvvMatched, _ := regexp.MatchString(`^\d+$`, card.CVV)
	if !cvvMatched {
		return fmt.Errorf("CVV must contain only digits")
	}

	// Validate amount (copied to 4 places)
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	if amount > 10000 {
		return fmt.Errorf("amount exceeds maximum")
	}

	// Process payment...
	fmt.Printf("Processing credit card payment: $%.2f\n", amount)
	return nil
}

// Refund to credit card - same validation, copied
func RefundCreditCard(card CreditCard, amount float64) error {
	// Validate card number (COPIED)
	cardNum := strings.ReplaceAll(card.Number, " ", "")
	cardNum = strings.ReplaceAll(cardNum, "-", "")
	if len(cardNum) < 13 || len(cardNum) > 19 {
		return fmt.Errorf("invalid card number length")
	}
	matched, _ := regexp.MatchString(`^\d+$`, cardNum)
	if !matched {
		return fmt.Errorf("card number must contain only digits")
	}

	// Validate expiry (COPIED)
	parts := strings.Split(card.Expiry, "/")
	if len(parts) != 2 {
		return fmt.Errorf("invalid expiry format")
	}
	month := parts[0]
	year := parts[1]
	if len(month) != 2 || len(year) != 2 {
		return fmt.Errorf("expiry must be MM/YY format")
	}

	// Validate amount (COPIED)
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	if amount > 10000 {
		return fmt.Errorf("amount exceeds maximum")
	}

	// Process refund...
	fmt.Printf("Processing credit card refund: $%.2f\n", amount)
	return nil
}

// Validate card for storage - same validation AGAIN
func ValidateCreditCardForStorage(card CreditCard) error {
	// Validate card number (COPIED THIRD TIME)
	cardNum := strings.ReplaceAll(card.Number, " ", "")
	cardNum = strings.ReplaceAll(cardNum, "-", "")
	if len(cardNum) < 13 || len(cardNum) > 19 {
		return fmt.Errorf("invalid card number length")
	}
	matched, _ := regexp.MatchString(`^\d+$`, cardNum)
	if !matched {
		return fmt.Errorf("card number must contain only digits")
	}

	// Validate expiry (COPIED THIRD TIME)
	parts := strings.Split(card.Expiry, "/")
	if len(parts) != 2 {
		return fmt.Errorf("invalid expiry format")
	}
	month := parts[0]
	year := parts[1]
	if len(month) != 2 || len(year) != 2 {
		return fmt.Errorf("expiry must be MM/YY format")
	}

	// Validate CVV (COPIED)
	if len(card.CVV) < 3 || len(card.CVV) > 4 {
		return fmt.Errorf("invalid CVV length")
	}
	cvvMatched, _ := regexp.MatchString(`^\d+$`, card.CVV)
	if !cvvMatched {
		return fmt.Errorf("CVV must contain only digits")
	}

	return nil
}

// Bank transfer - same amount validation copied
func ProcessBankTransfer(account BankAccount, amount float64) error {
	// Validate amount (COPIED AGAIN)
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	if amount > 10000 {
		return fmt.Errorf("amount exceeds maximum")
	}

	// Process transfer...
	fmt.Printf("Processing bank transfer: $%.2f\n", amount)
	return nil
}

// PayPal - and again
func ProcessPayPal(account PayPalAccount, amount float64) error {
	// Validate amount (COPIED YET AGAIN)
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}
	if amount > 10000 {
		return fmt.Errorf("amount exceeds maximum")
	}

	// Process PayPal...
	fmt.Printf("Processing PayPal payment: $%.2f\n", amount)
	return nil
}

// Magic numbers everywhere - what do these mean?
func CalculateFees(amount float64, paymentType string) float64 {
	switch paymentType {
	case "credit":
		return amount * 0.029 + 0.30  // What are these numbers?
	case "debit":
		return amount * 0.015 + 0.25  // Why different?
	case "bank":
		return 0.25                    // Fixed fee? Why?
	case "paypal":
		return amount * 0.034 + 0.49  // PayPal rate? When did this change?
	default:
		return amount * 0.05          // Default fee? Says who?
	}
}

// Timeout values scattered - should be config
func ProcessWithRetry(fn func() error) error {
	maxRetries := 3           // Magic number
	timeout := 30 * time.Second  // Magic timeout

	for i := 0; i < maxRetries; i++ {
		// ... retry logic
		_ = timeout
	}
	return fn()
}
