DECLARE @StartDate DATE = DATEFROMPARTS(2025, 1, 1);
DECLARE @EndDate   DATE = DATEFROMPARTS(2026, 1, 1);

-- =============================================================================
-- TOTAL ORDER COUNTS (for accurate percentage denominators)
-- =============================================================================

-- Counts by Site and System
SELECT 
    site.Mnemonic AS Site,
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS [System],
    COUNT(DISTINCT rx.Urn) AS TotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
GROUP BY 
    site.Mnemonic,
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END
ORDER BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END,
    site.Mnemonic;

-- Counts by System only
SELECT 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END AS [System],
    COUNT(DISTINCT rx.Urn) AS TotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate
GROUP BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END
ORDER BY 
    CASE WHEN rx.SYSSystemID = 'MC' THEN 'CS' ELSE rx.SYSSystemID END;

-- Grand Total
SELECT 
    COUNT(DISTINCT rx.Urn) AS GrandTotalOrders
FROM FHA_ANALYTICS.FHA.F_MeditechPHARxMain rx
JOIN FHA_ANALYTICS.FHA.F_MeditechADMPatMain pat
  ON rx.Patient COLLATE DATABASE_DEFAULT = pat.Urn COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechMISLocnMain loc
  ON loc.Mnemonic COLLATE DATABASE_DEFAULT = pat.Location COLLATE DATABASE_DEFAULT
JOIN FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary site
  ON site.Mnemonic COLLATE DATABASE_DEFAULT = loc.OeSite COLLATE DATABASE_DEFAULT
WHERE rx.Sig <> '.STK-MED'
  AND rx.EnterDate >= @StartDate
  AND rx.EnterDate <  @EndDate;
