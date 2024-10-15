codeunit 104152 "Copy Line Descr. To G/L Entry"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        SetCopyLineDescrToGLEntries;
    end;

    local procedure SetCopyLineDescrToGLEntries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Bug ugprade tag or remove
        IF SalesSetup.GET THEN BEGIN
            SalesSetup."Copy Line Descr. to G/L Entry" := TRUE;
            SalesSetup.MODIFY;
        END;

        IF ServiceMgtSetup.GET THEN BEGIN
            ServiceMgtSetup."Copy Line Descr. to G/L Entry" := TRUE;
            ServiceMgtSetup.MODIFY;
        END;

        IF PurchSetup.GET THEN BEGIN
            PurchSetup."Copy Line Descr. to G/L Entry" := TRUE;
            PurchSetup.MODIFY;
        END;
    end;
}

