SELECT
    rx.Physician AS prescriber_mnemonic,
    doc.Name AS prescriber_full_name,
    doc.Active AS provider_active,
    doc.DrType AS college_type,
    doc.Service AS provider_service,
    doc.Number AS provider_college_id,
    doc.LicenseNumber AS provider_msp
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain AS rx
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISDocMain AS doc ON doc.Mnemonic = rx.Physician COLLATE DATABASE_DEFAULT;