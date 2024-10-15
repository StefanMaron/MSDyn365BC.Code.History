codeunit 13403 "Export SEPA Payment File"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        if (GetFilter("Journal Template Name") <> '') and (GetFilter("Journal Batch Name") <> '') and (GetFilter("Document No.") <> '') then
            Error(ExportRefPmtErr);

        RefPmtExp.SetRange(Transferred, false);
        RefPmtExp.SetRange("Applied Payments", false);
        RefPmtExp.SetRange("SEPA Payment", true);
        REPORT.Run(REPORT::"Export SEPA Payment File", false, false, RefPmtExp);
    end;

    var
        RefPmtExp: Record "Ref. Payment - Exported";
        ExportRefPmtErr: Label 'Your export format is not set up to export bank Payments with this function. Use the function in the Bank Payment to Send window instead.';
}

