SELECT
    site.Mnemonic AS site_mnemonic,
    site.Name AS site_name,
    site.Active AS site_active,
    site.Address1 AS street,
    site.City AS city,
    site.State AS province,
    site.PostalCode AS postal_code,
    site.Phone AS phone
FROM FHA_ANALYTICS.FHA.D_MeditechPHASiteDictionary AS site;