WITH Forbidden (MatchType, Pattern, Meaning) AS (
	-- Roman numerals as numeric representations (ISMP refined, excluding I)
	SELECT 'PAT', '%[ ]ii[ ][^.]%',  'Roman numeral ii (numeric representation)' UNION ALL
	SELECT 'PAT', '%[ ]II[ ][^.]%',  'Roman numeral II (numeric representation)' UNION ALL
	SELECT 'PAT', '%[ ]iii[ ][^.]%', 'Roman numeral iii (numeric representation)' UNION ALL
	SELECT 'PAT', '%[ ]III[ ][^.]%', 'Roman numeral III (numeric representation)'
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

SELECT TOP 1000
    pat.UnitNumber AS Account,
    pat.AcctNumber AS MRN,
    site.Mnemonic AS Site,
    pat.Location AS Location,
    rx.Number AS [Order Number],
    rx.EnterDate AS [Order Entered],
    dose.FullDoseInstruction AS [Dose Instructions],
    flags.Flagged AS [Flagged Roman Numeral]

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
    WHERE PATINDEX(f.Pattern, dose.FullDoseInstruction) > 0
      AND dose.FullDoseInstruction NOT LIKE '%Level II%'
      AND dose.FullDoseInstruction NOT LIKE '%Level III%'
) flags

WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
  AND rx.EnterDate <  DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
  AND flags.Flagged IS NOT NULL;