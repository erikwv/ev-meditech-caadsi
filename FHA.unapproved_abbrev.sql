DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
DECLARE @EndDate   DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);

WITH Forbidden (MatchType, Pattern, Meaning) AS (

    -- Units
    SELECT 'PAT', '%[0-9]U %',  'U (Unit)' UNION ALL
    SELECT 'PAT', '%[0-9] U %', 'U (Unit)' UNION ALL
    SELECT 'PAT', '%[0-9]U/%',  'U (Unit)' UNION ALL
    SELECT 'PAT', '%[0-9] U/%', 'U (Unit)' UNION ALL

    -- International Units
    SELECT 'PAT', '%[0-9]IU %',  'IU (International Unit)' UNION ALL
    SELECT 'PAT', '%[0-9] IU %', 'IU (International Unit)' UNION ALL
    SELECT 'PAT', '%[0-9]IU/%',  'IU (International Unit)' UNION ALL
    SELECT 'PAT', '%[0-9] IU/%', 'IU (International Unit)' UNION ALL

    -- Microgram symbol
    SELECT 'CHAR', NCHAR(181) + 'g', 'µg (Microgram symbol)' UNION ALL

    -- Cubic centimeters
    SELECT 'PAT', '%[0-9]cc %',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] cc %', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]cc/%',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] cc/%', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]CC %',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] CC %', 'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9]CC/%',  'cc (Cubic Centimeter)' UNION ALL
    SELECT 'PAT', '%[0-9] CC/%', 'cc (Cubic Centimeter)' UNION ALL

    -- Comparison symbols
    SELECT 'CHAR', NCHAR(8805), '≥ (Greater Than or Equal)' UNION ALL
    SELECT 'CHAR', NCHAR(8804), '≤ (Less Than or Equal)' UNION ALL
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

    -- Ear abbreviations
    SELECT 'PAT', '%[0-9]AD %',  'AD (Right Ear)' UNION ALL
    SELECT 'PAT', '%[0-9] AD %', 'AD (Right Ear)' UNION ALL
    SELECT 'PAT', '%[0-9]AS %',  'AS (Left Ear)' UNION ALL
    SELECT 'PAT', '%[0-9] AS %', 'AS (Left Ear)' UNION ALL
    SELECT 'PAT', '%[0-9]AU %',  'AU (Both Ears)' UNION ALL
    SELECT 'PAT', '%[0-9] AU %', 'AU (Both Ears)' UNION ALL

    -- Eye abbreviations
    SELECT 'PAT', '%[0-9]OS %',  'OS (Left Eye)' UNION ALL
    SELECT 'PAT', '%[0-9] OS %', 'OS (Left Eye)' UNION ALL
    SELECT 'PAT', '%[0-9]OD %',  'OD (Right Eye)' UNION ALL
    SELECT 'PAT', '%[0-9] OD %', 'OD (Right Eye)' UNION ALL
    SELECT 'PAT', '%[0-9]OU %',  'OU (Both Eyes)' UNION ALL
    SELECT 'PAT', '%[0-9] OU %', 'OU (Both Eyes)' UNION ALL

    -- Trailing / leading zeros
    SELECT 'PAT', '%[0-9]\.0[^0-9]%', 'Trailing zero (e.g., 1.0 mg)' UNION ALL
    SELECT 'PAT', '%[^0-9]\.[0-9]%',  'Missing leading zero (e.g., .5 mg)' UNION ALL

    -- MS abbreviations
    SELECT 'PAT', '%[^A-Za-z]MS[^A-Za-z]%',    'MS (Morphine or Magnesium Sulfate)' UNION ALL
    SELECT 'PAT', '%[^A-Za-z]MSO4[^A-Za-z]%',  'MSO4 (Morphine or Magnesium Sulfate)' UNION ALL
    SELECT 'PAT', '%[^A-Za-z]MgSO4[^A-Za-z]%', 'MgSO4 (Magnesium Sulfate)' UNION ALL

    -- Roman numerals (II / III only)
    SELECT 'PAT', '%[ ]ii[ ][^.]%',  'Roman numeral ii (numeric representation)' UNION ALL
    SELECT 'PAT', '%[ ]II[ ][^.]%',  'Roman numeral II (numeric representation)' UNION ALL
    SELECT 'PAT', '%[ ]iii[ ][^.]%', 'Roman numeral iii (numeric representation)' UNION ALL
    SELECT 'PAT', '%[ ]III[ ][^.]%', 'Roman numeral III (numeric representation)' UNION ALL

    -- Dot / tally notation
    SELECT 'CHAR', NCHAR(7786),                              'Ṫ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7786) + NCHAR(7786),               'ṪṪ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7786) + NCHAR(7786) + NCHAR(7786), 'ṪṪṪ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7787),                              'ṫ (Numeric tally notation)' UNION ALL

    -- Time notation
    SELECT 'PAT', '%[0-9]/7%',  'x/7 (Days notation)' UNION ALL
    SELECT 'PAT', '%[0-9]/52%', 'y/52 (Weeks notation)'
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
    site.Mnemonic AS Site,
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS [System],

    rx.Number        AS [Order Number],
    rx.EnterDate     AS [Order Entered],
    rx.OrderType     AS [Order Type],
    rx.StartDate,
    rx.StopDate,
    rx.Physician     AS [Provider],

    drug_main.Mnemonic     AS [Drug Mnemonic],
    drug_main5.DrugId      AS [Generic Name],
    drug_main.NdcDinNumber AS [DIN],

    med.Dose,
    rd.RangeDoseLow,
    rd.RangeDoseHigh,
    rx.Schedule,

    drug_main.DispenseUnit AS [Dose Unit],
    drug_main.DispenseForm AS [Dosage Form],
    rx.Route,
    rx.Sig                 AS [Frequency],

    label.FullLabelComment   AS [Label Comment],
    dose.FullDoseInstruction AS [Dose Instructions],

    flags.Flagged AS [Flagged Abbreviation],
    flags.FlaggedInDose AS [Flagged in Dose],
    flags.FlaggedInLabel AS [Flagged in Label]

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx

JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatCanadaRecall recall
  ON recall.Urn COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxInpatientMedications med
  ON med.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain drug_main
  ON drug_main.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 drug_main5
  ON drug_main5.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxRangeDoses rd
  ON rd.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
 AND rd.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT

JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT

LEFT JOIN CombinedLabelComments label
  ON label.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
 AND label.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

LEFT JOIN CombinedDoseInstructions dose
  ON dose.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
 AND dose.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

CROSS APPLY (
    SELECT 
        STRING_AGG(DISTINCT Meaning, ', ') WITHIN GROUP (ORDER BY Meaning) AS Flagged,
        STRING_AGG(DISTINCT CASE WHEN InDose = 1 THEN Meaning END, ', ') WITHIN GROUP (ORDER BY Meaning) AS FlaggedInDose,
        STRING_AGG(DISTINCT CASE WHEN InLabel = 1 THEN Meaning END, ', ') WITHIN GROUP (ORDER BY Meaning) AS FlaggedInLabel
    FROM (
        SELECT DISTINCT
            f.Meaning,
            CASE WHEN (f.MatchType = 'CHAR' AND CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0) OR
                      (f.MatchType = 'PAT' AND PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0)
                 THEN 1 ELSE 0 END AS InDose,
            CASE WHEN (f.MatchType = 'CHAR' AND CHARINDEX(f.Pattern, label.FullLabelComment) > 0) OR
                      (f.MatchType = 'PAT' AND PATINDEX(f.Pattern, label.FullLabelComment) > 0)
                 THEN 1 ELSE 0 END AS InLabel
        FROM Forbidden f
        WHERE
            (f.MatchType = 'CHAR' AND 
             (CHARINDEX(f.Pattern, dose.FullDoseInstruction) > 0 OR 
              CHARINDEX(f.Pattern, label.FullLabelComment) > 0))
            OR
            (f.MatchType = 'PAT' AND 
             (PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0 OR 
              PATINDEX(f.Pattern, label.FullLabelComment) > 0))
    ) matches
) flags

WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
  AND flags.Flagged IS NOT NULL
  AND dose.FullDoseInstruction NOT LIKE '%Antithrombin III%'
  AND dose.FullDoseInstruction NOT LIKE '%Level II%'
  AND dose.FullDoseInstruction NOT LIKE '%Level III%';