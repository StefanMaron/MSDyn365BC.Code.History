codeunit 104102 "Upg No Taxable"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateNoTaxableEntries;
    end;

    local procedure UpdateNoTaxableEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesTag) THEN
            EXIT;

        CODEUNIT.RUN(CODEUNIT::"No Taxable - Generate Entries");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateNoTaxableEntriesTag);
    end;
}

