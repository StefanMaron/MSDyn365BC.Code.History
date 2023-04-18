codeunit 104050 "Upg Load Named Forward Links"
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

        LoadForwardLinks();
    end;

    local procedure LoadForwardLinks()
    var
        NamedForwardLink: Record "Named Forward Link";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetLoadNamedForwardLinksUpgradeTag()) THEN
            exit;

        NamedForwardLink.Load();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetLoadNamedForwardLinksUpgradeTag());
    end;
}