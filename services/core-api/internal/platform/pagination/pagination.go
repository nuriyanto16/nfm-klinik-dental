// Package pagination adds page/pageSize support to list endpoints without
// breaking existing consumers: a request with no page/pageSize query param
// gets the exact same bare-array response as before (used by the mobile
// app and any other client that just wants "all of it" for small reference
// lists like branches/treatments); the admin panel always passes both, and
// gets back an Envelope with the slice plus paging metadata.
package pagination

import "github.com/gofiber/fiber/v2"

type Params struct {
	Page     int
	PageSize int
	Enabled  bool
}

func FromQuery(c *fiber.Ctx) Params {
	if c.Query("page") == "" && c.Query("pageSize") == "" {
		return Params{}
	}
	page := c.QueryInt("page", 1)
	if page < 1 {
		page = 1
	}
	pageSize := c.QueryInt("pageSize", 20)
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	return Params{Page: page, PageSize: pageSize, Enabled: true}
}

func (p Params) Limit() int {
	return p.PageSize
}

func (p Params) Offset() int {
	return (p.Page - 1) * p.PageSize
}

type Envelope[T any] struct {
	Data       []T   `json:"data"`
	Page       int   `json:"page"`
	PageSize   int   `json:"pageSize"`
	Total      int64 `json:"total"`
	TotalPages int64 `json:"totalPages"`
}

func Wrap[T any](data []T, total int64, p Params) Envelope[T] {
	totalPages := total / int64(p.PageSize)
	if total%int64(p.PageSize) != 0 {
		totalPages++
	}
	if data == nil {
		data = []T{}
	}
	return Envelope[T]{Data: data, Page: p.Page, PageSize: p.PageSize, Total: total, TotalPages: totalPages}
}
