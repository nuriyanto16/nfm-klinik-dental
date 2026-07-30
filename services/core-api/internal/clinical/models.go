package clinical

import "time"

// MedicalRecord is append-only — a clinical encounter, once written, is
// never edited. Corrections are a new record referencing the same patient.
type MedicalRecord struct {
	ID             string    `json:"id"`
	PatientID      string    `json:"patientId"`
	PatientName    string    `json:"patientName"`
	ReservationID  *string   `json:"reservationId"`
	StaffID        string    `json:"staffId"`
	DoctorName     string    `json:"doctorName"`
	Diagnosis      *string   `json:"diagnosis"`
	TreatmentNotes *string   `json:"treatmentNotes"`
	CreatedAt      time.Time `json:"createdAt"`
}

type OdontogramEntry struct {
	ID          string  `json:"id"`
	ToothNumber int     `json:"toothNumber"`
	Condition   string  `json:"condition"`
	Notes       *string `json:"notes"`
}

type ItemUsage struct {
	ID              string  `json:"id"`
	InventoryItemID string  `json:"inventoryItemId"`
	ItemName        string  `json:"itemName"`
	Category        string  `json:"category"`
	Unit            string  `json:"unit"`
	Quantity        float64 `json:"quantity"`
	Notes           *string `json:"notes"`
}

type MedicalRecordDetail struct {
	MedicalRecord
	Odontogram []OdontogramEntry `json:"odontogram"`
	ItemsUsed  []ItemUsage       `json:"itemsUsed"`
}

type OdontogramEntryInput struct {
	ToothNumber int     `json:"toothNumber"`
	Condition   string  `json:"condition"`
	Notes       *string `json:"notes"`
}

type ItemUsageInput struct {
	InventoryItemID string  `json:"inventoryItemId"`
	Quantity        float64 `json:"quantity"`
	Notes           *string `json:"notes"`
}

type CreateMedicalRecordInput struct {
	PatientID      string                 `json:"patientId"`
	ReservationID  *string                `json:"reservationId"`
	StaffID        string                 `json:"staffId"`
	Diagnosis      *string                `json:"diagnosis"`
	TreatmentNotes *string                `json:"treatmentNotes"`
	Odontogram     []OdontogramEntryInput `json:"odontogram"`
	ItemsUsed      []ItemUsageInput       `json:"itemsUsed"`
}
