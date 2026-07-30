package identity

import "time"

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
	CreatedAt   time.Time  `json:"createdAt"`
}
