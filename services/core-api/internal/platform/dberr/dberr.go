// Package dberr centralizes the handful of Postgres error checks every
// domain repository needs (does this row exist, would deleting it violate a
// foreign key) so each domain doesn't reimplement pgconn error-code
// sniffing.
package dberr

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

var ErrNotFound = errors.New("not found")

// IsForeignKeyViolation reports whether err is a Postgres FK constraint
// violation (SQLSTATE 23503) — the standard signal that a row can't be
// deleted because other rows still reference it.
func IsForeignKeyViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23503"
}

// IsUniqueViolation reports whether err is a Postgres unique constraint
// violation (SQLSTATE 23505) — e.g. a duplicate email/phone on insert.
func IsUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
