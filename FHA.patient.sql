SELECT
    pat.Urn AS patient_urn,
    pat.UnitNumber AS patient_id,
    pat.AcctNumber AS encounter_num,
    pat.Name AS name_full,
    pat.Status AS status,
    recall.HealthCareNumber AS phn,
    pat.Birthdate AS dob,
    pat.Sex,
    pat.Location AS medical_unit,
    pat.AdmitDate AS admit_date,
    pat.AdmitTime AS admit_time,
    pat.AdmitDateTime AS admit_datetime,
    room.Service,
    pat.DischargeDate AS discharge_date,
    pat.DischargeTime AS discharge_time,
    pat.DischargeDateTime AS discharge_datetime,
    room.Location AS nurse_unit
FROM FHA_ANALYTICS.FHA.F_MeditechADMPatMain AS pat
INNER JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatCanadaRecall AS recall ON recall.Urn = pat.Urn
INNER JOIN FHA_ANALYTICS.FHA.D_MeditechMISRoomMain AS room ON room.Location = pat.Location;