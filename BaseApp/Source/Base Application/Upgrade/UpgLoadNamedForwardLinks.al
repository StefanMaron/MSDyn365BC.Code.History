codeunit 104050 "Upg Load Named Forward Links"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
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

