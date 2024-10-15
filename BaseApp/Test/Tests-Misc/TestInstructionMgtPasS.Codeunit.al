codeunit 139003 "Test Instruction Mgt. PasS"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post and Send] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostingInstructionNotShownForEmptySalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize;

        // Exercise
        SalesInvoice.OpenNew;

        // Verify
        // Instruction is not displayed
        SalesInvoice.Close;
    end;

    [Test]
    [HandlerFunctions('EmailDialogModalPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostingInstructionNotShownAfterPostingAndSending()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '', '', 1, '', 0D);
        DocumentNo := SalesHeader."No.";

        UpdateSalesInvoiceReportSelections;

        // Exercise
        SalesInvoice.OpenEdit;
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Email as PDF".Invoke;

        // Verify
        SalesInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    local procedure Initialize()
    var
        UserPreference: Record "User Preference";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        BindActiveDirectoryMockEvents;

        UserPreference.DeleteAll;

        LibraryApplicationArea.EnableFoundationSetup;

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;

        IsInitialized := true;
        Commit;
    end;

    local procedure UpdateSalesInvoiceReportSelections()
    var
        ExistingReportSelections: Record "Report Selections";
        NewReportSelections: Record "Report Selections";
    begin
        ExistingReportSelections.SetRange(Usage, ExistingReportSelections.Usage::"S.Invoice");
        ExistingReportSelections.ModifyAll(Default, false, true);

        NewReportSelections.Init;
        NewReportSelections.Validate(Usage, NewReportSelections.Usage::"S.Invoice");
        NewReportSelections.Validate("Report ID", REPORT::"Standard Sales - Invoice");
        NewReportSelections.Validate(Default, true);
        NewReportSelections.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailDialogModalPageHandler(var EmailDialog: TestPage "Email Dialog")
    begin
        EmailDialog.OutlookEdit.SetValue(false);
        EmailDialog.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;
}

