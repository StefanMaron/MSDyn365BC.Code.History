codeunit 104015 "Upg Price Calc. Method Setup"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        SetPriceCalcMethodInSetup();
    end;

    local procedure SetPriceCalcMethodInSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        IF UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceCalcMethodInSetupTag()) THEN
            EXIT;

        if SalesReceivablesSetup.Get() then
            if SalesReceivablesSetup."Price Calculation Method" = SalesReceivablesSetup."Price Calculation Method"::" " then begin
                SalesReceivablesSetup."Price Calculation Method" :=
                    SalesReceivablesSetup."Price Calculation Method"::"Lowest Price";
                SalesReceivablesSetup.Modify();
            end;

        if PurchasesPayablesSetup.Get() then
            if PurchasesPayablesSetup."Price Calculation Method" = PurchasesPayablesSetup."Price Calculation Method"::" " then begin
                PurchasesPayablesSetup."Price Calculation Method" :=
                    PurchasesPayablesSetup."Price Calculation Method"::"Lowest Price";
                PurchasesPayablesSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPriceCalcMethodInSetupTag());
    end;
}

