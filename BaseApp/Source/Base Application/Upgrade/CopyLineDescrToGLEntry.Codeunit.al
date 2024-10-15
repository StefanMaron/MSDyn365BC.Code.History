codeunit 104152 "Copy Line Descr. To G/L Entry"
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

        SetCopyLineDescrToGLEntries();
    end;

    local procedure SetCopyLineDescrToGLEntries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Bug ugprade tag or remove
        IF SalesSetup.Get() then BEGIN
            SalesSetup."Copy Line Descr. to G/L Entry" := TRUE;
            SalesSetup.Modify();
        END;

        IF ServiceMgtSetup.Get() then BEGIN
            ServiceMgtSetup."Copy Line Descr. to G/L Entry" := TRUE;
            ServiceMgtSetup.Modify();
        END;

        IF PurchSetup.Get() then BEGIN
            PurchSetup."Copy Line Descr. to G/L Entry" := TRUE;
            PurchSetup.Modify();
        END;
    end;
}

