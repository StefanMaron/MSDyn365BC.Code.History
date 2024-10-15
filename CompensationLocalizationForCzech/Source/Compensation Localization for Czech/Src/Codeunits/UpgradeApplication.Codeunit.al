codeunit 31263 "Upgrade Application CZC"
{
    Subtype = Upgrade;

    var
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitionsCZC: Codeunit "Upgrade Tag Definitions CZC";

    trigger OnUpgradePerDatabase()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZC.GetDataVersion180PerDatabaseUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZC.GetDataVersion180PerDatabaseUpgradeTag());
    end;

    trigger OnUpgradePerCompany()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZC.GetDataVersion180PerCompanyUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZC.GetDataVersion180PerCompanyUpgradeTag());
    end;
}
