package content

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
)

func (r *Repository) ListNotificationTemplates(ctx context.Context) ([]NotificationTemplate, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, code, channel, subject, body, updated_at
		FROM content.notification_templates ORDER BY code`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	templates := []NotificationTemplate{}
	for rows.Next() {
		var t NotificationTemplate
		if err := rows.Scan(&t.ID, &t.Code, &t.Channel, &t.Subject, &t.Body, &t.UpdatedAt); err != nil {
			return nil, err
		}
		templates = append(templates, t)
	}
	return templates, rows.Err()
}

func (r *Repository) CreateNotificationTemplate(ctx context.Context, in NotificationTemplateInput) (NotificationTemplate, error) {
	var t NotificationTemplate
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.notification_templates (code, channel, subject, body)
		VALUES ($1, $2, $3, $4)
		RETURNING id, code, channel, subject, body, updated_at`,
		in.Code, in.Channel, in.Subject, in.Body,
	).Scan(&t.ID, &t.Code, &t.Channel, &t.Subject, &t.Body, &t.UpdatedAt)
	return t, err
}

func (r *Repository) UpdateNotificationTemplate(ctx context.Context, id string, in NotificationTemplateInput) (NotificationTemplate, error) {
	var t NotificationTemplate
	err := r.pool.QueryRow(ctx, `
		UPDATE content.notification_templates
		SET code = $1, channel = $2, subject = $3, body = $4, updated_at = now()
		WHERE id = $5
		RETURNING id, code, channel, subject, body, updated_at`,
		in.Code, in.Channel, in.Subject, in.Body, id,
	).Scan(&t.ID, &t.Code, &t.Channel, &t.Subject, &t.Body, &t.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return t, dberr.ErrNotFound
	}
	return t, err
}

func (r *Repository) DeleteNotificationTemplate(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM content.notification_templates WHERE id = $1`, id)
	return err
}

func (r *Repository) ListNotificationLogs(ctx context.Context) ([]NotificationLog, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, template_code, channel, recipient, status, error_message, sent_at
		FROM content.notification_logs ORDER BY sent_at DESC LIMIT 200`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	logs := []NotificationLog{}
	for rows.Next() {
		var l NotificationLog
		if err := rows.Scan(&l.ID, &l.TemplateCode, &l.Channel, &l.Recipient, &l.Status, &l.ErrorMessage, &l.SentAt); err != nil {
			return nil, err
		}
		logs = append(logs, l)
	}
	return logs, rows.Err()
}

var ErrTemplateNotFound = errors.New("notification template not found")

// SendNotification is a stand-in for the real WA/push/email gateway call
// (Fase 2, pending 3rd-party provider selection — see
// docs/architecture.md §7): it logs the send as successful immediately so
// the broadcast UI and log viewer are fully usable ahead of that
// integration, without pretending to call an external API that isn't wired
// up yet.
func (r *Repository) SendNotification(ctx context.Context, in SendNotificationInput) (NotificationLog, error) {
	var channel string
	if err := r.pool.QueryRow(ctx, `
		SELECT channel FROM content.notification_templates WHERE code = $1`, in.TemplateCode,
	).Scan(&channel); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return NotificationLog{}, ErrTemplateNotFound
		}
		return NotificationLog{}, err
	}

	var l NotificationLog
	err := r.pool.QueryRow(ctx, `
		INSERT INTO content.notification_logs (template_code, channel, recipient, status)
		VALUES ($1, $2, $3, 'sent')
		RETURNING id, template_code, channel, recipient, status, error_message, sent_at`,
		in.TemplateCode, channel, in.Recipient,
	).Scan(&l.ID, &l.TemplateCode, &l.Channel, &l.Recipient, &l.Status, &l.ErrorMessage, &l.SentAt)
	return l, err
}
