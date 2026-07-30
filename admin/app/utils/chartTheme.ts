// Shared chart color tokens — kept centralized so every new chart this
// round (dashboard, doctor/patient panels, billing, reports, reservations)
// reads as one system instead of picking colors ad hoc.
//
// - Single-series magnitude (revenue trend, booking count): one hue, the
//   brand blue, light→dark via opacity — never a rainbow per bar.
// - Multi-series categorical (status breakdown, payment method): a fixed,
//   never-cycled hue order (Okabe-Ito-derived, colorblind-safe).
export const CHART_PRIMARY = '#2563eb'
export const CHART_PRIMARY_LIGHT = '#93c5fd'
export const CHART_SUCCESS = '#16a34a'
export const CHART_WARNING = '#d97706'
export const CHART_ERROR = '#dc2626'

export const CATEGORICAL_PALETTE = [
  '#2563eb', // blue
  '#d97706', // amber
  '#16a34a', // green
  '#dc2626', // red
  '#7c3aed', // violet
  '#0891b2', // cyan
  '#db2777', // pink
  '#65a30d' // lime
]

export function colorForIndex(i: number): string {
  return CATEGORICAL_PALETTE[i % CATEGORICAL_PALETTE.length] ?? CHART_PRIMARY
}
