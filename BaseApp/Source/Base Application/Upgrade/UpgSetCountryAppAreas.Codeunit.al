codeunit 104010 "UPG Set Country App Areas"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        SetCountryAppAreas;
    end;

    local procedure SetCountryAppAreas()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag) THEN
            EXIT;

        IF ApplicationAreaSetup.GET AND ApplicationAreaSetup.Basic THEN BEGIN
            ApplicationAreaSetup.VAT := TRUE;
            ApplicationAreaSetup."Basic IS" := TRUE;
            ApplicationAreaSetup.Modify();
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCountryApplicationAreasTag);
    end;
}

