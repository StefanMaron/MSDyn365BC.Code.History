codeunit 104011 "Upg Advanced Checklist Setup"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        BaseDemoDataSetup();
    end;

    local procedure BaseDemoDataSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        IntraJnlManagement: Codeunit IntraJnlManagement;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetAdvancedIntrastatBaseDemoDataUpgradeTag()) then
            exit;

        IntraJnlManagement.CreateDefaultAdvancedIntrastatSetup();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetAdvancedIntrastatBaseDemoDataUpgradeTag());
    end;
}

