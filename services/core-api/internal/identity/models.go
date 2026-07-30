package identity

import "time"

// PatientStats backs the patient detail panel's chart/rewards section.
type PatientStats struct {
	LoyaltyPoints   int                  `json:"loyaltyPoints"`
	TotalSpent      float64              `json:"totalSpent"`
	VisitsCount     int64                `json:"visitsCount"`
	MonthlySpending []MonthlySpendingRow `json:"monthlySpending"`
}

type MonthlySpendingRow struct {
	Period string  `json:"period"`
	Amount float64 `json:"amount"`
}

type Patient struct {
	ID          string     `json:"id"`
	FullName    string     `json:"fullName"`
	RMNumber    *string    `json:"rmNumber"`
	Relation    string     `json:"relation"`
	Gender      *string    `json:"gender"`
	DateOfBirth *time.Time `json:"dateOfBirth"`
	PhoneWA     *string    `json:"phoneWa"`
	Email       *string    `json:"email"`
	City        *string    `json:"city"`
	Address     *string    `json:"address"`
	PhotoURL    *string    `json:"photoUrl"`
	CreatedAt   time.Time  `json:"createdAt"`
}
