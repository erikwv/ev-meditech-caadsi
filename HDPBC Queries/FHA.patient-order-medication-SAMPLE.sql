SELECT
    -- Patient Info
    pat.Urn AS patient_urn,
    pat.UnitNumber AS patient_id,
    pat.AcctNumber AS encounter_num,
    pat.Name AS name_full,
    pat.Status AS patient_status,
    recall.HealthCareNumber AS phn,
    pat.Birthdate AS dob,
    pat.Sex,
    pat.AdmitDate AS admit_date,
    pat.AdmitTime AS admit_time,
    pat.DischargeDate AS discharge_date,
    pat.DischargeTime AS discharge_time,
    pat.Location AS medical_unit,

    -- Order Info
    rx.SYSSystemID AS system_id,
    rx.Number AS order_id,
    rx.EnterDate AS enter_date,
    rx.StartDate AS order_start_dt,
    rx.StopDate AS order_stop_dt,
    rx.Status AS order_status,
    rx.OrderType AS order_type,
    rx.TotalDoses AS total_doses,
    rx.Route AS route,
    rx.Sig AS frequency,

    -- Medication Info
    med.Med AS product_mnemonic,
    drug_main5.DrugId AS generic_name,
    drug_main.Mnemonic AS drug_mnemonic,
    drug_main.NdcDinNumber AS din,
    med.Dose AS strength_dose,
    drug_main.DispenseUnit AS strength_dose_unit,
    drug_main.DispenseForm AS dosage_form,
    drug_main.DispenseSize AS main_disp_size,
    med.Volume AS volume_dose,

    -- Range Dose Info
    rd.RangeDoseLow,
    rd.RangeDoseHigh,

    -- Facility Info
    site.Mnemonic AS site_mnemonic,
    site.Name AS site_name

FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain AS rx

-- Patient Join
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain AS pat
    ON rx.Patient = pat.Urn
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatCanadaRecall AS recall
    ON recall.Urn = pat.Urn

-- Medication Join
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxInpatientMedications AS med
    ON med.Urn = rx.Urn
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain AS drug_main
    ON drug_main.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHADrugMain5 AS drug_main5
    ON drug_main5.Mnemonic COLLATE DATABASE_DEFAULT = med.Med COLLATE DATABASE_DEFAULT

-- Range Doses Join
LEFT JOIN FHA_ANALYTICS.FHA.F_MeditechPHARxRangeDoses AS rd
    ON rd.Urn = rx.Urn
   AND rd.SYSSystemID = rx.SYSSystemID

-- Facility Join
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain AS loc
    ON loc.Mnemonic = pat.Location
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary AS site
    ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT

WHERE rx.EnterDate >= '20170101' 
  AND rx.EnterDate < '20170201'
  AND rx.SYSSystemID LIKE 'MC';
