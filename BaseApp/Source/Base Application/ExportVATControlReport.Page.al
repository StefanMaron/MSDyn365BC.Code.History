page 31106 "Export VAT Control Report"
{
    Caption = 'Export VAT Control Report';
    DataCaptionFields = "No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "VAT Control Report Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(XmlFormat; XmlFormat)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Xml Format';
                }
                field(StartDateName; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the first date in the period for which VAT control report were exported.';

                    trigger OnValidate()
                    begin
                        StartDateOnAfterValidate;
                    end;
                }
                field(EndDateName; EndDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the last date in the period for which VAT control report were exported.';

                    trigger OnValidate()
                    begin
                        EndDateReqOnAfterValidate;
                    end;
                }
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries Selection';
                    OptionCaption = 'Open,Closed,Open and Closed';
                    ToolTip = 'Specifies that VAT entries are included in the VAT control report.';
                }
                field(PrintInIntegers; PrintInIntegers)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Round to Integer';
                    ToolTip = 'Specifies if the vat statement will be rounded to integer';
                }
                group(Control1220025)
                {
                    ShowCaption = false;
                }
                field(DeclarationType; DeclarationType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Declaration Type';
                    OptionCaption = 'Recapitulative,Recapitulative-Corrective,Supplementary,Supplementary-Corrective';
                    ToolTip = 'Specifies the declaration type (recapitulative, corrective, supplementary).';

                    trigger OnValidate()
                    begin
                        if DeclarationType <> DeclarationType::Supplementary then begin
                            ReasonsObservedOn := 0D;
                            AppelDocumentNo := '';
                        end;
                    end;
                }
                field(Month; Month)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Month';
                    ToolTip = 'Specifies the number of monat for VAT statement reporting.';

                    trigger OnValidate()
                    begin
                        if Month <> 0 then
                            if Quarter <> 0 then
                                Error(MonthZeroIfQuarterErr);
                    end;
                }
                field(Quarter; Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Quarter';
                    ToolTip = 'Specifies vat statement for quarter';

                    trigger OnValidate()
                    begin
                        if Quarter <> 0 then
                            if Month <> 0 then
                                Error(MonthDontEmptyIfQuarErr);
                    end;
                }
                field(YearName; Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Specifies year of vat statement';
                }
                field(ReasonsObservedOn; ReasonsObservedOn)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reasons Observed On Date';
                    ToolTip = 'Specifies the date of finding reasons of supplementary vat control report';
                }
                field(FastAppelReaction; FastAppelReaction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fast reaction to appel';
                    ToolTip = 'Specifies the quick answer for appel. It is used for VAT Control Report.';
                }
                field(AppelDocumentNo; AppelDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Appel Document No.';
                    ToolTip = 'Specifies the number of appel document.';
                }
                field(FilledByEmployeeNo; FilledByEmployeeNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filled By Employee No.';
                    TableRelation = "Company Officials";
                    ToolTip = 'Specifies the number of employee, who filled VAT control report.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OK)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'OK';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'This batch job exported VAT control report xml file.';

                trigger OnAction()
                begin
                    ClientFileName := ExportToXML();
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StartDate := "Start Date";
        EndDate := "End Date";
        case "Report Period" of
            "Report Period"::Month:
                begin
                    Month := "Period No.";
                    Quarter := 0;
                end;
            "Report Period"::Quarter:
                begin
                    Quarter := "Period No.";
                    Month := 0;
                end;
        end;
        Year := Year;
    end;

    trigger OnOpenPage()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CompanyOfficials: Record "Company Officials";
    begin
        UpdateDateParameters;
        StatReportingSetup.Get;
        if CompanyOfficials.Get(StatReportingSetup."VAT Stat. Filled by Empl. No.") then
            FilledByEmployeeNo := CompanyOfficials."No.";
        XmlFormat := StatReportingSetup."VAT Control Report Xml Format";
    end;

    var
        MonthZeroIfQuarterErr: Label 'Month must be 0 if Quarter is filled in.';
        MonthDontEmptyIfQuarErr: Label 'Quarter must be 0 if Month is filled in.';
        MonthOrQuarterErr: Label 'Month or Quarter must be filled in.';
        ReasonObserverReqErr: Label 'You must specify Reasons Observed On date in Supplementary or Corrective VAT Control Report.';
        TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary;
        FileMgt: Codeunit "File Management";
        VATControlReportMgt: Codeunit VATControlReportManagement;
        VATControlReport: XMLport "VAT Control Report";
        DeclarationType: Option Recapitulative,"Recapitulative-Corrective",Supplementary,"Supplementary-Corrective";
        ReasonsObservedOn: Date;
        StartDate: Date;
        EndDate: Date;
        Month: Integer;
        Quarter: Integer;
        Year: Integer;
        Selection: Option Open,Closed,"Open and Closed";
        FilledByEmployeeNo: Code[20];
        FastAppelReaction: Option " ",B,P;
        AppelDocumentNo: Text;
        PrintInIntegers: Boolean;
        ClientFileName: Text;
        XmlFormat: Option "KH 02.01.03","KH 03.01.01";

    local procedure UpdateDateParameters()
    var
        DateRec: Record Date;
    begin
        if (StartDate <> 0D) and (EndDate <> 0D) then begin
            if EndDate < StartDate then
                EndDate := StartDate;
            Year := Date2DMY(StartDate, 3);
            Month := Date2DMY(StartDate, 2);
            if (Month = Date2DMY(EndDate, 2)) and (Year = Date2DMY(EndDate, 3)) then
                Quarter := 0
            else begin
                Month := 0;
                DateRec.SetRange("Period Type", DateRec."Period Type"::Quarter);
                DateRec.SetFilter("Period Start", '..%1', StartDate);
                if DateRec.FindLast then
                    Quarter := DateRec."Period No.";
            end;
        end;
    end;

    local procedure ExportToXML(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutputStream: OutStream;
    begin
        if (Month = 0) and (Quarter = 0) then
            Error(MonthOrQuarterErr);

        if DeclarationIsSupplementary then begin
            if ReasonsObservedOn = 0D then
                Error(ReasonObserverReqErr);
        end;

        ClearXMLPortVariables;
        VATControlReportMgt.CreateBufferForExport(Rec, TempVATCtrlRptBuf, false, Selection);
        TempBlob.CreateOutStream(OutputStream);
        XMLExportWithParametersTo(OutputStream);
        exit(FileMgt.BLOBExport(TempBlob, '*.xml', true));
    end;

    local procedure XMLExportWithParametersTo(var OutputStream: OutStream)
    begin
        VATControlReport.SetParameters(
          Month, Quarter, Year, DeclarationType, ReasonsObservedOn, FilledByEmployeeNo, FastAppelReaction, AppelDocumentNo, XmlFormat);
        if PrintInIntegers then begin
            TempVATCtrlRptBuf.Reset;
            if TempVATCtrlRptBuf.FindSet then
                repeat
                    TempVATCtrlRptBuf."Base 1" := Round(TempVATCtrlRptBuf."Base 1", 1);
                    TempVATCtrlRptBuf."Base 2" := Round(TempVATCtrlRptBuf."Base 2", 1);
                    TempVATCtrlRptBuf."Base 3" := Round(TempVATCtrlRptBuf."Base 3", 1);
                    TempVATCtrlRptBuf."Amount 1" := Round(TempVATCtrlRptBuf."Amount 1", 1);
                    TempVATCtrlRptBuf."Amount 2" := Round(TempVATCtrlRptBuf."Amount 2", 1);
                    TempVATCtrlRptBuf."Amount 3" := Round(TempVATCtrlRptBuf."Amount 3", 1);
                    TempVATCtrlRptBuf."Total Base" := Round(TempVATCtrlRptBuf."Total Base", 1);
                    TempVATCtrlRptBuf."Total Amount" := Round(TempVATCtrlRptBuf."Total Amount", 1);
                    TempVATCtrlRptBuf.Modify;
                until TempVATCtrlRptBuf.Next = 0;
        end;
        TempVATCtrlRptBuf.Reset;
        VATControlReport.CopyBuffer(TempVATCtrlRptBuf);
        VATControlReport.SetDestination(OutputStream);
        VATControlReport.Export;
    end;

    local procedure ClearXMLPortVariables()
    begin
        VATControlReport.ClearVariables;
    end;

    local procedure DeclarationIsSupplementary(): Boolean
    begin
        exit(DeclarationType in [DeclarationType::Supplementary, DeclarationType::"Supplementary-Corrective"]);
    end;

    local procedure EndDateReqOnAfterValidate()
    begin
        UpdateDateParameters;
    end;

    local procedure StartDateOnAfterValidate()
    begin
        UpdateDateParameters;
    end;

    [Scope('OnPrem')]
    procedure GetClientFileName(): Text
    begin
        exit(ClientFileName);
    end;
}

