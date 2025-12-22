# Multiple Abbreviation Instance Detection

## Overview

The ISMP abbreviation detection queries are designed to identify **all** unapproved abbreviations within a single medication order, scanning across both dose instructions and label comments. Multiple abbreviations are aggregated into a single, comma-separated output field.

## Detection Scope

### Scanned Fields
1. **Dose Instructions** (`FullDoseInstruction`)
   - Multi-line dose instructions from `D_MeditechPHARxDoseInstructions`
   - Aggregated using `STRING_AGG` with line breaks preserved
   
2. **Label Comments** (`FullLabelComment`)
   - Multi-line pharmacist label comments from `F_MeditechPHARxLabelComments`
   - Aggregated using `STRING_AGG` with line breaks preserved

### Detection Mechanism

```sql
CROSS APPLY (
    SELECT STRING_AGG(f.Meaning, ', ') AS Flagged
    FROM Forbidden f
    WHERE
        (f.MatchType = 'CHAR' AND 
         (CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0 OR 
          CHARINDEX(f.Pattern, label.FullLabelComment) > 0))
        OR
        (f.MatchType = 'PAT' AND 
         (PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0 OR 
          PATINDEX(f.Pattern, label.FullLabelComment) > 0))
) flags
```

**Key Components**:
- `STRING_AGG(f.Meaning, ', ')` - Aggregates all matching abbreviations
- Checks **both** dose instructions **OR** label comments
- Single output per order regardless of number of matches

## Detection Examples

### Example 1: Multiple Abbreviations in Dose Instructions

**Dose Instruction**:
```
Give 10U subcutaneously QD
```

**Label Comment**:
```
Store in refrigerator
```

**Flagged Output**:
```
U (Unit), QD (Daily)
```

---

### Example 2: Abbreviations in Both Fields

**Dose Instruction**:
```
Administer .5cc via IV route
```

**Label Comment**:
```
Give @bedtime, D/C if rash occurs
```

**Flagged Output**:
```
Missing leading zero (e.g., .5 mg), cc (Cubic Centimeter), @ (At Symbol), D/C (Discontinue)
```

---

### Example 3: Complex Multi-Line Detection

**Dose Instruction** (multi-line):
```
Line 1: Give 1.0 mg
Line 2: Increase to 2000U if needed
Line 3: Administer >30 min before meal
```

**Label Comment** (multi-line):
```
Line 1: Take OD in morning
Line 2: Follow x/7 schedule
```

**Flagged Output**:
```
Trailing zero (e.g., 1.0 mg), U (Unit), > (Greater Than), OD (Once Daily), x/7 (Days notation)
```

---

### Example 4: Numeric Safety Issues

**Dose Instruction**:
```
Start with .25mg, increase to 0.5 mg, max 1.0 mg
```

**Label Comment**:
```
Titrate carefully
```

**Flagged Output**:
```
Missing leading zero (e.g., .5 mg), Trailing zero (e.g., 1.0 mg)
```

---

### Example 5: Drug Confusion Abbreviations

**Dose Instruction**:
```
Give MS 10mg IV for pain
MSO4 or MgSO4 - clarify with prescriber
```

**Label Comment**:
```
Confirm medication name
```

**Flagged Output**:
```
MS (Morphine or Magnesium Sulfate), MSO4 (Morphine or Magnesium Sulfate), MgSO4 (Magnesium Sulfate)
```

---

### Example 6: Eye/Ear Route Abbreviations

**Dose Instruction**:
```
Instill 2 OS and 1 OD
Apply 3 AD prn
```

**Label Comment**:
```
For ophthalmic use OU
```

**Flagged Output**:
```
OS (Left Eye), OD (Right Eye), AD (Right Ear), OU (Both Eyes)
```

---

### Example 7: Roman Numerals

**Dose Instruction**:
```
Apply Silvadene ii times daily
Increase to iii applications if needed
```

**Label Comment**:
```
For Level I burns only
```

**Flagged Output**:
```
Roman numeral ii (numeric representation), Roman numeral iii (numeric representation)
```

**Note**: "Level I" is NOT flagged (single "I" intentionally excluded to prevent false positives)

---

## Detection Behavior

### Deduplication
The `STRING_AGG` function automatically handles deduplication if the same abbreviation appears multiple times:

**Input**:
```
Dose: "Give 10U in morning and 5U in evening"
Label: "Insulin dosing"
```

**Output**:
```
U (Unit)
```
(Not "U (Unit), U (Unit)")

### Order of Detection
Abbreviations are listed in the order they appear in the `Forbidden` CTE, not in the order they appear in the text:

**Standard Order**:
1. U (Unit)
2. IU (International Unit)
3. µg (Microgram symbol)
4. cc (Cubic Centimeter)
5. ≥, ≤, >, < (Comparison symbols)
6. @ (At Symbol)
7. D/C (Discontinue)
8. OD, QD, QOD, EOD (Frequency)
9. AS, AD, AU (Ear routes)
10. OS, OD, OU (Eye routes)
11. Trailing/Leading zeros
12. MS, MSO4, MgSO4 (Drug confusion)
13. Roman numerals (II, III)
14. Ṫ, ṪṪ, ṪṪṪ (Dot notation)
15. x/7, y/52 (Time notation)
16. D, d (Days/doses)

### Null Handling
If **no** abbreviations are found:
- The `flags.Flagged` field returns `NULL`
- The row is filtered out by `WHERE flags.Flagged IS NOT NULL`
- Order does not appear in results

## Performance Considerations

### Query Optimization
- **Single scan** per order - both fields checked simultaneously
- **Early filtering** - `WHERE flags.Flagged IS NOT NULL` prevents returning clean orders
- **Indexed joins** - Relies on proper indexing of URN and SYSSystemID

### Potential Impact
Scanning both fields increases detection comprehensiveness with minimal performance impact:
- `CHARINDEX` and `PATINDEX` are optimized string functions
- Text fields are aggregated once per order (via CTEs)
- No additional table joins required

## Clinical Workflow Integration

### Prioritization
Orders with multiple flagged abbreviations may indicate:
- Higher patient safety risk
- Need for immediate pharmacy intervention
- Prescriber education opportunity

### Recommended Actions
1. **Review all flagged abbreviations** - Each represents a potential safety risk
2. **Contact prescriber** - Clarify intent for each abbreviation
3. **Document clarification** - Record correct interpretation
4. **Update order** - Replace abbreviations with approved terminology
5. **Track patterns** - Identify prescribers or departments with recurring issues

## False Positive Prevention

### Excluded Contexts
The queries include filters to prevent flagging legitimate clinical usage:

**Medication Names**:
- `Antithrombin III` - Legitimate drug name containing "III"

**Clinical Classifications**:
- `Level II` - Burn/trauma severity classification
- `Level III` - Burn/trauma severity classification

### Intentionally Not Detected
- **Roman numeral I** - Too many false positives in general prose
- **Roman numeral IV** - Valid route of administration (intravenous)

## Statistical Analysis

### Aggregated Metrics
To analyze abbreviation frequency across all orders:

```sql
-- Count total flagged orders
SELECT COUNT(*) AS TotalFlaggedOrders
FROM [query_results]
WHERE [Flagged Abbreviation] IS NOT NULL;

-- Count orders with multiple abbreviations
SELECT COUNT(*) AS MultipleAbbrevOrders
FROM [query_results]
WHERE [Flagged Abbreviation] LIKE '%,%';

-- Most common abbreviations
SELECT 
    value AS Abbreviation,
    COUNT(*) AS Occurrences
FROM [query_results]
CROSS APPLY STRING_SPLIT([Flagged Abbreviation], ',')
GROUP BY value
ORDER BY COUNT(*) DESC;
```

## Limitations

### What Is NOT Detected

1. **Context-dependent abbreviations**
   - Abbreviations that require semantic understanding
   - Abbreviations specific to certain specialties

2. **Typos or variations**
   - Misspelled abbreviations (e.g., "Ud" instead of "U")
   - Non-standard spacing (e.g., "10 U" vs "10U")

3. **Embedded in words**
   - Most patterns require spacing to avoid false positives
   - Example: "bug" does not trigger "ug" detection

4. **Image-based text**
   - Scanned documents or images with text
   - Handwritten abbreviations

## Best Practices

### For Query Users
1. **Review complete context** - Check both dose instructions and label comments
2. **Validate findings** - Confirm each abbreviation is actually unsafe
3. **Trend analysis** - Track abbreviation patterns over time
4. **Provider feedback** - Share results with prescribers for education

### For System Administrators
1. **Schedule regular runs** - Monitor abbreviation usage trends
2. **Set alerts** - Flag high-risk combinations automatically
3. **Export results** - Generate reports for quality improvement committees
4. **Track resolution** - Monitor how quickly flagged orders are corrected

## Updates and Maintenance

### Version History
- **Current**: Multi-field scanning (dose instructions + label comments)
- **Previous**: Single-field scanning (dose instructions only)

### Future Enhancements
Consider adding:
- Severity scoring for multiple abbreviations
- Separate columns for dose vs label detections
- Abbreviation frequency counts within single order
- Machine learning for context-aware detection

## References

- **ISMP Canada Do Not Use List (2025)**: [ismpcanada.ca/do-not-use-list](https://ismpcanada.ca/do-not-use-list)
- **Local Copy**: `ISMPCanadaDoNotUseList-2025.csv`, `ISMP-CDN Docs/ISMPCanadaDoNotUseList-2025-8X11.pdf`
- **Query Analysis**: `ANALYSIS_UNAPPROVED_ABBREVIATIONS.md`
- **Project README**: `README.md`

## Support

For questions or issues:
- Review query logic in `FHA.unapproved_abbrev.sql` or `FHA.patient-order-medication-caadsi.sql`
- Check ISMP official documentation for abbreviation definitions
- Contact FHA Analytics team for technical support
