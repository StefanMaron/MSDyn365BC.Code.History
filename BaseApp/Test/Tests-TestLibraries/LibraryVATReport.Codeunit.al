codeunit 131343 "Library - VAT Report"
{
    var
        LibraryUtility: Codeunit "Library - Utility";

    trigger OnRun()
    begin

    end;

    procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header");
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert(true);
    end;

    procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header"; PeriodYear: Integer);
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Validate("Period Year", PeriodYear);
        VATReportHeader.Insert(true);
    end;

    procedure FindVATReturnConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"): Boolean
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
        exit(VATReportsConfiguration.FindFirst());
    end;

    procedure CreateVATReportConfigurationNo(): Code[10]
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        CreateVATReportConfiguration(VATReportsConfiguration, 0, 0, 0, 0, 0);
        exit(VATReportsConfiguration."VAT Report Version");
    end;

    procedure CreateVATReportConfigurationNo(SuggestLinesCodeunitID: Integer; ContentCodeunitID: Integer; ValidateCodeunitID: Integer; SubmissionCodeunitID: Integer; ResponseHandlerCodeunitID: Integer): Code[10]
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        CreateVATReportConfiguration(
            VATReportsConfiguration, SuggestLinesCodeunitID, ContentCodeunitID,
            ValidateCodeunitID, SubmissionCodeunitID, ResponseHandlerCodeunitID);
        exit(VATReportsConfiguration."VAT Report Version");
    end;

    local procedure CreateVATReportConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"; SuggestLinesCodeunitID: Integer; ContentCodeunitID: Integer; ValidateCodeunitID: Integer; SubmissionCodeunitID: Integer; ResponseHandlerCodeunitID: Integer)
    begin
        with VATReportsConfiguration do begin
            "VAT Report Type" := "VAT Report Type"::"VAT Return";
            "VAT Report Version" := LibraryUtility.GenerateGUID();
            "Suggest Lines Codeunit ID" := SuggestLinesCodeunitID;
            "Content Codeunit ID" := ContentCodeunitID;
            "Validate Codeunit ID" := ValidateCodeunitID;
            "Submission Codeunit ID" := SubmissionCodeunitID;
            "Response Handler Codeunit ID" := ResponseHandlerCodeunitID;
            Insert();
        end;
    end;
}