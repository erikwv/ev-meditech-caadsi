WITH Forbidden (MatchType, Pattern, Meaning) AS (

    -- Dot / tally numeric notation (ISMP)
    SELECT 'CHAR', NCHAR(7786),                              'Ṫ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7786) + NCHAR(7786),               'ṪṪ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7786) + NCHAR(7786) + NCHAR(7786), 'ṪṪṪ (Numeric tally notation)' UNION ALL
    SELECT 'CHAR', NCHAR(7787),                              'ṫ (Numeric tally notation)' UNION ALL

    -- Eye abbreviations (OS / OD / OU) – numeric context only
    SELECT 'PAT', '%[0-9]OS %',  'OS (Left Eye)' UNION ALL
    SELECT 'PAT', '%[0-9] OS %', 'OS (Left Eye)' UNION ALL

    SELECT 'PAT', '%[0-9]OD %',  'OD (Right Eye)' UNION ALL
    SELECT 'PAT', '%[0-9] OD %', 'OD (Right Eye)' UNION ALL

    SELECT 'PAT', '%[0-9]OU %',  'OU (Both Eyes)' UNION ALL
    SELECT 'PAT', '%[0-9] OU %', 'OU (Both Eyes)' UNION ALL

    -- Time notation (x/7, y/52)
    SELECT 'PAT', '%[0-9]/7%',  'x/7 (Days notation)' UNION ALL
    SELECT 'PAT', '%[0-9]/52%', 'y/52 (Weeks notation)' UNION ALL

    -- D / d as days or doses (numeric context only)
    SELECT 'PAT', '%[0-9]D %', 'D (Days/Doses)' UNION ALL
    SELECT 'PAT', '%[0-9]d %', 'd (Days/Doses)'
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
    rx.Number AS [Order Number],
    rx.EnterDate AS [Order Entered],
    dose.FullDoseInstruction AS [Dose Instructions],
    flags.Flagged AS [Flagged ISMP Item]

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx

INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
    ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
    ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT

INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
    ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT

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