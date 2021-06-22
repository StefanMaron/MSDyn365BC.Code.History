codeunit 132502 "Purch. Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryPurchase: Codeunit "Library - Purchase";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        NothingToPostErr: Label 'There is nothing to post.';
        DefaultDimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Vendor %2.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Header");
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow Posting From'
        GeneralLedgerSetup.Get;
        TempErrorMessage.TestField("Record ID", GeneralLedgerSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Ledger Setup");
        TempErrorMessage.TestField("Field Number", GeneralLedgerSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        GeneralLedgerSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "General Ledger Setup" page.
        GeneralLedgerSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        GeneralLedgerSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate - 1;
        UserSetup.Modify;
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN]  "Source" is 'User Setup',  "Field Name" is 'Allow Posting From'
        TempErrorMessage.TestField("Record ID", UserSetup.RecordId);
        TempErrorMessage.TestField("Field Number", UserSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        UserSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "User Setup" page.
        UserSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        UserSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate);

        // TearDown
        UserSetup.Delete;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize;

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);

        // [WHEN] Preview Posting of Purchase Order '1002'
        asserterror PreviewPurchDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Purchase Header: Order, 1002'
        TempErrorMessage.FindLast;
        TempErrorMessage.TestField(Description, NothingToPostErr);
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectError()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        VendorNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents verifies "Error Messages" that contains two lines per first document and one line for second document
        Initialize;
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        VendorNo := LibraryPurchase.CreateVendorNo;
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[1], VendorNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);

        // [WHEN] Post both documents as a batch
        JobQueueEntry.DeleteAll();
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 3 lines:
        // [THEN] 2 lines for Invoice '1002' and 1 line for Invoice '1003'
        // [THEN] The first error for Invoice '1002' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 2);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
        // [THEN] The second error for Invoice '1002' is 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.'
        ErrorMessage.Next();
        Assert.ExpectedMessage(StrSubstNo(DefaultDimErr, DefaultDimension."Dimension Code", VendorNo), ErrorMessage.Description);

        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Document Posting Errors");
        LibraryErrorMessage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");
    end;

    local procedure PreviewPurchDocument(PurchHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages;
        PurchPostYesNo.Preview(PurchHeader);
    end;

    local procedure PurchHeaderToPost(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify;
        Commit;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

