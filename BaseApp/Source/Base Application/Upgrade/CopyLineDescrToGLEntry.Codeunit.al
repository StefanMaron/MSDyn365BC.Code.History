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
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Bug ugprade tag or remove
        if PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup."Copy Line Descr. to G/L Entry" := true;
            PurchasesPayablesSetup.Modify();
        end;
    end;
}

