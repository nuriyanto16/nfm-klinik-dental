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
	Points      int        `json:"points"`
	CreatedAt   time.Time  `json:"createdAt"`
}

type PointSettings struct {
	ID                   int       `json:"id"`
	PointsPerReservation int       `json:"pointsPerReservation"`
	PointsPerSpendIDR    float64   `json:"pointsPerSpendIdr"`
	PointsEarnedPerSpend int       `json:"pointsEarnedPerSpend"`
	RupiahPerPoint       float64   `json:"rupiahPerPoint"`
	MinRedeemPoints      int       `json:"minRedeemPoints"`
	UpdatedAt            time.Time `json:"updatedAt"`
}

type PointTransaction struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Type        string    `json:"type"` // earn, redeem, adjustment, bonus
	Points      int       `json:"points"`
	Description string    `json:"description"`
	ReferenceID *string   `json:"referenceId"`
	CreatedAt   time.Time `json:"createdAt"`
}

type UserPointsData struct {
	PointsBalance int                `json:"pointsBalance"`
	RupiahValue   float64            `json:"rupiahValue"`
	Transactions  []PointTransaction `json:"transactions"`
}

