# ev-meditech-caadsi

Meditech CAADSI (Clinical Application and Data Sharing Interface) integration project for Fraser Health Authority (FHA).

## Overview

This repository contains SQL queries and documentation for extracting and analyzing medication order data from Meditech's Pharmacy (PHA.RX) module, with a focus on detecting unsafe abbreviations in medication dose instructions.

## Project Structure

### Core Query Files
- **FHA.patient-order-medication-caadsi.sql** - Base CAADSI-compliant medication order query
- **FHA.unapproved_abbrev.sql** - Detects ISMP Canada Do Not Use abbreviations in dose instructions
- **FHA.unapproved_abbrev-only_roman_num.sql** - Test query for Roman numeral detection

### Directories
- **HDPBC Queries/** - High-Dose Parenteral B12 (HDPBC) related queries
  - Patient, practitioner, medication, order, and ingredient queries
- **ISMP-CDN Docs/** - ISMP Canada Do Not Use List documentation (PDF)
- **JIRA Files/** - JIRA ticket references and sample queries
- **Test Results/** - Test data and transaction samples (CSV)
- **SQL Metadata/** - Query metadata and field definitions
- **FHA_ANALYTICS db info/** - Database connection information

### Documentation
- **ANALYSIS_UNAPPROVED_ABBREVIATIONS.md** - Comprehensive analysis of the unapproved abbreviations query
- **ISMPCanadaDoNotUseList-2025.csv** - CSV version of ISMP Canada Do Not Use List
- **meditech_segment_sql_tables.txt** - Meditech segment to SQL table mapping
- **PHA.RX Segment and Field Definitions.txt** - Meditech PHA.RX data model documentation

## Key Features

### Unapproved Abbreviations Detection
The primary query (`FHA.unapproved_abbrev.sql`) identifies medication orders containing dangerous abbreviations that violate ISMP Canada safety standards:

**Currently Detected (13 of 19 ISMP items)**:
- Unit abbreviations: U, IU, ug/µg, cc
- Frequency abbreviations: OD, QD, QOD, EOD
- Ear route abbreviations: AS, AD, AU
- Symbols: <, >, ≥, ≤, @
- Clinical abbreviation: D/C
- Numeric safety: Trailing zeros (X.0), Missing leading zeros (.X)
- Ambiguous drug names: MS, MSO4, MgSO4
- Roman numerals: II, III (with context filtering)

**Query Coverage**: 68% of official ISMP Canada Do Not Use List (2025)

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

### Running Queries
```sql
-- Detect unapproved abbreviations in previous calendar year
-- Returns up to 100 flagged orders with patient, medication, and order details
EXEC FHA.unapproved_abbrev.sql
```

### Output Columns
- Patient info: Account, MRN, Site, Location
- Order info: Order Number, Entered Date, Provider, Start/Stop dates
- Medication info: Drug name, dose, route, frequency, instructions
- Detection: Flagged Abbreviation (comma-separated list)

## Regulatory Compliance

**Reference Standard**: ISMP Canada Dangerous Abbreviations, Symbols, and Dose Designations (©2025)
- **URL**: [ismpcanada.ca/do-not-use-list](https://ismpcanada.ca/do-not-use-list)
- **Local Copy**: `ISMP-CDN Docs/ISMPCanadaDoNotUseList-2025-8X11.pdf`

## Future Enhancements

See `ANALYSIS_UNAPPROVED_ABBREVIATIONS.md` for detailed recommendations:
- Expand scanning to label comments
- Detect trailing/leading zeros
- Add Roman numeral detection
- Implement real-time validation
- Provider feedback reporting

## License

Internal Fraser Health Authority project.

## Contact

For questions or issues, contact the FHA Analytics team.
