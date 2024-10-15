codeunit 104150 "Upgrade - Local App"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerDatabase()
    begin
        UpdatePermissions();
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateVATPostingSetup();
        UpdateVATControlReportLine();
        UpdateSalesReceivablesSetup();
    end;

    local procedure UpdateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag()) then
            exit;

        with VATPostingSetup do
            if FindSet() then
                repeat
                    // "Insolvency Proceedings (p.44)" field replaced by "Corrections for Bad Receivable" field
                    "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::" ";
                    IF "Insolvency Proceedings (p.44)" THEN
                        "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)";
                until Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag());
    end;

    local procedure UpdateVATControlReportLine()
    var
        VATControlReportLine: Record "VAT Control Report Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag()) then
            exit;

        with VATControlReportLine do
            if FindSet() then
                repeat
                    // "Insolvency Proceedings (p.44)" field replaced by "Corrections for Bad Receivable" field
                    "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::" ";
                    IF "Insolvency Proceedings (p.44)" THEN
                        "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)";
                until Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag());
    end;

    local procedure UpdatePermissions()
    var
        Permission: Record Permission;
        NewPermission: Record Permission;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetUseIsolatedCertificateInsteadOfCertificateCZ()) then
            exit;

        with Permission do begin
            SetRange("Object Type", "Object Type"::Table);
            SetRange("Object ID", Database::"Certificate CZ");
            if FindSet() then
                repeat
                    NewPermission.Init();
                    NewPermission := Permission;
                    NewPermission."Object ID" := Database::"Isolated Certificate";
                    NewPermission.Insert();
                    Delete();
                until Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag()) then
            exit;

        if SalesSetup.Get() then begin
            SalesSetup."Copy Line Descr. to G/L Entry" := SalesSetup."G/L Entry as Doc. Lines (Acc.)";
            SalesSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag());
    end;
}