package scheduling

import "time"

type Branch struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Slug     string  `json:"slug"`
	Address  string  `json:"address"`
	City     string  `json:"city"`
	Phone    *string `json:"phone"`
	OpensAt  string  `json:"opensAt"`
	ClosesAt string  `json:"closesAt"`
	IsActive bool    `json:"isActive"`
}

type Doctor struct {
	ID             string  `json:"id"`
	FullName       string  `json:"fullName"`
	Specialization *string `json:"specialization"`
	PhotoURL       *string `json:"photoUrl"`
}

type DoctorSchedule struct {
	DayOfWeek           int    `json:"dayOfWeek"`
	BranchID            string `json:"branchId"`
	StartTime           string `json:"startTime"`
	EndTime             string `json:"endTime"`
	SlotDurationMinutes int    `json:"slotDurationMinutes"`
}

type DoctorDetail struct {
	Doctor
	Email     *string          `json:"email"`
	PhoneWA   *string          `json:"phoneWa"`
	IsActive  bool             `json:"isActive"`
	BranchIDs []string         `json:"branchIds"`
	Schedules []DoctorSchedule `json:"schedules"`
}

type CreateDoctorInput struct {
	FullName       string           `json:"fullName"`
	Email          string           `json:"email"`
	PhoneWA        *string          `json:"phoneWa"`
	Specialization *string          `json:"specialization"`
	BranchIDs      []string         `json:"branchIds"`
	Schedules      []DoctorSchedule `json:"schedules"`
}

type UpdateDoctorInput struct {
	FullName       string           `json:"fullName"`
	Specialization *string          `json:"specialization"`
	IsActive       bool             `json:"isActive"`
	BranchIDs      []string         `json:"branchIds"`
	Schedules      []DoctorSchedule `json:"schedules"`
}

type Reservation struct {
	ID            string    `json:"id"`
	PatientID     string    `json:"patientId"`
	BranchID      string    `json:"branchId"`
	StaffID       string    `json:"staffId"`
	ScheduledAt   time.Time `json:"scheduledAt"`
	Status        string    `json:"status"`
	ComplaintNote *string   `json:"complaintNote"`
	PatientName   string    `json:"patientName"`
	BranchName    string    `json:"branchName"`
	DoctorName    string    `json:"doctorName"`
	Treatments    string    `json:"treatments"`
}

// ReservationFilter narrows ListReservations — every field is optional,
// applied only when non-empty/non-nil.
type ReservationFilter struct {
	BranchID  string
	Status    string
	From      string // YYYY-MM-DD
	To        string // YYYY-MM-DD
	PatientID string
}

type CreateReservationInput struct {
	PatientID     string    `json:"patientId"`
	BranchID      string    `json:"branchId"`
	StaffID       string    `json:"staffId"`
	ScheduledAt   time.Time `json:"scheduledAt"`
	ComplaintNote *string   `json:"complaintNote"`
	TreatmentIDs  []string  `json:"treatmentIds"`
	// Status defaults to "pending" (the normal booking flow). A POS/walk-in
	// checkout that serves and bills the patient in the same step passes
	// "completed" directly instead of booking-then-transitioning.
	Status string `json:"status"`
}

// ReservationStatuses in the lifecycle order the admin UI offers as the
// "next step" — cancelled/no_show are reachable from most earlier states
// too, offered separately in the UI rather than baked into this sequence.
var ReservationStatuses = []string{"pending", "confirmed", "checked_in", "in_progress", "completed", "cancelled", "no_show"}

type UpdateReservationStatusInput struct {
	Status string `json:"status"`
}
