package billing

import "time"

type Treatment struct {
	ID              string  `json:"id"`
	Name            string  `json:"name"`
	CategoryName    string  `json:"categoryName"`
	Price           float64 `json:"price"`
	DurationMinutes int16   `json:"durationMinutes"`
	IsActive        bool    `json:"isActive"`
}

type Payment struct {
	ID                string     `json:"id"`
	ReservationID     string     `json:"reservationId"`
	PatientID         string     `json:"patientId"`
	Amount            float64    `json:"amount"`
	DepositAmount     float64    `json:"depositAmount"`
	Status            string     `json:"status"`
	Provider          string     `json:"provider"`
	ProviderReference *string    `json:"providerReference"`
	PaymentMethod     *string    `json:"paymentMethod"`
	PaidAt            *time.Time `json:"paidAt"`
	ExpiredAt         *time.Time `json:"expiredAt"`
	CreatedAt         time.Time  `json:"createdAt"`
	PatientName       string     `json:"patientName"`
	BranchName        string     `json:"branchName"`
}

type DashboardSummary struct {
	ReservationsToday int64   `json:"reservationsToday"`
	RevenueToday      float64 `json:"revenueToday"`
	ActiveQueue       int64   `json:"activeQueue"`
	AttendanceRate7d  float64 `json:"attendanceRate7d"`
	TotalPatients     int64   `json:"totalPatients"`
	RevenueThisMonth  float64 `json:"revenueThisMonth"`
}

type DailyRevenue struct {
	Date    string  `json:"date"`
	Revenue float64 `json:"revenue"`
}

type StatusCount struct {
	Status string `json:"status"`
	Count  int64  `json:"count"`
}

type BranchRevenue struct {
	BranchName       string  `json:"branchName"`
	Revenue          float64 `json:"revenue"`
	ReservationCount int64   `json:"reservationCount"`
}

type TreatmentCount struct {
	TreatmentName string `json:"treatmentName"`
	BookingCount  int64  `json:"bookingCount"`
}
