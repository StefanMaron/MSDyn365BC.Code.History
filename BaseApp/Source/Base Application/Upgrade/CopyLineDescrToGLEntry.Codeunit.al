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
         
        SetCopyLineDescrToGLEntries;
    end;

    local procedure SetCopyLineDescrToGLEntries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Bug ugprade tag or remove
        IF PurchasesPayablesSetup.GET THEN BEGIN
            PurchasesPayablesSetup."Copy Line Descr. to G/L Entry" := TRUE;
            PurchasesPayablesSetup.Modify();
        END;
    end;
}

