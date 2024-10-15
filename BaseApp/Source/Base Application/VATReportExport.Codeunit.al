codeunit 743 "VAT Report Export"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';

    procedure Export(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                ExportOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                ExportReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                ExportReleased(VATReportHeader);
        end;
    end;

    local procedure ExportOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportReport(VATReportHeader, false);
        end;
    end;

    local procedure ExportReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        ExportReport(VATReportHeader, true);
    end;

    local procedure ExportReport(var VATReportHeader: Record "VAT Report Header"; Validate: Boolean)
    var
        VATReportHeaderLocal: Record "VAT Report Header";
    begin
        if Validate then begin
            if VATReportHeader.isDatifattura then
                CODEUNIT.Run(CODEUNIT::"Datifattura Validate", VATReportHeader)
            else
                CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);
        end;

        VATReportHeaderLocal.Copy(VATReportHeader);
        VATReportHeaderLocal.SetRange("No.", VATReportHeader."No.");
        Commit;
        if VATReportHeaderLocal.isDatifattura then
            CODEUNIT.Run(CODEUNIT::"Datifattura Export", VATReportHeaderLocal)
        else
            REPORT.Run(REPORT::"Export VAT Transactions", true, false, VATReportHeaderLocal);
    end;
}

