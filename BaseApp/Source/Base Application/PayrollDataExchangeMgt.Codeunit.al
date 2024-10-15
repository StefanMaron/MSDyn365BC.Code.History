codeunit 17415 "Payroll Data Exchange Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text002: Label 'Export payroll elements.';
        FileMgt: Codeunit "File Management";
        Text003: Label 'Export element groups.';
        Text004: Label 'Export calculation functions.';
        Text005: Label 'Export payroll analysis reports.';

    [Scope('OnPrem')]
    procedure ImportPayrollElements(FileName: Text[1024])
    var
        ElementXMLPort: XMLport "Payroll Element";
        PayrollFile: File;
        InputStream: InStream;
    begin
        if not CreateInputStream(FileName, PayrollFile, InputStream) then
            exit;

        ElementXMLPort.SetSource(InputStream);
        ElementXMLPort.Import;
        ElementXMLPort.ImportData;
        Clear(InputStream);

        if FileName <> '' then
            PayrollFile.Close;
    end;

    [Scope('OnPrem')]
    procedure ExportPayrollElements(var PayrollElement: Record "Payroll Element")
    var
        ElementXMLPort: XMLport "Payroll Element";
        OutputFile: File;
        OutputStream: OutStream;
        FileName: Text[250];
    begin
        FileName := FileMgt.ServerTempFileName('xml');

        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutputStream);

        ElementXMLPort.SetDestination(OutputStream);
        ElementXMLPort.SetData(PayrollElement);
        ElementXMLPort.Export;
        OutputFile.Close;

        Download(FileName, Text002, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportPayrollCalcGroups(FileName: Text[1024])
    var
        PayrollCalcGroupXMLPort: XMLport "Payroll Calc. Group";
        PayrollFile: File;
        InputStream: InStream;
    begin
        if not CreateInputStream(FileName, PayrollFile, InputStream) then
            exit;

        PayrollCalcGroupXMLPort.SetSource(InputStream);
        PayrollCalcGroupXMLPort.Import;
        PayrollCalcGroupXMLPort.ImportData;
        Clear(InputStream);

        if FileName <> '' then
            PayrollFile.Close;
    end;

    [Scope('OnPrem')]
    procedure ExportPayrollCalcGroups(var PayrollCalcGroup: Record "Payroll Calc Group")
    var
        PayrollCalcGroupXMLPort: XMLport "Payroll Calc. Group";
        OutputFile: File;
        OutputStream: OutStream;
        FileName: Text[250];
    begin
        FileName := FileMgt.ServerTempFileName('xml');

        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutputStream);

        PayrollCalcGroupXMLPort.SetDestination(OutputStream);
        PayrollCalcGroupXMLPort.SetData(PayrollCalcGroup);
        PayrollCalcGroupXMLPort.Export;
        OutputFile.Close;

        Download(FileName, Text003, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportPayrollCalcFunctions(FileName: Text[1024])
    var
        PayrollCalcFuncXMLPort: XMLport "Payroll Calc. Functions";
        PayrollFile: File;
        InputStream: InStream;
    begin
        if not CreateInputStream(FileName, PayrollFile, InputStream) then
            exit;

        PayrollCalcFuncXMLPort.SetSource(InputStream);
        PayrollCalcFuncXMLPort.Import;
        PayrollCalcFuncXMLPort.ImportData;
        Clear(InputStream);

        if FileName <> '' then
            PayrollFile.Close;
    end;

    [Scope('OnPrem')]
    procedure ExportPayrollCalcFunctions(var PayrollCalcFunction: Record "Payroll Calculation Function")
    var
        PayrollCalcFuncXMLPort: XMLport "Payroll Calc. Functions";
        OutputFile: File;
        OutputStream: OutStream;
        FileName: Text[250];
    begin
        FileName := FileMgt.ServerTempFileName('xml');

        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutputStream);

        PayrollCalcFuncXMLPort.SetDestination(OutputStream);
        PayrollCalcFuncXMLPort.SetData(PayrollCalcFunction);
        PayrollCalcFuncXMLPort.Export;
        OutputFile.Close;

        Download(FileName, Text004, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportPayrollAnalysisReports(FileName: Text[1024])
    var
        PayrollAnalysisReports: XMLport "Payroll Analysis Reports";
        PayrollFile: File;
        InputStream: InStream;
    begin
        if not CreateInputStream(FileName, PayrollFile, InputStream) then
            exit;

        PayrollAnalysisReports.SetSource(InputStream);
        PayrollAnalysisReports.Import;
        PayrollAnalysisReports.ImportData;
        Clear(InputStream);

        if FileName <> '' then
            PayrollFile.Close;
    end;

    [Scope('OnPrem')]
    procedure ExportPayrollAnalysisReports(var PayrollAnalysisReportName: Record "Payroll Analysis Report Name")
    var
        PayrollAnalysisReports: XMLport "Payroll Analysis Reports";
        OutputFile: File;
        OutputStream: OutStream;
        FileName: Text[250];
    begin
        FileName := FileMgt.ServerTempFileName('xml');

        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutputStream);

        PayrollAnalysisReports.SetDestination(OutputStream);
        PayrollAnalysisReports.SetData(PayrollAnalysisReportName);
        PayrollAnalysisReports.Export;
        OutputFile.Close;

        Download(FileName, Text005, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure CreateInputStream(FileName: Text; var PayrollFile: File; var InputStream: InStream): Boolean
    begin
        if FileName <> '' then begin
            PayrollFile.Open(FileName);
            PayrollFile.CreateInStream(InputStream);
            exit(true);
        end;

        exit(UploadIntoStream('', '', '*.xml|*.xml', FileName, InputStream));
    end;
}

