codeunit 104151 "ISO Code UPG.CH"
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
}

