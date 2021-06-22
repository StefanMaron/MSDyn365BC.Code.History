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

        VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
        if VATReportHeader."VAT Report Version" <> '' then
            VATReportsConfiguration.SetRange("VAT Report Version", VATReportHeader."VAT Report Version");
        VATReportsConfiguration.FindFirst;

        VATReportHeader.FilterGroup(2);
        VATReportHeader.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        CODEUNIT.Run(VATReportsConfiguration."Suggest Lines Codeunit ID", VATReportHeader);
    end;

    procedure Export(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        case VATReportHeader."VAT Report Config. Code" of
            VATReportHeader."VAT Report Config. Code"::"VAT Return":
                VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
            VATReportHeader."VAT Report Config. Code"::"EC Sales List":
                VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"EC Sales List");
        end;
        if VATReportHeader."VAT Report Version" <> '' then
            VATReportsConfiguration.SetRange("VAT Report Version", VATReportHeader."VAT Report Version");
        VATReportsConfiguration.FindFirst;

        if VATReportsConfiguration."Content Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", VATReportHeader);
        if VATReportsConfiguration."Submission Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Submission Codeunit ID", VATReportHeader);
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
}

