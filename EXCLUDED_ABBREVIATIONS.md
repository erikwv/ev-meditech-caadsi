# Excluded Unapproved Abbreviations

This document lists unapproved abbreviations from the ISMP Canada "Do Not Use" list that are **intentionally excluded** from the automated detection query due to excessive false positives.

## Summary

| Abbreviation | Meaning | Status | Notes |
|--------------|---------|--------|-------|
| AS | Left Ear (Auris Sinister) | ✅ INCLUDED (with filtering) | Filters out "as needed" patterns |
| I | Roman numeral one | ❌ EXCLUDED | Single letter, too common in prose |

---

## Detailed Explanations

### AS (Left Ear)

**ISMP Status:** ❌ Do Not Use  
**Preferred:** Left ear, auris sinister  
**Detection Status:** ✅ INCLUDED (as of 2026-02-02) with filtering

#### Problem
The abbreviation "AS" (for left ear) is indistinguishable from the extremely common English word "as" (meaning "in the manner of" or "during"). The primary false positive is "as needed" in various forms.

#### Solution Implemented (2026-02-02)
AS detection is now **INCLUDED** with the following approach:
1. **Pattern:** Requires drop/drops/gtt/gtts context: `%drop AS %`, `%drops AS %`, `%gtt AS %`, `%gtts AS %`
2. **Filtering:** Excludes all orders containing common "as" phrases (case-insensitive variations):
   - `%as needed%` (all case variations)
   - `%as ordered%` (all case variations)
   - `%as per%` (all case variations)
   - `%as closest%` (all case variations)

#### Rationale
The vast majority of false positives are "as needed" phrases. By filtering these out, we can capture legitimate AS usage while eliminating the most common false positive pattern.

#### False Positive Examples (filtered out)
- "Apply as many **drops as** needed" ✗ (filtered by "as needed")
- "Instill 1 drop sublingual Q2H **as** needed" ✗ (filtered by "as needed")
- "SUBSTITUTED for travoprost eye **drops as** per policy" ✓ (may still be detected - requires monitoring)
- "Give with brimonidine **drops as** closest equivalent" ✓ (may still be detected - requires monitoring)

#### Legitimate Use
If AS is actually used for left ear, it would appear as:
- "Instill 1 drop AS" ✓ (would be detected)
- "Apply gtt AS left ear" ✓ (would be detected)
- "2 drops AS TID" ✓ (would be detected)

---

### I (Roman Numeral One)

**ISMP Status:** ❌ Do Not Use (Roman numerals for drug names/dosages)  
**Preferred:** Use numeric "1" instead of "I"  
**Detection Status:** ⚠️ EXCLUDED from automated detection

#### Problem
The Roman numeral "I" is indistinguishable from:
- The first-person pronoun "I"
- The letter "I" in any word or acronym
- Tab/spacing characters in some systems

#### Pattern Challenges
Any pattern to detect "I" would require extremely complex context:
- Can't use `% I %` - matches every sentence with "I" 
- Can't use `%[0-9] I %` - matches "Type 1 Insulin" (intended usage)
- Can't reliably distinguish Roman numeral from other uses

#### False Positive Risk
- Extremely high - "I" appears in almost every text field
- Would generate thousands of false positives
- No practical pattern exists to isolate Roman numeral usage

#### Decision
**EXCLUDE Roman numeral I** from automated detection. 

**Note:** Roman numerals II and III are included in detection as they have fewer false positives.

---

## Included But Monitored

### OD (Once Daily / Right Eye)

**Status:** ✅ INCLUDED but requires monitoring

OD is included because:
- When used for dosing frequency, it's surrounded by spaces: " OD "
- Pattern ` OD ` has low false positive rate
- Also catches OD (Right Eye) which has similar pattern

However, may occasionally match:
- "METH**OD** " (false positive if embedded in words)

Monitor for false positives in future updates.

---

## MS (Morphine Sulfate / Magnesium Sulfate)

**ISMP Status:** ❌ Do Not Use  
**Preferred:** Morphine sulfate, magnesium sulfate (spell out)  
**Detection Status:** ✅ INCLUDED with filtering

### Filtering Applied (2026-01-29)

**Problem:** MS has two common false positive patterns:
1. **Milliseconds:** "500 ms", "500 MS", "QTC > 500ms"
2. **MS Trial:** Clinical trial references like "MS Trial", "MS trial"

**Solution:** Pattern now requires:
- A mass measurement unit (mg, g, gm, mcg) immediately before MS
- Proper spacing: `mg MS ` (with space after MS)

**Examples:**
- ✅ True Positive: "20mg MS PO", "10 mg MS IV"
- ❌ False Positive (filtered): "500 ms", "QTC > 500ms", "MS Trial"

**Pattern Used:**
```sql
SELECT 'PAT', '%mg MS %',    'MS (Morphine or Magnesium Sulfate)'
SELECT 'PAT', '%g MS %',     'MS (Morphine or Magnesium Sulfate)'
SELECT 'PAT', '%gm MS %',    'MS (Morphine or Magnesium Sulfate)'
SELECT 'PAT', '%mcg MS %',   'MS (Morphine or Magnesium Sulfate)'
```

---

## Detection Statistics

| Abbreviation | Instances Detected | Estimated False Positive Rate | Notes |
|--------------|-------------------|------------------------------|-------|
| < or > | 7,164 | <1% | 2025 data |
| cc | 1,126 | <1% | 2025 data |
| @ | 965 | <1% | 2025 data |
| D/C | 205 | <5% | 2025 data |
| U | 186 | <1% | 2025 data |
| x/7 | 122 | <1% | 2025 data |
| IU | 117 | <1% | 2025 data |
| OD | 110 | ~5% | 2025 data |
| MS | ~60 | <1% | With filtering (2025 data) |
| ii (Roman) | 48 | <5% | 2025 data |
| **AS** | **TBD** | **<10% (estimated)** | **ADDED 2026-02-02 with "as needed" filter** |
| **I** | **EXCLUDED** | **~99%** | Still excluded |

---

## Recommendations

### For AS (Left Ear)
- **Monitor Results:** AS detection is now active with "as needed" filtering. Monitor initial results for:
  - Remaining false positive rate
  - Detection of legitimate AS usage
  - Need for additional filtering patterns (e.g., "as per", "as directed")
- **Education:** Focus education on correct terminology ("left ear") regardless of detection accuracy
- **Further Refinement:** If false positive rate remains high, consider additional filters:
  - "as per"
  - "as directed"
  - "as ordered"

### For Roman Numeral I
- **Manual Review:** Search for specific drug names known to use Roman numerals (e.g., "Coagulation Factor I")
- **Education:** Include in staff training even without automated detection
- **Focus on II/III:** These ARE detected and can serve as indicators that Roman numerals are being used

---

## Future Considerations

### Potential Improvements
1. **Machine Learning:** Use NLP/ML to understand context better
2. **Case Sensitivity:** Require uppercase AS/AD/AU (may still have issues)
3. **Drug-Specific Rules:** Create patterns specific to known drug names
4. **Manual Spot Checks:** Periodic manual review of excluded abbreviations

### Re-evaluation Criteria
Consider re-including AS if:
- False positive rate drops below 10%
- Technical improvements enable better context detection
- Actual AS usage is identified through other means

---

## References

- ISMP Canada "Do Not Use" Abbreviations List (2023)
- FHA Medication Safety Committee Guidelines
- Analysis conducted: January 2026
- Dataset: 10,000+ medication orders (Jan 2025)

---

**Document Version:** 1.1  
**Last Updated:** 2026-02-02  
**Updates:** 
- Added AS (Left Ear) detection with "as needed" filtering
- Changed AS status from EXCLUDED to INCLUDED

**Contact:** FHA Medication Safety / Pharmacy
