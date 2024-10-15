codeunit 10012 "Ship-Post + Print"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code;
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReportSelection: Record "Report Selections";
        SalesPost: Codeunit "Sales-Post";
        Text1020001: Label 'Do you want to ship and print the %1?';

    local procedure "Code"()
    begin
        with SalesHeader do
            if "Document Type" = "Document Type"::Order then begin
                if not Confirm(Text1020001, false, "Document Type") then begin
                    "Shipping No." := '-1';
                    exit;
                end;
                Ship := true;
                Invoice := false;
                SalesPost.Run(SalesHeader);

                SalesShptHeader."No." := "Last Shipping No.";
                SalesShptHeader.SetRecFilter;
                PrintReport(ReportSelection.Usage::"S.Shipment");
            end;
    end;

    local procedure PrintReport(ReportUsage: Integer)
    begin
        ReportSelection.Reset();
        ReportSelection.SetRange(Usage, ReportUsage);
        ReportSelection.Find('-');
        repeat
            ReportSelection.TestField("Report ID");
            case ReportUsage of
                ReportSelection.Usage::"S.Invoice":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesInvHeader);
                ReportSelection.Usage::"S.Cr.Memo":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesCrMemoHeader);
                ReportSelection.Usage::"S.Shipment":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesShptHeader);
                ReportSelection.Usage::"S.Ret.Rcpt.":
                    REPORT.Run(ReportSelection."Report ID", false, false, ReturnRcptHeader);
            end;
        until ReportSelection.Next = 0;
    end;
}

