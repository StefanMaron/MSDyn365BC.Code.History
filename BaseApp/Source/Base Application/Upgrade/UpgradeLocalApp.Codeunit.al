codeunit 104150 "Upgrade - Local App"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin

    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateVATPostingSetup();
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
}