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

        MoveCurrencyISOCode();
        UpdateCountyName();
    end;

    local procedure MoveCurrencyISOCode()
    var
        Currency: Record "Currency";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag()) then
            exit;

        Currency.SetFilter("ISO Currency Code", '<>%1', '');
        if Currency.FindSet() then
            repeat
                Currency."ISO Code" := Currency."ISO Currency Code";
                Currency.Modify();
            until Currency.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetMoveCurrencyISOCodeTag());
    end;

    local procedure UpdateCountyName()
    var
        CountryRegion: Record "Country/Region";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag()) then
            exit;

        CountryRegion.SetFilter("ISO Country/Region Code", '<>%1', '');
        if CountryRegion.FindSet() then
            repeat
                CountryRegion."ISO Code" := CountryRegion."ISO Country/Region Code";
                CountryRegion.Modify();
            until CountryRegion.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag());
    end;
}

