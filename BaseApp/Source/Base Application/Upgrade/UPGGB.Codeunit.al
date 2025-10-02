#pragma warning disable AA0247
codeunit 104150 "UPG GB"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpgradeIntrastatSetup();
    end;

    local procedure UpgradeIntrastatSetup()
    var
        IntrastatSetup: Record "Intrastat Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateIntrastatSetupTag()) then
            exit;

        if not IntrastatSetup.Get() then
            exit;

        IntrastatSetup."Company VAT No. on File" := IntrastatSetup."Company VAT No. on File"::"VAT Reg. No. Without EU Country Code";
        IntrastatSetup.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateIntrastatSetupTag());
    end;
}

