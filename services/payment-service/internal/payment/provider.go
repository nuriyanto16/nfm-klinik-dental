package payment

import (
	"context"
	"time"
)

// CreateInvoiceInput is the provider-agnostic request core-api sends when a
// reservation needs to be paid for.
type CreateInvoiceInput struct {
	PaymentID       string
	ExternalRef     string // idempotency key, e.g. reservation ID
	Amount          float64
	PayerEmail      string
	PayerName       string
	Description     string
	ExpiresAt       time.Time
	SuccessRedirect string
	FailureRedirect string
}

// Invoice is the provider-agnostic result returned to core-api / the mobile
// app so it can render a checkout URL or VA/QRIS details.
type Invoice struct {
	ProviderReference string
	CheckoutURL       string
	Status            string
	ExpiresAt         time.Time
}

// Provider abstracts a payment gateway (Xendit today, Midtrans or others
// later) so the rest of payment-service never talks to a vendor SDK
// directly. Only one implementation exists right now (Xendit), added when
// the Xendit account/API key is available.
type Provider interface {
	CreateInvoice(ctx context.Context, in CreateInvoiceInput) (*Invoice, error)
	GetInvoice(ctx context.Context, providerReference string) (*Invoice, error)
	// VerifyWebhook checks the provider's signature/callback token on an
	// incoming webhook request and returns the normalized event payload.
	VerifyWebhook(headerToken string, rawBody []byte) (*WebhookEvent, error)
}

// WebhookEvent is the normalized shape of a provider callback, regardless of
// which gateway sent it.
type WebhookEvent struct {
	ProviderEventID   string
	ProviderReference string
	Status            string // paid, expired, failed
	PaidAt            *time.Time
}
