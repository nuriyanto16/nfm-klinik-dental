package settings

import "time"

type AppSetting struct {
	ID          string    `json:"id" db:"id"`
	KeyName     string    `json:"keyName" db:"key_name"`
	ValueData   string    `json:"valueData" db:"value_data"`
	Description string    `json:"description" db:"description"`
	UpdatedAt   time.Time `json:"updatedAt" db:"updated_at"`
}

type UpdateSettingInput struct {
	ValueData string `json:"valueData"`
}
