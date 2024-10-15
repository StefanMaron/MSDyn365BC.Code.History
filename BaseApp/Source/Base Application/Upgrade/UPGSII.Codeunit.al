codeunit 104100 "UPG SII"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateEmployeeNewNames;
        UpdateSchemasInSIISetup();
    end;

    local procedure UpdateEmployeeNewNames()
    var
        Employee: Record "Employee";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateEmployeeNewNamesTag) THEN
            EXIT;

        IF NOT Employee.FINDSET THEN
            EXIT;

        REPEAT
            Employee.UpdateNamesFromOldFields;
            Employee.Modify();
        UNTIL Employee.NEXT = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateEmployeeNewNamesTag);
    end;

    local procedure UpdateSchemasInSIISetup()
    var
        SIISetup: Record "SII Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateSIISetupSchemasTag()) THEN
            EXIT;

        if SIISetup.Get() then
            SIISetup.SetDefaults();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateSIISetupSchemasTag());
    end;

}

