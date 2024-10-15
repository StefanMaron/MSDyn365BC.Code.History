codeunit 144303 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHVATEntryExceptionReport')]
    [Scope('OnPrem')]
    procedure TestVATEntryExceptionReport()
    begin
        Initialize;
        REPORT.Run(REPORT::"VAT Entry Exception Report");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATEntryExceptionReport(var VATEntryExceptionReport: TestRequestPage "VAT Entry Exception Report")
    begin
        VATEntryExceptionReport.VATBaseDiscount.SetValue(true);
        VATEntryExceptionReport.ManualVATDifference.SetValue(true);
        VATEntryExceptionReport.VATCalculationTypes.SetValue(true);
        VATEntryExceptionReport.VATRate.SetValue(true);
        VATEntryExceptionReport.SaveAsPdf(FomatFileName(VATEntryExceptionReport.Caption));
    end;
}

