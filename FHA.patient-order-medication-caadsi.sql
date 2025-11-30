-- Combine multi-line label comments and dose instructions
WITH CombinedLabelComments AS (
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

    -- Patient Info
    pat.UnitNumber AS [Account],
    pat.AcctNumber AS [MRN],

    -- Location Info
    site.Mnemonic AS [Site],
    pat.Location AS [Location],

    -- Order Info
    CASE 
        WHEN rx.SYSSystemID = 'MC' THEN 'CS'
        ELSE rx.SYSSystemID
    END AS [System],
    rx.Number AS [Order Number],
    rx.EnterDate AS [Order Entered],
    rx.OrderType AS [Order Type],
    rx.StartDate AS [Order Start],
    rx.StopDate AS [Order Stop],
    rx.Physician AS [Provider],

    -- Medication Info
    drug_main.Mnemonic AS [Drug Mnemonic],
    drug_main5.DrugId AS [Generic Name],
    drug_main.NdcDinNumber AS [DIN],
    med.Dose AS [Dose],
    rd.RangeDoseLow AS [Range Dose Low],
    rd.RangeDoseHigh AS [Range Dose High],
    rx.Schedule,
    drug_main.DispenseUnit AS [Dose Unit],
    drug_main.DispenseForm AS [Dosage Form],
    rx.Route AS [Route],
    rx.Sig AS [Frequency],

    -- Multi-line label comments
    label.FullLabelComment AS [Label Comment],

    -- Multi-line dose instructions
    dose.FullDoseInstruction AS [Dose Instructions],

    -- Flagged abbreviation type (concatenated if multiple)
    CONCAT_WS(', ',
        CASE WHEN dose.FullDoseInstruction LIKE '% U %' OR dose.FullDoseInstruction LIKE '% U/%' THEN 'U (Unit)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '% IU %' OR dose.FullDoseInstruction LIKE '% IU/%' THEN 'IU (International Unit)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%[0-9]ug %' OR dose.FullDoseInstruction LIKE '%[0-9]ug/%' OR 
                  dose.FullDoseInstruction LIKE '% ug %' OR dose.FullDoseInstruction LIKE '% ug/%' THEN 'ug (Microgram)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%[0-9]cc %' OR dose.FullDoseInstruction LIKE '%[0-9]cc/%' OR 
                  dose.FullDoseInstruction LIKE '%[0-9]CC %' OR dose.FullDoseInstruction LIKE '%[0-9]CC/%' OR 
                  dose.FullDoseInstruction LIKE '% cc %' OR dose.FullDoseInstruction LIKE '% cc/%' OR 
                  dose.FullDoseInstruction LIKE '% CC %' OR dose.FullDoseInstruction LIKE '% CC/%' THEN 'cc (Cubic Centimeter)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%<%' AND dose.FullDoseInstruction NOT LIKE '%<=%' THEN '< (Less Than)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%>%' AND dose.FullDoseInstruction NOT LIKE '%>=%' THEN '> (Greater Than)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%≥%' THEN '≥ (Greater Than or Equal)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%≤%' THEN '≤ (Less Than or Equal)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%@%' THEN '@ (At Symbol)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '%D/C%' OR dose.FullDoseInstruction LIKE '%d/c%' THEN 'D/C (Discharge/Discontinue)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '% OD %' OR dose.FullDoseInstruction LIKE '% od %' THEN 'OD (Once Daily)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '% QD %' OR dose.FullDoseInstruction LIKE '% qd %' THEN 'QD (Daily)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '% QOD %' OR dose.FullDoseInstruction LIKE '% qod %' THEN 'QOD (Every Other Day)' END,
        CASE WHEN dose.FullDoseInstruction LIKE '% EOD %' OR dose.FullDoseInstruction LIKE '% eod %' THEN 'EOD (Every Other Day)' END
    ) AS [Flagged Abbreviation]

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain AS rx

-- Patient Join
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain AS pat
    ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatCanadaRecall AS recall
    ON recall.Urn COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT

-- Medication Join
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxInpatientMedications AS med
    ON med.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_main
    ON drug_main.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug_main5
    ON drug_main5.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

-- Range Doses Join
LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxRangeDoses AS rd
    ON rd.Urn COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND rd.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

-- Facility Join
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain AS loc
    ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary AS site
    ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT

-- Label Comments Join
LEFT JOIN CombinedLabelComments AS label
    ON label.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND label.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

-- Dose Instructions Join
LEFT JOIN CombinedDoseInstructions AS dose
    ON dose.URN COLLATE DATABASE_DEFAULT = rx.Urn COLLATE DATABASE_DEFAULT
   AND dose.SYSSystemID COLLATE DATABASE_DEFAULT = rx.SYSSystemID COLLATE DATABASE_DEFAULT

-- Filters
WHERE rx.Sig <> '.STK-MED'
  -- Filter for last calendar year
  AND rx.EnterDate >= DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
  AND rx.EnterDate < DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
-- Filter for unapproved medical abbreviations in Dose Instructions
  AND (
    -- U or IU (unit abbreviations)
    dose.FullDoseInstruction LIKE '% U %' OR
    dose.FullDoseInstruction LIKE '% U/%' OR
    dose.FullDoseInstruction LIKE '% IU %' OR
    dose.FullDoseInstruction LIKE '% IU/%' OR
    
    -- ug (microgram) - must be preceded by number or space, followed by space or slash
    dose.FullDoseInstruction LIKE '%[0-9]ug %' OR
    dose.FullDoseInstruction LIKE '%[0-9]ug/%' OR
    dose.FullDoseInstruction LIKE '% ug %' OR
    dose.FullDoseInstruction LIKE '% ug/%' OR
    
    -- cc (cubic centimeter) - must be preceded by number or space, followed by space or slash
    dose.FullDoseInstruction LIKE '%[0-9]cc %' OR
    dose.FullDoseInstruction LIKE '%[0-9]cc/%' OR
    dose.FullDoseInstruction LIKE '%[0-9]CC %' OR
    dose.FullDoseInstruction LIKE '%[0-9]CC/%' OR
    dose.FullDoseInstruction LIKE '% cc %' OR
    dose.FullDoseInstruction LIKE '% cc/%' OR
    dose.FullDoseInstruction LIKE '% CC %' OR
    dose.FullDoseInstruction LIKE '% CC/%' OR
    
    -- Symbols
    (dose.FullDoseInstruction LIKE '%<%' AND dose.FullDoseInstruction NOT LIKE '%<=%') OR
    (dose.FullDoseInstruction LIKE '%>%' AND dose.FullDoseInstruction NOT LIKE '%>=%') OR
    dose.FullDoseInstruction LIKE '%≥%' OR
    dose.FullDoseInstruction LIKE '%≤%' OR
    dose.FullDoseInstruction LIKE '%@%' OR
    
    -- D/C (discharge/discontinue)
    dose.FullDoseInstruction LIKE '%D/C%' OR
    dose.FullDoseInstruction LIKE '%d/c%' OR
    
    -- Frequency abbreviations
    dose.FullDoseInstruction LIKE '% OD %' OR
    dose.FullDoseInstruction LIKE '% od %' OR
    dose.FullDoseInstruction LIKE '% QD %' OR
    dose.FullDoseInstruction LIKE '% qd %' OR
    dose.FullDoseInstruction LIKE '% QOD %' OR
    dose.FullDoseInstruction LIKE '% qod %' OR
    dose.FullDoseInstruction LIKE '% EOD %' OR
    dose.FullDoseInstruction LIKE '% eod %'
  )
