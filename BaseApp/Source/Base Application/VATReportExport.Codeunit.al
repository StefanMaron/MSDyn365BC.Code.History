codeunit 743 "VAT Report Export"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';
        Text002: Label 'You cannot export already submitted report. Reopen report first.';

    procedure Export(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                ExportOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                ExportReleased(VATReportHeader);
            VATReportHeader.Status::Exported:
                ExportReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                Error(Text002);
        end;
    end;

    local procedure ExportOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportReleased(VATReportHeader);
        end;
    end;

    local procedure ExportReleased(VATReportHeader: Record "VAT Report Header")
    begin
        ExportReport(VATReportHeader);
    end;

    local procedure ExportReport(VATReportHeader: Record "VAT Report Header")
    var
        VATReportHeader2: Record "VAT Report Header";
    begin
        VATReportHeader2.Copy(VATReportHeader);
        VATReportHeader2.SetRange("No.", VATReportHeader."No.");
        Commit;
        REPORT.Run(REPORT::"Export VIES Report", true, false, VATReportHeader2);
    end;
}

