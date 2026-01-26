# SQL Query Updates - January 26, 2026

## Issue Identified

The original SQL query (`FHA.unapproved_abbrev.sql`) was filtering to only return orders that HAD unapproved abbreviations:

```sql
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
  AND flags.Flagged IS NOT NULL  -- ← THIS LINE FILTERS TO ONLY FLAGGED ORDERS
```

This caused percentage calculations to be misleading:
- **What we calculated:** "61.4% of orders WITH issues contain <" 
- **What we need:** "X% of ALL orders scanned contain <"

## Solution

Created new SQL query file: `FHA.unapproved_abbrev_ALL_ORDERS.sql`

### Key Changes

**Line 230 - Removed filtering condition:**
```sql
-- OLD (line 230 in original):
AND flags.Flagged IS NOT NULL

-- NEW (line 230 in updated):
-- REMOVED: AND flags.Flagged IS NOT NULL  -- This line was filtering to only flagged orders
```

**Also removed line 120 - `SELECT TOP 100`:**
```sql
-- OLD:
SELECT TOP 100
    site.Mnemonic AS Site,
    ...

-- NEW:
SELECT
    site.Mnemonic AS Site,
    ...
```

This ensures we get ALL orders, not just a sample.

### Impact

**Before (with filter):**
- Query returns: 10,406 orders (only those with issues)
- CSV contains: Only flagged orders
- Percentage calculation: Relative to flagged orders only
- Result: Misleading - "61.4% of problematic orders have <"

**After (without filter):**
- Query returns: ALL orders processed (estimated 100,000+)
- CSV contains: All orders, with NULL in Flagged columns for clean orders
- Percentage calculation: Relative to all orders scanned
- Result: Accurate - "X% of ALL orders have <"

## Data Structure

### Flagged Order (has issues):
```
Site,System,...,Flagged,FlaggedInDose,FlaggedInLabel
RCH,EX,...,"< (Less Than)","< (Less Than)",NULL
```

### Clean Order (no issues):
```
Site,System,...,Flagged,FlaggedInDose,FlaggedInLabel
RCH,EX,...,NULL,NULL,NULL
```

## Visualization Updates Needed

The Python visualization script (`visualize_abbreviations.py`) currently works correctly because it counts actual records. However, the interpretation changes:

**Current logic (CORRECT):**
```python
total_orders = len(data)  # Count of ALL records
mc_orders = len(mc_order_ids)  # Count of ALL MC orders
```

**With new data:**
- `total_orders` = true total (e.g., 150,000 instead of 10,406)
- `mc_orders` = true total MC orders (e.g., 120,000 instead of 8,361)
- Percentages will now show true prevalence

## Expected Results Change

### Example: < (Less Than) abbreviation

**Old Query (only flagged orders):**
- Total MC orders in file: 8,361
- Orders with <: 5,135
- Percentage: 61.4% ← MISLEADING
- Interpretation: "61% of problematic MC orders have <"

**New Query (all orders):**
- Total MC orders in file: ~120,000 (estimated)
- Orders with <: 5,135
- Percentage: ~4.3% ← ACCURATE  
- Interpretation: "4.3% of ALL MC orders have <"

The new percentage is much more useful for:
- Understanding true scope of the problem
- Setting realistic improvement goals
- Comparing with industry benchmarks
- Resource planning

## Implementation Steps

1. **Run Updated SQL Query**
   - Use `FHA.unapproved_abbrev_ALL_ORDERS.sql`
   - Export results to CSV
   - Place in `Test Results/` directory

2. **Run Visualization Script**
   - No code changes needed to `visualize_abbreviations.py`
   - Script will automatically count all records
   - Percentages will now be accurate

3. **Review Results**
   - Percentages will be significantly lower (more accurate)
   - Total order counts will be much higher
   - Interpretation: % of ALL orders, not just problematic ones

## File Comparison

### Original Query
- **File:** `FHA.unapproved_abbrev.sql`
- **Line 230:** `AND flags.Flagged IS NOT NULL`
- **Use:** Returns only orders with issues
- **Purpose:** Quick analysis of what issues exist

### Updated Query  
- **File:** `FHA.unapproved_abbrev_ALL_ORDERS.sql`
- **Line 230:** Comment explaining removal
- **Use:** Returns ALL orders
- **Purpose:** Accurate prevalence calculation

## Testing

To verify the query works correctly:

```sql
-- Count total orders
SELECT COUNT(*) AS TotalOrders
FROM [YourTable]
WHERE ... (same WHERE conditions without Flagged filter)

-- Count flagged orders
SELECT COUNT(*) AS FlaggedOrders
FROM [YourTable]
WHERE ... (same conditions)
  AND flags.Flagged IS NOT NULL

-- Calculate clean order rate
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN flags.Flagged IS NULL THEN 1 ELSE 0 END) AS CleanOrders,
    SUM(CASE WHEN flags.Flagged IS NOT NULL THEN 1 ELSE 0 END) AS FlaggedOrders,
    CAST(SUM(CASE WHEN flags.Flagged IS NULL THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS CleanOrderPct
FROM [YourTable]
WHERE ... (same conditions)
```

## Notes

- The visualization Python script does NOT need changes
- Current percentage charts (Figures 4-7) were already trying to calculate "% of total site orders"
- Those charts just need the new data file to work correctly
- The script already handles NULL values in Flagged columns correctly

## Recommendation

Replace the data source file:
1. Run `FHA.unapproved_abbrev_ALL_ORDERS.sql`
2. Export to `Test Results/unap_abbrev_mt_ALL_2025-01-19.csv`
3. Update script to read new filename (or replace old file)
4. Re-run `python3 visualize_abbreviations.py`
5. Compare old vs new percentages to see true scope

---

**Created:** 2026-01-26  
**Author:** Analysis Team  
**Status:** Ready for Implementation
