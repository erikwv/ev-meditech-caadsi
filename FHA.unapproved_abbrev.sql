WITH Forbidden AS (
    -- MatchType = 'CHAR' means literal match via CHARINDEX
    -- MatchType = 'PAT'  means pattern match via PATINDEX (supports [0-9], etc.)

    -- Units (U) must follow a number or number+space, and be followed by space or slash
    SELECT 'PAT' AS MatchType, '%[0-9]U %'  AS Pattern, 'U (Unit)' AS Meaning UNION ALL
    SELECT 'PAT',               '%[0-9] U %',            'U (Unit)' UNION ALL
    SELECT 'PAT',               '%[0-9]U/%',             'U (Unit)' UNION ALL
    SELECT 'PAT',               '%[0-9] U/%',            'U (Unit)' UNION ALL

    -- International Units (IU) must follow a number or number+space, and be followed by space or slash
	SELECT 'PAT', '%[0-9]IU %',  'IU (International Unit)' UNION ALL
	SELECT 'PAT', '%[0-9] IU %', 'IU (International Unit)' UNION ALL
	SELECT 'PAT', '%[0-9]IU/%',  'IU (International Unit)' UNION ALL
	SELECT 'PAT', '%[0-9] IU/%', 'IU (International Unit)' UNION ALL

    -- Microgram symbol (µg)
	SELECT 'CHAR', NCHAR(181) + 'g', 'µg (Microgram symbol)' UNION ALL

    -- Cubic centimeters (cc) must follow a number or number+space, and be followed by space or slash
    SELECT 'PAT', '%[0-9]cc %',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] cc %', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]cc/%',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] cc/%', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]CC %',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] CC %', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]CC/%',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] CC/%', 'cc (Cubic Centimeter)' UNION ALL

    -- Unicode symbols (use NCHAR to prevent "=" confusion)
    SELECT 'CHAR', NCHAR(8805), '≥ (Greater Than or Equal)' UNION ALL
    SELECT 'CHAR', NCHAR(8804), '≤ (Less Than or Equal)' UNION ALL

    -- ASCII comparison symbols
    SELECT 'CHAR', '>', '> (Greater Than)' UNION ALL
    SELECT 'CHAR', '<', '< (Less Than)' UNION ALL

    -- Symbol
    SELECT 'CHAR', '@', '@ (At Symbol)' UNION ALL

    -- Discontinue
    SELECT 'CHAR', 'D/C', 'D/C (Discontinue)' UNION ALL
    SELECT 'CHAR', 'd/c', 'D/C (Discontinue)' UNION ALL

    -- Frequency abbreviations
    SELECT 'CHAR', ' OD ',  'OD (Once Daily)' UNION ALL
    SELECT 'CHAR', ' od ',  'OD (Once Daily)' UNION ALL
    SELECT 'CHAR', ' QD ',  'QD (Daily)' UNION ALL
    SELECT 'CHAR', ' qd ',  'QD (Daily)' UNION ALL
    SELECT 'CHAR', ' QOD ', 'QOD (Every Other Day)' UNION ALL
    SELECT 'CHAR', ' qod ', 'QOD (Every Other Day)' UNION ALL
    SELECT 'CHAR', ' EOD ', 'EOD (Every Other Day)' UNION ALL
    SELECT 'CHAR', ' eod ', 'EOD (Every Other Day)' UNION ALL

    -- Unsafe ear abbreviations (must follow a number or number+space, and have a space after)
    SELECT 'PAT', '%[0-9]AD %',  'AD (Right Ear)' UNION ALL
    SELECT 'PAT', '%[0-9] AD %', 'AD (Right Ear)' UNION ALL
    SELECT 'PAT', '%[0-9]AS %',  'AS (Left Ear)' UNION ALL
    SELECT 'PAT', '%[0-9] AS %', 'AS (Left Ear)' UNION ALL
    SELECT 'PAT', '%[0-9]AU %',  'AU (Both Ears)' UNION ALL
    SELECT 'PAT', '%[0-9] AU %', 'AU (Both Ears)' UNION ALL

	-- Trailing zero (e.g. 1.0 mg)
	SELECT 'PAT', '%[0-9]\.0[^0-9]%', 'Trailing zero (e.g., 1.0 mg)' UNION ALL

	-- Missing leading zero (e.g. .5 mg)
	SELECT 'PAT', '%[^0-9]\.[0-9]%', 'Missing leading zero (e.g., .5 mg)' UNION ALL

	-- Roman numerals as numeric representations (ISMP – general token case)
	SELECT 'PAT', '%[^A-Za-z]i[^A-Za-z]%',   'Roman numeral i (numeric representation)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]I[^A-Za-z]%',   'Roman numeral I (numeric representation)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]ii[^A-Za-z]%',  'Roman numeral ii (numeric representation)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]II[^A-Za-z]%',  'Roman numeral II (numeric representation)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]iii[^A-Za-z]%', 'Roman numeral iii (numeric representation)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]III[^A-Za-z]%', 'Roman numeral III (numeric representation)' UNION ALL

	-- MS / MSO4 / MgSO4 (morphine vs magnesium sulfate)
	SELECT 'PAT', '%[^A-Za-z]MS[^A-Za-z]%',    'MS (Morphine or Magnesium Sulfate)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]MSO4[^A-Za-z]%',  'MSO4 (Morphine or Magnesium Sulfate)' UNION ALL
	SELECT 'PAT', '%[^A-Za-z]MgSO4[^A-Za-z]%', 'MgSO4 (Magnesium Sulfate)'
),

CombinedLabelComments AS (
    SELECT 
        URN,
        SYSSystemID,
        STRING_AGG(LabelComment, CHAR(10)) WITHIN GROUP (ORDER BY LabelCommentQ) AS FullLabelComment
    FROM FHA_ANALYTICS.FHA.F_MeditechPHARxLabelComments
    GROUP BY URN, SYSSystemID
),

CombinedDoseInstructions AS (
    SELECT 
        URN,
        SYSSystemID,
        STRING_AGG(DoseInstruction, CHAR(10)) WITHIN GROUP (ORDER BY DoseInstructionQ) AS FullDoseInstruction
    FROM FHA_ANALYTICS.FHA.D_MeditechPHARxDoseInstructions
    GROUP BY URN, SYSSystemID
)

SELECT TOP 1000
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

LEFT JOIN CombinedDoseInstructions dose
    ON dose.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND dose.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

CROSS APPLY (
    SELECT STRING_AGG(f.Meaning, ', ') AS Flagged
    FROM Forbidden f
    WHERE
        (f.MatchType = 'CHAR' AND CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0)
        OR
        (f.MatchType = 'PAT'  AND PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0)
) flags

WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
  AND rx.EnterDate <  DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
  AND flags.Flagged IS NOT NULL;