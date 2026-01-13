# ev-meditech-caadsi

Meditech CAADSI (Clinical Application and Data Sharing Interface) integration project for Fraser Health Authority (FHA).

## Overview

This repository contains SQL queries and documentation for extracting and analyzing medication order data from Meditech's Pharmacy (PHA.RX) module, with a focus on detecting unsafe abbreviations in medication dose instructions.

## Project Structure

### Production Query
- **FHA.unapproved_abbrev.sql** - Production-ready ISMP Canada Do Not Use abbreviation detection query
  - 83-89% ISMP coverage (15-16 of 18 items)
  - Scans both dose instructions and label comments
  - Token-aware pattern matching to minimize false positives
  - SQL Server 2017-2019 compatible

### Directories
- **Archive/** - Historical alternate query versions (reference only)
- **HDPBC Queries/** - High-Dose Parenteral B12 related queries
- **ISMP-CDN Docs/** - ISMP Canada Do Not Use List documentation (PDF)
- **JIRA Files/** - JIRA ticket references and sample queries
- **Test Results/** - Test data and transaction samples (CSV)
- **SQL Metadata/** - Query metadata and field definitions
- **FHA_ANALYTICS db info/** - Database connection information

### Documentation
- **ANALYSIS_UNAPPROVED_ABBREVIATIONS.md** - Comprehensive query analysis and coverage details
- **MULTIPLE_DETECTION.md** - Multiple abbreviation detection capabilities documentation
- **ISMPCanadaDoNotUseList-2025.csv** - CSV version of ISMP Canada Do Not Use List
- **meditech_segment_sql_tables.txt** - Meditech segment to SQL table mapping
- **PHA.RX Segment and Field Definitions.txt** - Meditech PHA.RX data model documentation

## Key Features

### Production Query: FHA.unapproved_abbrev.sql

Comprehensive medication safety monitoring query that detects ISMP Canada 2025 Do Not Use abbreviations in medication orders.

**Detection Capabilities**:
- Scans both dose instructions AND label comments
- Multiple abbreviations detected per order
- Source location tracking (dose vs label)
- Parameterized date range (@StartDate, @EndDate)

**Currently Detected (15-16 of 18 ISMP items)**:
- Unit abbreviations: U, IU, µg (microgram symbol), cc
- Frequency abbreviations: OD, QD, QOD, EOD
- Route abbreviations: AS, AD, AU (ears), OS, OD, OU (eyes) - numeric context only
- Symbols: <, >, ≥, ≤, @
- Clinical abbreviation: D/C (token-aware with word boundaries)
- Numeric safety: Trailing zeros (X.0), Missing leading zeros (.X)
- Ambiguous drug names: MS, MSO4, MgSO4
- Roman numerals: II, III only (I/IV intentionally excluded)
- Time notation: x/7, y/52
- Dot notation: Ṫ, ṪṪ, ṪṪṪ

**ISMP Coverage**: 83-89% (15-16 of 18 items)

**Intentionally Excluded**:
- Roman numeral I - Excessive false positives in prose
- Roman numeral IV - Valid route of administration (intravenous)
- D, d (days/doses) - Removed due to false positives (MD, PhD, etc.); QD already covered

### Data Sources
- **Database**: FHA_ANALYTICS
- **Primary Tables**: 
  - `F_MeditechPHARxMain` - Prescription orders
  - `D_MeditechPHARxDoseInstructions` - Multi-line dose instructions (scan target)
  - `F_MeditechPHARxLabelComments` - Pharmacist label comments
  - Drug dictionary, patient demographics, location data

## Query Architecture

### Pattern Matching Strategy
- **CHARINDEX** - Fast literal substring matching
- **PATINDEX** - Context-aware wildcard pattern matching (digit prefixes, spacing)
- **CROSS APPLY** - Aggregates all detected abbreviations per order
- **STRING_AGG** - Combines multi-line dose instructions for scanning

### False Positive Reduction
Evolved through 25+ commits with refinements:
- Digit prefix requirements (e.g., "10U" vs "bug")
- Space/slash boundary requirements
- Removed problematic Unicode patterns
- Case-insensitive matching

## Usage

### Prerequisites
- SQL Server access to FHA_ANALYTICS database
- Appropriate permissions for Meditech tables

### Running the Query
```sql
-- Production query - detects ISMP abbreviations in previous calendar year
-- Returns up to 100 flagged orders
EXEC FHA.unapproved_abbrev.sql
```

### Output Columns (20 total)

**Site/System**:
- Site, System

**Order Details**:
- Order Number, Order Entered, Order Type, StartDate, StopDate, Provider

**Medication Details**:
- Drug Mnemonic, Generic Name, DIN
- Dose, RangeDoseLow, RangeDoseHigh, Schedule
- Dose Unit, Dosage Form, Route, Frequency

**Free-text Fields**:
- Label Comment (multi-line pharmacist comments)
- Dose Instructions (multi-line dosing instructions)

**Detection Results**:
- Flagged - All detected abbreviations (comma-separated)
- FlaggedInDose - Abbreviations found in dose instructions only
- FlaggedInLabel - Abbreviations found in label comments only

**Note**: Patient identifiers (Account, MRN, Location) are commented out for privacy-focused safety monitoring

## Regulatory Compliance

**Reference Standard**: ISMP Canada Dangerous Abbreviations, Symbols, and Dose Designations (©2025)
- **URL**: [ismpcanada.ca/do-not-use-list](https://ismpcanada.ca/do-not-use-list)
- **Local Copy**: `ISMP-CDN Docs/ISMPCanadaDoNotUseList-2025-8X11.pdf`

## Version History

**Current**: Production-ready query with 83-89% ISMP coverage
- Token-aware D/C detection (word boundaries)
- Dual-field scanning (dose instructions + label comments)
- Source location tracking
- SQL Server 2017-2019 compatible
- Comprehensive false positive prevention

**Archive**: Historical alternate versions preserved in `Archive/` directory

## Future Enhancements

See `ANALYSIS_UNAPPROVED_ABBREVIATIONS.md` for detailed recommendations:
- Real-time validation at order entry
- Provider-specific feedback reporting
- Trend analysis dashboards
- Integration with CPOE systems
- Machine learning for context-aware detection

## License

Internal Fraser Health Authority project.

## Contact

For questions or issues, contact the FHA Analytics team.
