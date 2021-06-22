codeunit 132501 "Sales Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibrarySales: Codeunit "Library - Sales";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        NothingToPostErr: Label 'There is nothing to post.';
        DefaultDimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.';

        // Expected error messages (from code unit 80).
        SalesReturnRcptHeaderConflictErr: Label 'Cannot post the sales return because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Receipt No.';
        SalesShptHeaderConflictErr: Label 'Cannot post the sales shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Shipping No.';
        SalesInvHeaderConflictErr: Label 'Cannot post the sales invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Header");
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow Posting From'
        GeneralLedgerSetup.Get();
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
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
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
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate);

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize;

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [WHEN] Preview posting of Order '1002'
        asserterror PreviewSalesDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Sales Header: Order, 1002'
        TempErrorMessage.FindLast;
        TempErrorMessage.TestField(Description, NothingToPostErr);
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T940_BatchPostingWithOneLoggedAndOneDirectError()
    var
        SalesHeader: array[3] of Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting]
        // [SCENARIO] Batch posting of two documents (in the current session) opens "Error Messages" page that contains two lines per document.
        Initialize;
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019, and nothing to post
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, CustomerNo);
        SalesHeaderToPost(SalesHeader[1]);
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');

        // [THEN] Opened page "Error Messages" with 3 lines:
        // [THEN] 2 lines for Order '1002' and 1 line for Invoice '1003'
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Clear(RegisterID);
        TempErrorMessage.SetRange("Register ID", RegisterID);
        Assert.RecordCount(TempErrorMessage, 3);
        // [THEN] The first error for Order '1002' is 'Posting Date is not within your range of allowed posting dates.'

        TempErrorMessage.Get(1);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 1st error');
        // [THEN] The second error for Order '1002' is 'There is nothing to post'
        TempErrorMessage.Get(2);
        Assert.ExpectedMessage(NothingToPostErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 2nd error');
        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        TempErrorMessage.Get(3);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[2].RecordId, TempErrorMessage."Context Record ID", 'Context for 3rd error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectErrorBackground()
    var
        SalesHeader: array[3] of Record "Sales Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents (in background) verifies "Error Messages" that contains two lines per first document and one line for second document
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch via Job Queue
        JobQueueEntry.DeleteAll();
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 3 lines:
        // [THEN] 2 lines for Invoice '1002' and 1 line for Invoice '1003'
        // [THEN] The first error for Invoice '1002' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", SalesHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 2);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
        // [THEN] The second error for Invoice '1002' is 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.'
        ErrorMessage.Next();
        Assert.ExpectedMessage(StrSubstNo(DefaultDimErr, DefaultDimension."Dimension Code", CustomerNo), ErrorMessage.Description);

        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", SalesHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure BatchPostingWithErrorsShowJobQueueErrorsBackground()
    var
        SalesHeader: array[2] of Record "Sales Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        JobQueueEntries: TestPage "Job Queue Entries";
        ErrorMessages: TestPage "Error Messages";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of document (in background) verifies "Error Messages" page that contains two lines for Job Queue Entry
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [WHEN] Post both documents as a batch via Job Queue
        JobQueueEntry.DeleteAll();
        SalesHeader[2].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[2], 2, '');
        JobQueueEntry.SetRange("Record ID to Process", SalesHeader[1].RecordId);
        JobQueueEntry.FindFirst();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId);

        // [THEN] "Error Message" page contains 2 lines:
        JobQueueEntries.OpenView();
        JobQueueEntries.GoToRecord(JobQueueEntry);
        ErrorMessages.Trap();
        JobQueueEntries.ShowError.Invoke();
        ErrorMessages.First();
        Assert.IsSubstring(ErrorMessages.Description.Value, PostingDateNotAllowedErr);
        ErrorMessages.Next();
        Assert.IsSubstring(ErrorMessages.Description.Value, StrSubstNo(DefaultDimErr, DefaultDimension."Dimension Code", CustomerNo));
        Assert.IsFalse(ErrorMessages.Next(), 'Wrong number of error messages.');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostingReturnReceiptNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales credit memo when the reserved Return Receipt No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales credit memo where we create a Return Receipt Header record and the next Return Recipt No. already exists.
        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Return Receipt No. Series" := SalesSetup."Posted Return Receipt Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Return Receipt No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        ReturnRcptHeader.SetCurrentKey("No.");
        ReturnRcptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(ReturnRcptHeader."No.");

        // Sanity check.
        Assert.AreEqual(ReturnRcptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales credit memo.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(SalesReturnRcptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Receipt No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Return Receipt No.", 'Return Receipt No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingShippingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales invoice when the reserved Shipping No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales invoice where we create a Sales Shipment Header record and the next Shipping No. already exists.
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Shipping No. Series" := SalesSetup."Posted Shipment Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Shipping No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        SalesShptHeader.SetCurrentKey("No.");
        SalesShptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(SalesShptHeader."No.");

        // Sanity check.
        Assert.AreEqual(SalesShptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales invoice.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(SalesShptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Shipping No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Shipping No.", 'Shipping No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPostingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales invoice when the reserved Posting No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate);
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales invoice where we create a Sales Invoice Header record and the next Posting No. already exists.
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Posting No. Series" := SalesSetup."Posted Invoice Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Posting No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        SalesInvHeader.SetCurrentKey("No.");
        SalesInvHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(SalesInvHeader."No.");

        // Sanity check.
        Assert.AreEqual(SalesInvHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales invoice.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField(Description, StrSubstNo(SalesInvHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Posting No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Posting No.", 'Posting No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Document Posting Errors");
        LibraryErrorMessage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");
    end;

    local procedure PreviewSalesDocument(SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages;
        SalesPostYesNo.Preview(SalesHeader);
    end;

    local procedure SalesHeaderToPost(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
        Commit();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

