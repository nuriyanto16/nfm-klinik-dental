package clinical

import "time"

// MedicalRecord is append-only — a clinical encounter, once written, is
// never edited. Corrections are a new record referencing the same patient.
type MedicalRecord struct {
	ID                    string    `json:"id"`
	PatientID             string    `json:"patientId"`
	PatientName           string    `json:"patientName"`
	ReservationID         *string   `json:"reservationId"`
	StaffID               string    `json:"staffId"`
	DoctorName            string    `json:"doctorName"`
	Diagnosis             *string   `json:"diagnosis"`
	TreatmentNotes        *string   `json:"treatmentNotes"`
	NIK                   *string   `json:"nik"`
	Occupation            *string   `json:"occupation"`
	EmergencyContact      *string   `json:"emergencyContact"`
	ChiefComplaint        *string   `json:"chiefComplaint"`
	PresentIllnessHistory *string   `json:"presentIllnessHistory"`
	HasHypertension       bool      `json:"hasHypertension"`
	HasHeartDisease       bool      `json:"hasHeartDisease"`
	HasDiabetes           bool      `json:"hasDiabetes"`
	HasHepatitis          bool      `json:"hasHepatitis"`
	HasHiv                bool      `json:"hasHiv"`
	HasBleedingDisorder   bool      `json:"hasBleedingDisorder"`
	DrugAllergies         *string   `json:"drugAllergies"`
	FoodAllergies         *string   `json:"foodAllergies"`
	IsPregnant            bool      `json:"isPregnant"`
	RoutineMedications    *string   `json:"routineMedications"`
	VitalBloodPressure    *string   `json:"vitalBloodPressure"`
	VitalPulse            *string   `json:"vitalPulse"`
	VitalTemperature      *string   `json:"vitalTemperature"`
	ExtraOralExam         *string   `json:"extraOralExam"`
	ToothNumber           *string   `json:"toothNumber"`
	SoapS                 *string   `json:"soapS"`
	SoapO                 *string   `json:"soapO"`
	SoapP                 *string   `json:"soapP"`
	Prescription          *string   `json:"prescription"`
	CreatedAt             time.Time `json:"createdAt"`
}

type OdontogramEntry struct {
	ID          string  `json:"id"`
	ToothNumber int     `json:"toothNumber"`
	Condition   string  `json:"condition"`
	Notes       *string `json:"notes"`
	PhotoURL    *string `json:"photoUrl"`
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
	PhotoURL    *string `json:"photoUrl"`
}

// PatientOdontogramTimeline is one medical record's worth of odontogram
// photos, ordered oldest-first, so the patient panel can show a
// before/after comparison (e.g. braces progression) across visits.
type PatientOdontogramTimeline struct {
	MedicalRecordID string            `json:"medicalRecordId"`
	CreatedAt       time.Time         `json:"createdAt"`
	Odontogram      []OdontogramEntry `json:"odontogram"`
}

type ItemUsageInput struct {
	InventoryItemID string  `json:"inventoryItemId"`
	Quantity        float64 `json:"quantity"`
	Notes           *string `json:"notes"`
}

type CreateMedicalRecordInput struct {
	PatientID             string                 `json:"patientId"`
	ReservationID         *string                `json:"reservationId"`
	StaffID               string                 `json:"staffId"`
	Diagnosis             *string                `json:"diagnosis"`
	TreatmentNotes        *string                `json:"treatmentNotes"`
	NIK                   *string                `json:"nik"`
	Occupation            *string                `json:"occupation"`
	EmergencyContact      *string                `json:"emergencyContact"`
	ChiefComplaint        *string                `json:"chiefComplaint"`
	PresentIllnessHistory *string                `json:"presentIllnessHistory"`
	HasHypertension       bool                   `json:"hasHypertension"`
	HasHeartDisease       bool                   `json:"hasHeartDisease"`
	HasDiabetes           bool                   `json:"hasDiabetes"`
	HasHepatitis          bool                   `json:"hasHepatitis"`
	HasHiv                bool                   `json:"hasHiv"`
	HasBleedingDisorder   bool                   `json:"hasBleedingDisorder"`
	DrugAllergies         *string                `json:"drugAllergies"`
	FoodAllergies         *string                `json:"foodAllergies"`
	IsPregnant            bool                   `json:"isPregnant"`
	RoutineMedications    *string                `json:"routineMedications"`
	VitalBloodPressure    *string                `json:"vitalBloodPressure"`
	VitalPulse            *string                `json:"vitalPulse"`
	VitalTemperature      *string                `json:"vitalTemperature"`
	ExtraOralExam         *string                `json:"extraOralExam"`
	ToothNumber           *string                `json:"toothNumber"`
	SoapS                 *string                `json:"soapS"`
	SoapO                 *string                `json:"soapO"`
	SoapP                 *string                `json:"soapP"`
	Prescription          *string                `json:"prescription"`
	Odontogram            []OdontogramEntryInput `json:"odontogram"`
	ItemsUsed             []ItemUsageInput       `json:"itemsUsed"`
}

type UpdateMedicalRecordInput struct {
	PatientID             string                 `json:"patientId"`
	ReservationID         *string                `json:"reservationId"`
	StaffID               string                 `json:"staffId"`
	Diagnosis             *string                `json:"diagnosis"`
	TreatmentNotes        *string                `json:"treatmentNotes"`
	NIK                   *string                `json:"nik"`
	Occupation            *string                `json:"occupation"`
	EmergencyContact      *string                `json:"emergencyContact"`
	ChiefComplaint        *string                `json:"chiefComplaint"`
	PresentIllnessHistory *string                `json:"presentIllnessHistory"`
	HasHypertension       bool                   `json:"hasHypertension"`
	HasHeartDisease       bool                   `json:"hasHeartDisease"`
	HasDiabetes           bool                   `json:"hasDiabetes"`
	HasHepatitis          bool                   `json:"hasHepatitis"`
	HasHiv                bool                   `json:"hasHiv"`
	HasBleedingDisorder   bool                   `json:"hasBleedingDisorder"`
	DrugAllergies         *string                `json:"drugAllergies"`
	FoodAllergies         *string                `json:"foodAllergies"`
	IsPregnant            bool                   `json:"isPregnant"`
	RoutineMedications    *string                `json:"routineMedications"`
	VitalBloodPressure    *string                `json:"vitalBloodPressure"`
	VitalPulse            *string                `json:"vitalPulse"`
	VitalTemperature      *string                `json:"vitalTemperature"`
	ExtraOralExam         *string                `json:"extraOralExam"`
	ToothNumber           *string                `json:"toothNumber"`
	SoapS                 *string                `json:"soapS"`
	SoapO                 *string                `json:"soapO"`
	SoapP                 *string                `json:"soapP"`
	Prescription          *string                `json:"prescription"`
	Odontogram            []OdontogramEntryInput `json:"odontogram"`
	ItemsUsed             []ItemUsageInput       `json:"itemsUsed"`
}

