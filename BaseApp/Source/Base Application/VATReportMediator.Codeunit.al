codeunit 740 "VAT Report Mediator"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';

    procedure GetLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        if (VATReportHeader."VAT Report Type" = VATReportHeader."VAT Report Type"::Corrective) or
           (VATReportHeader."VAT Report Type" = VATReportHeader."VAT Report Type"::Supplementary)
        then
            VATReportHeader.TestField("Original Report No.");

        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);

        VATReportHeader.FilterGroup(2);
        VATReportHeader.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        CODEUNIT.Run(VATReportsConfiguration."Suggest Lines Codeunit ID", VATReportHeader);
    end;

    procedure Generate(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.TestField("Content Codeunit ID");
        CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", VATReportHeader);
    end;

    procedure ShowGenerate(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit((VATReportsConfiguration."Content Codeunit ID" <> 0) and (VATReportsConfiguration."Submission Codeunit ID" = 0));
    end;

    procedure Export(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        if VATReportsConfiguration."Content Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", VATReportHeader);
        if VATReportsConfiguration."Submission Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Submission Codeunit ID", VATReportHeader);
    end;

    procedure ShowExport(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit(VATReportsConfiguration."Submission Codeunit ID" <> 0);
    end;

    procedure ReceiveResponse(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.TestField("Response Handler Codeunit ID");
        CODEUNIT.Run(VATReportsConfiguration."Response Handler Codeunit ID", VATReportHeader);
    end;

    procedure ShowReceiveResponse(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit(
          (VATReportHeader.Status = VATReportHeader.Status::Submitted) and
          (VATReportsConfiguration."Response Handler Codeunit ID" <> 0));
    end;

    procedure Release(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
    end;

    procedure Reopen(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Reopen(VATReportHeader);
    end;

    procedure Print(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                PrintOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                PrintReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                PrintReleased(VATReportHeader);
        end;
    end;

    local procedure PrintOpen(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            PrintReleased(VATReportHeader);
        end
    end;

    local procedure PrintReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        REPORT.RunModal(REPORT::"VAT Report Print", false, false, VATReportHeader);
    end;

    procedure Submit(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Submit(VATReportHeader);
    end;

    procedure ShowSubmissionMessage(VATReportHeader: Record "VAT Report Header") ShowSubmissionMessage: Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        with VATReportHeader do begin
            GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
            if VATReportsConfiguration."Submission Codeunit ID" = 0 then
                ShowSubmissionMessage := Status = Status::Released
            else
                ShowSubmissionMessage := (Status = Status::Submitted) or
                  (Status = Status::Rejected) or
                  (Status = Status::Accepted) or
                  (Status = Status::Closed);
            exit(ShowSubmissionMessage);
        end;
    end;

    local procedure GetVATReportConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader."VAT Report Config. Code" of
            VATReportHeader."VAT Report Config. Code"::"VAT Return":
                VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
            VATReportHeader."VAT Report Config. Code"::"EC Sales List":
                VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"EC Sales List");
        end;
        if VATReportHeader."VAT Report Version" <> '' then
            VATReportsConfiguration.SetRange("VAT Report Version", VATReportHeader."VAT Report Version");
        VATReportsConfiguration.FindFirst();
    end;
}

