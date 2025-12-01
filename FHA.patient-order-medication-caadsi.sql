-- Combine multi-line label comments and dose instructions
WITH Forbidden AS (
    -- Units
    SELECT ' U '  AS Pattern, 'U (Unit)' AS Meaning UNION ALL
    SELECT ' U/' , 'U (Unit)' UNION ALL
    
    -- International Units
    SELECT ' IU ', 'IU (International Unit)' UNION ALL
    SELECT ' IU/', 'IU (International Unit)' UNION ALL

    -- Micrograms (must follow a digit)
    SELECT '0ug ', 'ug (Microgram)' UNION ALL
    SELECT '1ug ', 'ug (Microgram)' UNION ALL
    SELECT '2ug ', 'ug (Microgram)' UNION ALL
    SELECT '3ug ', 'ug (Microgram)' UNION ALL
    SELECT '4ug ', 'ug (Microgram)' UNION ALL
    SELECT '5ug ', 'ug (Microgram)' UNION ALL
    SELECT '6ug ', 'ug (Microgram)' UNION ALL
    SELECT '7ug ', 'ug (Microgram)' UNION ALL
    SELECT '8ug ', 'ug (Microgram)' UNION ALL
    SELECT '9ug ', 'ug (Microgram)' UNION ALL
    SELECT '0ug/', 'ug (Microgram)' UNION ALL
    SELECT '1ug/', 'ug (Microgram)' UNION ALL
    SELECT '2ug/', 'ug (Microgram)' UNION ALL
    SELECT '3ug/', 'ug (Microgram)' UNION ALL
    SELECT '4ug/', 'ug (Microgram)' UNION ALL
    SELECT '5ug/', 'ug (Microgram)' UNION ALL
    SELECT '6ug/', 'ug (Microgram)' UNION ALL
    SELECT '7ug/', 'ug (Microgram)' UNION ALL
    SELECT '8ug/', 'ug (Microgram)' UNION ALL
    SELECT '9ug/', 'ug (Microgram)' UNION ALL

    -- Cubic centimeters (must follow a digit)
    SELECT '0cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '1cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '2cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '3cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '4cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '5cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '6cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '7cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '8cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '9cc ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '0cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '1cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '2cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '3cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '4cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '5cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '6cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '7cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '8cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '9cc/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '0CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '1CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '2CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '3CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '4CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '5CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '6CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '7CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '8CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '9CC ', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '0CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '1CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '2CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '3CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '4CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '5CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '6CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '7CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '8CC/', 'cc (Cubic Centimeter)' UNION ALL
    SELECT '9CC/', 'cc (Cubic Centimeter)' UNION ALL

    -- Unicode symbols (exact binary match via codepoints)
    SELECT NCHAR(8805), '≥ (Greater Than or Equal)' UNION ALL   -- ≥
    SELECT NCHAR(8804), '≤ (Less Than or Equal)' UNION ALL      -- ≤

    -- Symbol
    SELECT '@', '@ (At Symbol)' UNION ALL

    -- Discontinue
    SELECT 'D/C', 'D/C (Discontinue)' UNION ALL
    SELECT 'd/c', 'D/C (Discontinue)' UNION ALL

    -- Frequency abbreviations
    SELECT ' OD ',  'OD (Once Daily)' UNION ALL
    SELECT ' od ',  'OD (Once Daily)' UNION ALL
    SELECT ' QD ',  'QD (Daily)' UNION ALL
    SELECT ' qd ',  'QD (Daily)' UNION ALL
    SELECT ' QOD ', 'QOD (Every Other Day)' UNION ALL
    SELECT ' qod ', 'QOD (Every Other Day)' UNION ALL
    SELECT ' EOD ', 'EOD (Every Other Day)' UNION ALL
    SELECT ' eod ', 'EOD (Every Other Day)'
),

CombinedLabelComments AS (
    SELECT 
        URN,
        SYSSystemID,
        STRING_AGG(LabelComment, CHAR(10)) 
            WITHIN GROUP (ORDER BY LabelCommentQ) AS FullLabelComment
    FROM FHA_ANALYTICS.FHA.F_MeditechPHARxLabelComments
    GROUP BY URN, SYSSystemID
),
CombinedDoseInstructions AS (
    SELECT 
        URN,
        SYSSystemID,
        STRING_AGG(DoseInstruction, CHAR(10)) 
            WITHIN GROUP (ORDER BY DoseInstructionQ) AS FullDoseInstruction
    FROM FHA_ANALYTICS.FHA.D_MeditechPHARxDoseInstructions
    GROUP BY URN, SYSSystemID
)

SELECT TOP 100
    pat.UnitNumber AS Account,
    pat.AcctNumber AS MRN,
    site.Mnemonic AS Site,
    pat.Location AS Location,

    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS System,

    rx.Number AS [Order Number],
    rx.EnterDate AS [Order Entered],
    rx.OrderType,
    rx.StartDate,
    rx.StopDate,
    rx.Physician AS Provider,

    drug_main.Mnemonic AS [Drug Mnemonic],
    drug_main5.DrugId AS [Generic Name],
    drug_main.NdcDinNumber AS DIN,
    med.Dose,
    rd.RangeDoseLow,
    rd.RangeDoseHigh,
    rx.Schedule,
    drug_main.DispenseUnit AS [Dose Unit],
    drug_main.DispenseForm AS [Dosage Form],
    rx.Route,
    rx.Sig AS Frequency,

    label.FullLabelComment AS [Label Comment],
    dose.FullDoseInstruction AS [Dose Instructions],

    flags.Flagged AS [Flagged Abbreviation]

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx

INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
    ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatCanadaRecall recall
    ON recall.Urn COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxInpatientMedications med
    ON med.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain drug_main
    ON drug_main.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 drug_main5
    ON drug_main5.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxRangeDoses rd
    ON rd.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND rd.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
    ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
    ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT

LEFT JOIN CombinedLabelComments label
    ON label.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND label.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

-- Dose Instructions Join
LEFT JOIN CombinedDoseInstructions dose
    ON dose.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND dose.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

CROSS APPLY (
    SELECT STRING_AGG(f.Meaning, ', ') AS Flagged
    FROM Forbidden f
    WHERE CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0
) flags

WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
  AND rx.EnterDate <  DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
  AND flags.Flagged IS NOT NULL;
