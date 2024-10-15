codeunit 104151 "UPG. MX CFDI"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateSATCatalogs;
        UpdateCFDIFields
    end;

    local procedure UpdateSATCatalogs()
    begin
        // Bug - add upgrade tag
        CODEUNIT.RUN(CODEUNIT::"Update SAT Payment Catalogs");
    end;

    local procedure UpdateCFDIFields()
    begin
        // Bug - add upgrade tag
        CODEUNIT.RUN(CODEUNIT::"Update CFDI Fields Sales Doc");
    end;
}

