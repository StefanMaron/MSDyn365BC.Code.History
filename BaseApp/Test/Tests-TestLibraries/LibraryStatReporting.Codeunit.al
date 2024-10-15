codeunit 143014 "Library - Stat. Reporting"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateStatutoryReport(var StatutoryReport: Record "Statutory Report")
    begin
        StatutoryReport.Init();
        StatutoryReport.Validate(Code, LibraryUtility.GenerateRandomCode(StatutoryReport.FieldNo(Code), DATABASE::"Statutory Report"));
        StatutoryReport.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateStatutoryReportData(var StatutoryReport: Record "Statutory Report")
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        AccountingPeriod: Record "Accounting Period";
        StartDate: Date;
        EndDate: Date;
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, true);
        AccountingPeriod.FindLast();
        StartDate := AccountingPeriod."Starting Date";
        EndDate := CalcDate('<CY>', StartDate);
        StatutoryReportDataHeader.CreateReportHeader(
          StatutoryReport, EndDate, StartDate, EndDate, 0, 0, 0, 'Test', 3, '46', '2016');
        StatutoryReport.CreateReportData(StatutoryReportDataHeader."No.", StartDate, EndDate, 0); // From database
    end;

    [Scope('OnPrem')]
    procedure CreateXMLElementLine(var XMLElementLine: Record "XML Element Line"; ReportCode: Code[20]; SourceType: Option; LineValue: Text[250]): Integer
    var
        RecRef: RecordRef;
    begin
        with XMLElementLine do begin
            Init;
            "Report Code" := ReportCode;
            RecRef.GetTable(XMLElementLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "Source Type" := SourceType;
            "Data Type" := "Data Type"::Integer;
            Value := LineValue;
            Insert;
            exit("Line No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXMLElementExpressionLine(ReportCode: Code[20]; BaseXMLElementLineNo: Integer; ChildXMLElementLineNo: Integer)
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        RecRef: RecordRef;
    begin
        with XMLElementExpressionLine do begin
            Init;
            "Report Code" := ReportCode;
            "Base XML Element Line No." := BaseXMLElementLineNo;
            RecRef.GetTable(XMLElementExpressionLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "XML Element Line No." := ChildXMLElementLineNo;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure ReleaseStatutoryReportDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    var
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        StatutoryReportMgt.ReleaseDataHeader(StatutoryReportDataHeader);
    end;

    [Scope('OnPrem')]
    procedure ReopenStatutoryReportDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    var
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        StatutoryReportMgt.ReopenDataHeader(StatutoryReportDataHeader);
    end;
}

