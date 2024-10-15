codeunit 104151 "ISO Code UPG.BE"
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
         
        MoveCurrencyISOCode;
        UpdateCountyName;
    end;

    local procedure MoveCurrencyISOCode()
    var
        Currency: Record "Currency";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag) THEN
            EXIT;

        WITH Currency DO BEGIN
            SETFILTER("ISO Currency Code", '<>%1', '');
            IF FindSet() then
                REPEAT
                    "ISO Code" := "ISO Currency Code";
                    Modify();
                UNTIL Next() = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag);
    end;

    local procedure UpdateCountyName()
    var
        CountryRegion: Record "Country/Region";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag) THEN
            EXIT;

        WITH CountryRegion DO BEGIN
            SETFILTER("ISO Country/Region Code", '<>%1', '');
            IF FindSet() then
                REPEAT
                    "ISO Code" := "ISO Country/Region Code";
                    Modify();
                UNTIL Next() = 0;
        END;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag);
    end;
}

