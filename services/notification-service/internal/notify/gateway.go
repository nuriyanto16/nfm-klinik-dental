package notify

import "context"

// WhatsAppGateway abstracts a 3rd-party WA gateway (Fonnte/Wablas/Qontak).
// Only one implementation is wired up at a time — chosen based on
// price/reliability when the clinic signs up with a provider — so this
// package never depends on a specific vendor SDK.
type WhatsAppGateway interface {
	SendText(ctx context.Context, phoneE164 string, message string) error
}

// PushGateway abstracts Firebase Cloud Messaging.
type PushGateway interface {
	SendToDevice(ctx context.Context, deviceToken string, title, body string, data map[string]string) error
}

// EmailGateway abstracts outbound SMTP email (used for staff-facing
// notifications, e.g. daily reports).
type EmailGateway interface {
	Send(ctx context.Context, toEmail, subject, body string) error
}

// Channel identifies which gateway a notification_templates row targets.
type Channel string

const (
	ChannelWhatsApp Channel = "wa"
	ChannelPush     Channel = "push"
	ChannelEmail    Channel = "email"
)
