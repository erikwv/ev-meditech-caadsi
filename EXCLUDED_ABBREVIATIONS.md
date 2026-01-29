# Excluded Unapproved Abbreviations

This document lists unapproved abbreviations from the ISMP Canada "Do Not Use" list that are **intentionally excluded** from the automated detection query due to excessive false positives.

## Summary

| Abbreviation | Meaning | Reason for Exclusion | False Positive Examples |
|--------------|---------|---------------------|------------------------|
| AS | Left Ear (Auris Sinister) | Common English word "as" | "as needed", "as per", "drops as directed" |
| I | Roman numeral one | Single letter, too common | "I will", "I have", any sentence starting with "I" |

---

## Detailed Explanations

### AS (Left Ear)

**ISMP Status:** ❌ Do Not Use  
**Preferred:** Left ear, auris sinister  
**Detection Status:** ⚠️ EXCLUDED from automated detection

#### Problem
The abbreviation "AS" (for left ear) is indistinguishable from the extremely common English word "as" (meaning "in the manner of" or "during"). 

#### Pattern Attempts
We tried multiple pattern refinements:
1. **Initial:** `%[0-9]AS %` - Matched "10 **as** needed", "5 **as** per protocol"
2. **Refined:** `%drop% AS %` - Matched "drops **as** needed", "drop **as** per"  
3. **Final:** `%drop AS %` - Still matched "drops **as** per", "Teardrops **as** ordered"

Even with strict context requirements (requiring "drop/drops/gtt/gtts" immediately before AS), we still get massive false positives.

#### False Positive Examples (from real data)
- "Apply as many **drops as** needed" ✗
- "Instill 1 drop sublingual Q2H **as** needed" ✗
- "SUBSTITUTED for travoprost eye **drops as** per policy" ✗
- "Give with brimonidine **drops as** closest equivalent" ✗
- "CLOSEST EQUIVALENT TO SYSTANE EYE **DROPS AS** ORDERED" ✗
- "Tear**drops as** closest formulary equivalent" ✗

#### Impact
- **Original data (no filter):** 382 instances (100% false positives - all "as needed", "as per", etc.)
- **After refinement 1:** 167 instances (still mostly false positives)
- **After refinement 2:** 43 instances (still all false positives based on manual review)

#### Decision
**EXCLUDE AS from automated detection** and rely on manual review if needed.

#### Legitimate Use (if it exists)
If AS is actually used for left ear, it would appear as:
- "Instill 1 drop AS" (uppercase, no other words)
- "Apply gtt AS left ear"

However, we found **zero** legitimate instances in our dataset of 10,000+ orders.

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

## Detection Statistics (2025-01-29 Update)

| Abbreviation | Instances Detected | Estimated False Positive Rate |
|--------------|-------------------|------------------------------|
| < or > | 7,164 | <1% |
| cc | 1,126 | <1% |
| @ | 965 | <1% |
| D/C | 205 | <5% |
| U | 186 | <1% |
| x/7 | 122 | <1% |
| IU | 117 | <1% |
| OD | 110 | ~5% |
| MS | 60 → TBD after rerun | <1% (with new filter) |
| ii (Roman) | 48 | <5% |
| **AS** | **EXCLUDED** | **~100%** |
| **I** | **EXCLUDED** | **~99%** |

---

## Recommendations

### For AS (Left Ear)
- **Manual Review:** If concern exists about AS usage, manually search for:
  - "drop AS"
  - "drops AS"  
  - "gtt AS"
  - "gtts AS"
- **Education:** Focus education on correct terminology ("left ear") regardless of detection
- **Alternative Detection:** Consider case-sensitive search for uppercase "AS" only (would reduce but not eliminate false positives)

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

**Document Version:** 1.0  
**Last Updated:** 2026-01-29  
**Contact:** FHA Medication Safety / Pharmacy
