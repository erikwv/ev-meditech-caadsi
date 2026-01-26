# Project Update - January 26, 2026

## Unapproved Abbreviation Analysis - Visualization Enhancements

### Date: 2026-01-26
### Time: 15:27 UTC

---

## Summary of Changes

Modified the unapproved abbreviation analysis visualization script to provide more targeted and system-specific insights.

## Changes Made

### 1. Modified `visualize_abbreviations.py`

**Key Updates:**
- Changed from showing top 10 to **top 3** unapproved abbreviations overall
- Added **system-specific analysis** for MC (EX) and CS systems
- Added **site-specific breakdowns** for top 3 sites in each system
- Enhanced data processing to track abbreviations by system and site
- Created separate visualization outputs for each analysis type

**New Data Structures:**
- Added system-specific counters: `dose_counter_mc`, `label_counter_mc`, `dose_counter_cs`, `label_counter_cs`
- Added site tracking dictionaries: `mc_sites{}` and `cs_sites{}` with dose/label counters per site

### 2. New Visualization Outputs

Generated three separate PNG files in `Test Results/`:

#### a) `unapproved_abbreviations_top3.png`
- Single chart showing top 3 abbreviations overall
- Stacked horizontal bars (Dose Instructions vs Label Comments)
- Size: 134KB

#### b) `unapproved_abbreviations_mc_system.png`
- 2x2 grid layout with 4 charts:
  - Chart 1: Top 10 abbreviations for MC (EX) system
  - Charts 2-4: Site-specific top 10 for RCH, ERH, and MMH sites
- Size: 437KB

#### c) `unapproved_abbreviations_cs_system.png`
- 2x2 grid layout with 4 charts:
  - Chart 1: Top 10 abbreviations for CS system
  - Charts 2-4: Site-specific top 10 for SMH, BH, and RMH sites
- Size: 447KB

### 3. Enhanced Summary Statistics

Updated console output to include:
- System-specific totals (MC vs CS)
- Top 5 abbreviations by system
- Top 3 sites by volume for each system

---

## Results Summary

### Overall Statistics
- **Total orders flagged:** 10,406
- **Total instances:** 10,681
  - Dose Instructions: 7,617
  - Label Comments: 3,064
- **MC (EX) System:** 8,591 instances (80.4%)
- **CS System:** 2,090 instances (19.6%)

### Top 3 Unapproved Abbreviations (Overall)
1. **< (Less Than)** - 5,638 instances
   - Dose: 5,022 | Label: 616
2. **> (Greater Than)** - 1,670 instances
   - Dose: 1,229 | Label: 441
3. **cc (Cubic Centimeter)** - 1,131 instances
   - Dose: 613 | Label: 518

### System Breakdown

#### MC (EX) System - Top 5
1. < (Less Than): 5,135 instances
2. > (Greater Than): 1,362 instances
3. cc (Cubic Centimeter): 1,031 instances
4. @ (At Symbol): 479 instances
5. U (Unit): 147 instances

**Top MC Sites by Volume:**
1. RCH: 12,669 instances
2. ERH: 3,641 instances
3. MMH: 394 instances

#### CS System - Top 5
1. U (Unit): 42 instances
2. IU (International Unit): 62 instances
3. cc (Cubic Centimeter): 100 instances
4. @ (At Symbol): 486 instances
5. x/7 (Days notation): 95 instances

**Top CS Sites by Volume:**
1. SMH: 1,260 instances
2. BH: 778 instances
3. RMH: 661 instances

---

## Technical Notes

### Data Source
- CSV File: `Test Results/unap_abbrev_mt_2025-01-19.csv`
- Fields used: Site, System, FlaggedInDose, FlaggedInLabel

### System Mapping
- **MC System** = System field value "EX"
- **CS System** = System field value "CS"

### Chart Specifications
- Color scheme: Red (#e74c3c) for Dose Instructions, Blue (#3498db) for Label Comments
- Chart style: Horizontal stacked bar charts with value labels
- Resolution: 300 DPI
- Format: PNG

---

## Files Modified
- `visualize_abbreviations.py` - Complete refactor of visualization logic

## Files Created
- `Test Results/unapproved_abbreviations_top3.png`
- `Test Results/unapproved_abbreviations_mc_system.png`
- `Test Results/unapproved_abbreviations_cs_system.png`

---

## Next Steps / Recommendations

1. Review site-specific patterns to identify facility-specific training needs
2. Consider creating time-series analysis if historical data available
3. Investigate why RCH has significantly higher volumes than other MC sites
4. Analyze why @ (At Symbol) is predominantly in Label Comments for CS but more balanced in MC

---

## Execution Command
```bash
python3 visualize_abbreviations.py
```

**Execution Status:** ✅ Successful  
**Execution Time:** ~2-3 seconds  
**No errors or warnings**
