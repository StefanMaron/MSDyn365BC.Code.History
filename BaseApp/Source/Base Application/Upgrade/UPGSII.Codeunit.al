codeunit 104100 "UPG SII"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateEmployeeNewNames;
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
            Employee.MODIFY;
        UNTIL Employee.NEXT = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateEmployeeNewNamesTag);
    end;
}

