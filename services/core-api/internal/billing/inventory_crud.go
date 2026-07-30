package billing

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/nina-dental-care/core-api/internal/platform/dberr"
	"github.com/nina-dental-care/core-api/internal/platform/pagination"
)

type InventoryItem struct {
	ID               string  `json:"id"`
	Name             string  `json:"name"`
	Category         string  `json:"category"` // obat, alat
	Unit             string  `json:"unit"`
	StockQuantity    float64 `json:"stockQuantity"`
	UnitPrice        float64 `json:"unitPrice"`
	ReorderThreshold float64 `json:"reorderThreshold"`
	IsActive         bool    `json:"isActive"`
}

type InventoryItemInput struct {
	Name             string  `json:"name"`
	Category         string  `json:"category"`
	Unit             string  `json:"unit"`
	StockQuantity    float64 `json:"stockQuantity"`
	UnitPrice        float64 `json:"unitPrice"`
	ReorderThreshold float64 `json:"reorderThreshold"`
	IsActive         bool    `json:"isActive"`
}

func (r *Repository) ListInventoryItems(ctx context.Context, page pagination.Params) ([]InventoryItem, int64, error) {
	query := `
		SELECT id, name, category::text, unit, stock_quantity, unit_price, reorder_threshold, is_active, count(*) OVER() AS total_count
		FROM billing.inventory_items
		ORDER BY category, name`
	args := []any{}
	if page.Enabled {
		args = append(args, page.Limit())
		query += fmt.Sprintf(" LIMIT $%d", len(args))
		args = append(args, page.Offset())
		query += fmt.Sprintf(" OFFSET $%d", len(args))
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var total int64
	items := []InventoryItem{}
	for rows.Next() {
		var i InventoryItem
		if err := rows.Scan(&i.ID, &i.Name, &i.Category, &i.Unit, &i.StockQuantity, &i.UnitPrice, &i.ReorderThreshold, &i.IsActive, &total); err != nil {
			return nil, 0, err
		}
		items = append(items, i)
	}
	return items, total, rows.Err()
}

func (r *Repository) CreateInventoryItem(ctx context.Context, in InventoryItemInput) (InventoryItem, error) {
	var i InventoryItem
	err := r.pool.QueryRow(ctx, `
		INSERT INTO billing.inventory_items (name, category, unit, stock_quantity, unit_price, reorder_threshold, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, name, category::text, unit, stock_quantity, unit_price, reorder_threshold, is_active`,
		in.Name, in.Category, in.Unit, in.StockQuantity, in.UnitPrice, in.ReorderThreshold, in.IsActive,
	).Scan(&i.ID, &i.Name, &i.Category, &i.Unit, &i.StockQuantity, &i.UnitPrice, &i.ReorderThreshold, &i.IsActive)
	return i, err
}

func (r *Repository) UpdateInventoryItem(ctx context.Context, id string, in InventoryItemInput) (InventoryItem, error) {
	var i InventoryItem
	err := r.pool.QueryRow(ctx, `
		UPDATE billing.inventory_items
		SET name = $1, category = $2, unit = $3, stock_quantity = $4, unit_price = $5,
		    reorder_threshold = $6, is_active = $7, updated_at = now()
		WHERE id = $8
		RETURNING id, name, category::text, unit, stock_quantity, unit_price, reorder_threshold, is_active`,
		in.Name, in.Category, in.Unit, in.StockQuantity, in.UnitPrice, in.ReorderThreshold, in.IsActive, id,
	).Scan(&i.ID, &i.Name, &i.Category, &i.Unit, &i.StockQuantity, &i.UnitPrice, &i.ReorderThreshold, &i.IsActive)
	if errors.Is(err, pgx.ErrNoRows) {
		return i, dberr.ErrNotFound
	}
	return i, err
}

func (r *Repository) DeleteInventoryItem(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM billing.inventory_items WHERE id = $1`, id)
	if dberr.IsForeignKeyViolation(err) {
		return ErrInventoryItemInUse
	}
	return err
}

var ErrInventoryItemInUse = errors.New("inventory item has usage history and cannot be deleted")
