SELECT TOP 500

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
    drug_main.DispenseUnit AS [Dose Unit],
    drug_main.DispenseForm AS [Dosage Form],
    rx.Route AS [Route],
    rx.Sig AS [Frequency]

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