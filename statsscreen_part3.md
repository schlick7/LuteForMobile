# StatsScreen Part 3: UI Components & Charts

## Widgets to Implement

| Widget | Purpose |
|--------|---------|
| `summary_cards.dart` | Quick stats overview (today, week, total) |
| `period_filter_widget.dart` | Time period selector (7d, 30d, 90d, 1y, all) |
| `language_filter_widget.dart` | Language dropdown selector |
| `words_read_chart.dart` | Line chart for cumulative words |
| `term_status_chart.dart` | Pie chart for term distribution |
| `language_breakdown_card.dart` | Per-language stats list |

## Chart Configuration (fl_chart)

**Line Chart (words_read_chart.dart):**
- X-axis: Date
- Y-axis: Cumulative word count
- Multi-language overlay with color-coded lines
- Interactive tooltips on tap

**Pie Chart (term_status_chart.dart):**
- Segments: Status 1-5, Status 99 (Well Known)
- Interactive tap to show count
- Legend with color coding

## Dependencies

Already in `pubspec.yaml`:
- `fl_chart: ^1.1.1` - Charts

## Tasks

1. Create `summary_cards.dart`
2. Create `period_filter_widget.dart`
3. Create `language_filter_widget.dart`
4. Create `words_read_chart.dart`
5. Create `term_status_chart.dart`
6. Create `language_breakdown_card.dart`
7. Update `stats_screen.dart` to include all widgets
8. Add refresh indicator and pull-to-refresh
9. Test on both light/dark themes
