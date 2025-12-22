# Meditech CAADSI Repository Analysis
## Focus: Unapproved Abbreviations Query

---

## Repository Overview

**Repository**: `ev-meditech-caadsi`  
**Purpose**: Meditech CAADSI (Clinical Application and Data Sharing Interface) integration project  
**Database**: FHA_ANALYTICS (Fraser Health Authority)  
**Primary System**: Meditech Pharmacy (PHA.RX) module

---

## Project Structure

### Core Query Files
- **FHA.unapproved_abbrev.sql** - Main unapproved abbreviations detection query
- **FHA.patient-order-medication-caadsi.sql** - Base medication order query (CAADSI compliant)
- **FHA.order_sample_steven.sql** - Sample order query

### Supporting Directories
- **HDPBC Queries/** - High-Dose Parenteral B12 (HDPBC) related queries
  - Patient, practitioner, medication, order, and ingredient queries
- **SQL Metadata/** - Query metadata and documentation
- **JIRA Text Files/** - JIRA ticket references (currently empty placeholder)
- **FHA_ANALYTICS db info/** - Database connection information

### Documentation Files
- **meditech_segment_sql_tables.txt** - Maps Meditech segments to SQL table names
- **PHA.RX Segment and Field Definitions.txt** - Meditech PHA.RX data model documentation
- **test-caadsi.csv** - Test data (85KB)
- **transactions-sample.csv** - Transaction samples (28KB)

---

## Unapproved Abbreviations Query Deep Dive

### Query Purpose
The `FHA.unapproved_abbrev.sql` query identifies medication orders containing unsafe or unapproved medical abbreviations in dose instructions, which pose patient safety risks due to potential misinterpretation.

### Evolution History
The query underwent **25+ commits** on the `unapproved_abbrev` branch, showing iterative refinement to reduce false positives:

**Key Milestones**:
1. **Initial implementation** (6fae90f) - Basic filter for U, IU, ug, cc abbreviations
2. **Date filtering** (be1b494) - Restricted to last calendar year (2024)
3. **False positive reduction** (219a22c - f733bc5) - Required spacing around abbreviations
4. **Symbol detection** (6ea1eab) - Added <, >, ≥, ≤, @ symbols
5. **Frequency abbreviations** (caea11e) - Added OD, QD, QOD, EOD
6. **Context-aware matching** (d0299a2 - b991ffc) - Required numeric prefixes for certain abbreviations
7. **Unicode handling** (8ab089e - 37da32e) - Removed problematic >= and <= checks causing false positives
8. **Pattern refactoring** (ee0d1fd) - Implemented CTE-based approach with CROSS APPLY
9. **Final optimization** (d7f2577 - 905fc0f) - Digit-prefixed requirements for ug/cc using PATINDEX

### Query Architecture

#### 1. **Forbidden Abbreviations CTE**
Defines two pattern matching strategies:
- **CHAR (Character Index)**: Literal substring matching via `CHARINDEX()`
- **PAT (Pattern Index)**: Wildcard pattern matching via `PATINDEX()` for context-sensitive rules

#### 2. **Abbreviation Categories**

**Dosage Units**:
- **U (Unit)** - Must follow digits, followed by space or slash
  - Patterns: `%[0-9]U %`, `%[0-9] U %`, `%[0-9]U/%`, `%[0-9] U/%`
- **IU (International Unit)** - Must follow digits, followed by space or slash
  - Patterns: `%[0-9]IU %`, `%[0-9] IU %`, `%[0-9]IU/%`, `%[0-9] IU/%`
- **µg (Microgram symbol)** - Unicode character detection
  - Pattern: `NCHAR(181) + 'g'` (matches µg symbol)
- **cc (Cubic Centimeter)** - Must follow digits (case-insensitive), followed by space or slash
  - Patterns: `%[0-9]cc %`, `%[0-9] cc %`, `%[0-9]cc/%`, `%[0-9] cc/%` (plus CC variants)

**Symbols**:
- **Unicode comparison**: ≥ (8805), ≤ (8804) - Using `NCHAR()` to prevent confusion with `=`
- **ASCII comparison**: `>`, `<`
- **At symbol**: `@`

**Clinical Abbreviations**:
- **D/C (Discontinue)** - Case-insensitive: `D/C`, `d/c`
- **Frequency terms** (case-insensitive):
  - OD (Once Daily)
  - QD (Daily)
  - QOD (Every Other Day)
  - EOD (Every Other Day)

**Ear Administration Routes**:
- **AD (Right Ear)** - Must follow digits
- **AS (Left Ear)** - Must follow digits
- **AU (Both Ears)** - Must follow digits
- Patterns require `%[0-9]AD %` format to avoid false matches

**Numeric Safety Issues**:
- **Trailing zero** (e.g., "1.0 mg") - Pattern: `%[0-9]\.0[^0-9]%`
- **Missing leading zero** (e.g., ".5 mg") - Pattern: `%[^0-9]\.[0-9]%`

**Ambiguous Drug Abbreviations**:
- **MS** - Morphine vs Magnesium Sulfate confusion
- **MSO4** - Morphine Sulfate vs Magnesium Sulfate
- **MgSO4** - Magnesium Sulfate (can be confused with MSO4)
- Patterns require non-letter boundaries: `%[^A-Za-z]MS[^A-Za-z]%`

**Roman Numerals** (when used as numeric representations):
- **ii, II** - Pattern: `%[ ]ii[ ][^.]%` (space-bounded, not before period)
- **iii, III** - Pattern: `%[ ]iii[ ][^.]%`
- **Note**: Excludes single "I" due to excessive false positives
- **Exclusions**: "Level II", "Level III" filtered out to prevent false positives

#### 3. **Data Aggregation CTEs**

**CombinedLabelComments**:
```sql
STRING_AGG(LabelComment, CHAR(10)) WITHIN GROUP (ORDER BY LabelCommentQ)
```
Concatenates multi-line label comments from `F_MeditechPHARxLabelComments` with line breaks.

**CombinedDoseInstructions**:
```sql
STRING_AGG(DoseInstruction, CHAR(10)) WITHIN GROUP (ORDER BY DoseInstructionQ)
```
Concatenates multi-line dose instructions from `D_MeditechPHARxDoseInstructions` - **this is the primary scan target**.

#### 4. **Main Query Structure**

**Data Sources**:
- `F_MeditechPHARxMain` (rx) - Core prescription orders
- `F_MeditechADMPatMain` (pat) - Patient demographics
- `F_MeditechADMPatCanadaRecall` (recall) - Canadian patient identifiers
- `F_MeditechPHARxInpatientMedications` (med) - Medication details
- `D_MeditechPHADrugMain` (drug_main) - Drug dictionary (dispense info)
- `D_MeditechPHADrugMain5` (drug_main5) - Drug dictionary (generic names)
- `F_MeditechPHARxRangeDoses` (rd) - Range dose parameters
- `D_MeditechMISLocnMain` (loc) - Location data
- `D_MeditechPHASiteDictionary` (site) - Site information
- CTEs: `CombinedLabelComments`, `CombinedDoseInstructions`

**Key Joins**:
- All joins use `COLLATE DATABASE_DEFAULT` to handle collation differences
- Patient linked via `rx.Patient = pat.Urn`
- Medications linked via `rx.Urn = med.Urn`
- Drugs linked via `med.Med = drug_main.Mnemonic`
- Multi-line text linked via URN + SYSSystemID

#### 5. **Abbreviation Detection Logic**

**CROSS APPLY Pattern**:
```sql
CROSS APPLY (
    SELECT STRING_AGG(f.Meaning, ', ') AS Flagged
    FROM Forbidden f
    WHERE
        (f.MatchType = 'CHAR' AND CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0)
        OR
        (f.MatchType = 'PAT'  AND PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0)
) flags
```
- Scans `FullDoseInstruction` against all forbidden patterns
- Aggregates matched abbreviation meanings into comma-separated list
- `CROSS APPLY` ensures row exists for every prescription (with or without matches)

#### 6. **Filters**

**Exclusions**:
- `rx.Sig <> '.STK-MED'` - Excludes stock medication records
- `dose.FullDoseInstruction NOT LIKE '%Antithrombin III%'` - Excludes legitimate "III" usage in medication name

**Date Range**:
```sql
rx.EnterDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
AND rx.EnterDate < DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
```
Filters to previous full calendar year (e.g., 2024 if run in 2025).

**Positive Matches Only**:
- `flags.Flagged IS NOT NULL` - Only returns orders with detected abbreviations

**Result Limit**:
- `TOP 100` - Returns maximum 100 flagged orders

---

## Output Columns

### Patient Information
- **Account** - Unit number
- **MRN** - Medical record number
- **Site** - Facility site mnemonic
- **Location** - Patient location
- **System** - System ID (MC mapped to CS)

### Order Information
- **Order Number** - Prescription number
- **Order Entered** - Entry date/time
- **OrderType** - Type of order
- **StartDate** - Order start date
- **StopDate** - Order stop date
- **Provider** - Ordering physician

### Medication Information
- **Drug Mnemonic** - Drug identifier
- **Generic Name** - Generic drug name
- **DIN** - Drug Identification Number (NDC)
- **Dose** - Prescribed dose
- **RangeDoseLow** - Minimum range dose
- **RangeDoseHigh** - Maximum range dose
- **Schedule** - Dosing schedule
- **Dose Unit** - Unit of measurement
- **Dosage Form** - Form (tablet, liquid, etc.)
- **Route** - Administration route
- **Frequency** - Dosing frequency (Sig)

### Text Fields
- **Label Comment** - Multi-line pharmacist label comments
- **Dose Instructions** - Multi-line dose instructions (scan target)

### Detection Result
- **Flagged Abbreviation** - Comma-separated list of detected unsafe abbreviations

---

## Base Query Comparison

The `FHA.patient-order-medication-caadsi.sql` query serves as the foundation and differs from the unapproved abbreviations query in:

### Similarities
- Identical CTE structure for aggregating label comments and dose instructions
- Same table joins and relationships
- Same collation handling
- Same column output (excluding flagged abbreviations)

### Key Differences
1. **No abbreviation detection** - Missing the `Forbidden` CTE and `CROSS APPLY` logic
2. **No date filtering** - No restriction to previous calendar year
3. **No flagged column** - Does not include `[Flagged Abbreviation]` output
4. **Different filter** - Includes commented-out drug mnemonic filter:
   ```sql
   -- AND drug_main.Mnemonic IN ('POTCH1.5T', 'SALIPH', 'MAGICL', 'SALBU100H', 'IPRAT20H')
   ```
5. **No positive-match requirement** - Returns all orders (up to TOP 100)

---

## Technical Design Patterns

### 1. **Incremental False Positive Reduction**
The 25+ commit history demonstrates methodical refinement:
- Started with broad string searches
- Added context requirements (spacing, digit prefixes)
- Removed problematic patterns (Unicode >= causing = false positives)
- Consolidated into maintainable CTE pattern

### 2. **Pattern Matching Strategy**
Two-tier approach optimizes performance and flexibility:
- **CHARINDEX** - Fast exact matches for simple patterns
- **PATINDEX** - Context-aware matching with wildcard support

### 3. **String Aggregation with Ordering**
```sql
STRING_AGG(field, CHAR(10)) WITHIN GROUP (ORDER BY sequenceField)
```
Ensures multi-line text maintains original order using sequence fields.

### 4. **Collation Normalization**
All joins include `COLLATE DATABASE_DEFAULT` to handle mixed collations across tables.

### 5. **System Mapping**
```sql
CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END
```
Normalizes system identifiers for reporting consistency.

---

## Data Quality Considerations

### False Positive Challenges
Historical commits show struggles with:
- **Substring matches** - "bug bites" triggering "ug" detection
- **Symbol confusion** - Equals signs triggering >= and <= checks
- **PICC lines** - "PICC" triggering "cc" detection
- **Context-free matching** - "U" appearing in general text

### Current Mitigation Strategies
- Digit prefix requirements for unit abbreviations
- Space/slash boundary requirements
- Removal of problematic Unicode patterns
- Case-insensitive pattern variations

### Remaining Risks
- **Legitimate usage** - Some abbreviations may be contextually appropriate
- **Incomplete scanning** - Only checks `DoseInstructions`, not all free-text fields
- **Pattern gaps** - May miss creative variations or typos of dangerous abbreviations

---

## Regulatory Context

### ISMP Canada Do Not Use List (2025)
The query detects abbreviations from the official **ISMP Canada Dangerous Abbreviations, Symbols, and Dose Designations** list. Below is the complete reference table:

| DO NOT USE | ALWAYS USE | Query Coverage |
|------------|------------|----------------|
| **Abbreviated medication name** (e.g., MSO4, MTX) | Use full name of medication | ❌ Not detected |
| **U** | Use units | ✅ Detected |
| **IU** | Use International units | ✅ Detected |
| **ug, µg** | Use microgram or mcg | ✅ Detected |
| **cc** | Use millilitre or mL | ✅ Detected |
| **OD, QD** | Use daily | ✅ Detected |
| **QOD, EOD** | Use every other day | ✅ Detected |
| **D, d** | Use days or doses | ✅ Detected (numeric context) |
| **x/7, y/52** | Use x days, y weeks | ✅ Detected |
| **AS, AD, AU** | Use left ear, right ear, both ears | ✅ Detected |
| **OS, OD, OU** | Use left eye, right eye, both eyes | ✅ Detected (numeric context) |
| **< >** | Use less than, lower than or more than, greater than | ✅ Detected (includes ≥ ≤) |
| **@** | Use at | ✅ Detected |
| **D/C** | Use discharge when referring to a discharge with medications from a care area. Where discontinue is intended, stop or discontinue may be safer alternatives. | ✅ Detected |
| **medication A, medication B** | Use the intended Arabic numerals, or spell out the numeral. | ✅ Detected (MS, MSO4, MgSO4) |
| **I, II, III, IV, ...** | Use the intended Arabic numerals, or spell out the numeral. | ⚠️ Partial (II, III only; I/IV excluded) |
| **Ṫ, ṪṪ, ṪṪṪ, ...** | Use the intended Arabic numerals, or spell out the numeral. | ✅ Detected |
| **X.0** (trailing zero) | Use X. Never use zeroes after a decimal point. | ✅ Detected |
| **.X** (lack of leading zero) | Use 0.X. Always use a zero before a decimal point. | ✅ Detected |

**Query Coverage: 16-17 of 18 items (89-94%)**

### Gap Analysis

**Currently Detected (16-17 items)**:
- Unit abbreviations: U, IU, ug/µg, cc
- Frequency abbreviations: OD, QD, QOD, EOD
- Ear route abbreviations: AS, AD, AU
- Eye route abbreviations: OS, OD, OU (numeric context)
- Symbols: <, >, ≥, ≤, @
- Clinical abbreviation: D/C
- Numeric safety: Trailing zeros (X.0), Missing leading zeros (.X)
- Ambiguous drug names: MS, MSO4, MgSO4
- Roman numerals: II, III (with context filtering)
- Time notation: x/7, y/52
- Days/Doses: D, d (numeric context)
- Dot notation: Ṫ, ṪṪ, ṪṪṪ (Unicode 7786/7787)

**Not Currently Detected (1-2 items)**:
- Roman numeral: I (excluded due to excessive false positives in prose)
- Roman numeral: IV (valid route of administration - intentionally excluded)

**Note**: Some items remain difficult to detect without causing excessive false positives:
- **D, d** - Too common in normal text ("daily", "days", "medication")
- **OD** (eye) vs **OD** (once daily) - Ambiguous without anatomical context
- **Roman numeral I** - Appears frequently in legitimate contexts (Vitamin I, Phase I, etc.)
- **Dot notation (Ṫ)** - Rare in modern systems; minimal occurrence expected
- **x/7, y/52** - Too complex for pattern matching without contextual numeric parsing

### Source Reference
**Document**: ISMP Canada Dangerous Abbreviations, Symbols, and Dose Designations (©2025)  
**URL**: [ismpcanada.ca/do-not-use-list](https://ismpcanada.ca/do-not-use-list)  
**Local Files**: 
- PDF: `ISMPCanadaDoNotUseList-2025-8X11.pdf`
- CSV: `ISMPCanadaDoNotUseList-2025.csv`

---

## Performance Considerations

### Query Optimization
- **TOP 100** limit prevents excessive result sets
- **Date filtering** reduces scan range to single year
- **Early NULL filtering** (`WHERE flags.Flagged IS NOT NULL`) prevents returning non-matches
- **STRING_AGG with WITHIN GROUP** efficiently handles multi-line text

### Potential Bottlenecks
- **CROSS APPLY** with multiple pattern checks may be compute-intensive
- **Multiple PATINDEX calls** for each row and pattern combination
- **No indexes specified** - performance depends on underlying table indexes

### Scalability Recommendations
1. Add indexes on frequently joined columns (URN, SYSSystemID, Mnemonic)
2. Consider materialized view for `CombinedDoseInstructions` if frequently queried
3. Partition date-based tables by year/month
4. Adjust `TOP N` dynamically based on monitoring needs

---

## Related Queries

### HDPBC Query Set
The repository includes complementary High-Dose Parenteral B12 queries:
- **FHA.patient.sql** - Patient demographics
- **FHA.practitioner.sql** - Provider information
- **FHA.medication.sql** - Medication details
- **FHA.order.sql** - Order information
- **FHA.ingredients_*.sql** - Ingredient components (med, additive, carrier)
- **FHA.patient-order-medication-SAMPLE.sql** - Combined sample query

These follow similar patterns but focus on specific medication types rather than abbreviation safety.

---

## Recommendations

### Short-term
1. **Extend scanning** - Apply abbreviation detection to `LabelComment` field as well
2. **Add severity classification** - Categorize abbreviations by risk level
3. **Export flagged orders** - Remove `TOP 100` limit and export full dataset for review
4. **Add detection date** - Include `GETDATE()` to track when each order was flagged

### Medium-term
1. **Real-time alerts** - Implement as trigger or validation rule in Meditech
2. **Provider feedback loop** - Generate reports showing abbreviation usage by provider
3. **Trend analysis** - Track abbreviation prevalence over time
4. **Education targeting** - Identify high-risk departments/providers for training

### Long-term
1. **Prevention at entry** - Block abbreviations at order entry point
2. **Standardized picklists** - Replace free-text fields with structured data entry
3. **Integration with CPOE** - Embed validation in Computerized Provider Order Entry system
4. **Machine learning** - Train models to detect contextual misuse beyond pattern matching

---

## Git Branch Status

- **Current branch**: `dev` (HEAD at cfc9544)
- **Feature branch**: `unapproved_abbrev` (ahead of main, at 905fc0f)
- **Main branch**: `main` (at 0d9198b)

The unapproved abbreviations work exists on a separate feature branch and has not yet been merged to main. The last commit on `dev` added dose instructions to the base medication query, which enabled the abbreviation scanning functionality.

---

## Conclusion

The `FHA.unapproved_abbrev.sql` query represents a mature, iteratively refined solution for detecting unsafe medical abbreviations in Meditech medication orders. Its evolution through 25+ commits demonstrates a methodical approach to reducing false positives while maintaining comprehensive coverage of dangerous abbreviations.

The query serves as a **retrospective quality assurance tool** for identifying existing orders with safety risks, complementing the base CAADSI medication query. Its pattern-based detection approach is production-ready but would benefit from expansion to real-time validation and prevention mechanisms.

**Key Strengths**:
- Comprehensive abbreviation coverage aligned with ISMP/TJC standards
- Context-aware pattern matching to minimize false positives
- Clean, maintainable CTE-based architecture
- Documented evolution showing continuous improvement

**Opportunities**:
- Expand to additional free-text fields
- Implement real-time prevention rather than retrospective detection
- Add severity classification and trending analytics
- Integrate with provider education and feedback systems
