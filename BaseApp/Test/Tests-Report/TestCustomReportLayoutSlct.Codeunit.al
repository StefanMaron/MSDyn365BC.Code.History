codeunit 134606 "Test Custom Report Layout Slct"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout] [Custom]
    end;

    var
        Assert: Codeunit Assert;
        FileManagement: Codeunit "File Management";

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomReportLayoutSelection()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempFileName: Text;
        ReportOK: Boolean;
    begin
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceHeader.SetRecFilter;

        CustomReportLayout.SetFilter("Report ID", StrSubstNo('%1|%2', REPORT::"Sales - Invoice", REPORT::"Standard Sales - Invoice"));
        if CustomReportLayout.FindSet then
            repeat
                ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);
                TempFileName := FileManagement.ServerTempFileName('.pdf');
                ReportOK := REPORT.SaveAsPdf(CustomReportLayout."Report ID", TempFileName, SalesInvoiceHeader);
                ReportLayoutSelection.SetTempLayoutSelected('');
                Assert.IsTrue(ReportOK, 'PDF generation failed');
                FileManagement.DeleteServerFile(TempFileName);
            until CustomReportLayout.Next = 0;
    end;
}

