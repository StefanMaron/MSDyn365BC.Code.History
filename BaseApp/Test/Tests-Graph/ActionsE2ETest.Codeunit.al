codeunit 135541 "Actions E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Actions]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        Initialized: Boolean;
        InvoiceServiceNameTxt: Label 'salesInvoices';
        QuoteServiceNameTxt: Label 'salesQuotes', Locked = true;
        JournalServiceNameTxt: Label 'journals';
        PurchInvServiceNameTxt: Label 'purchaseInvoices';
        ActionPostTxt: Label 'Microsoft.NAV.post';
        ActionPostAndSendTxt: Label 'Microsoft.NAV.postAndSend', Locked = true;
        ActionCancelTxt: Label 'Microsoft.NAV.cancel', Locked = true;
        ActionCancelAndSendTxt: Label 'Microsoft.NAV.cancelAndSend', Locked = true;
        ActionSendTxt: Label 'Microsoft.NAV.send', Locked = true;
        ActionMakeInvoiceTxt: Label 'Microsoft.NAV.makeInvoice', Locked = true;
        NotEmptyResponseErr: Label 'Response body should be empty.';
        CannotFindDraftInvoiceErr: Label 'Cannot find the draft invoice.';
        CannotFindPostedInvoiceErr: Label 'Cannot find the posted invoice.';
        CannotFindQuoteErr: Label 'Cannot find the quote.', Locked = true;
        QuoteStillExistsErr: Label 'The quote still exists.', Locked = true;
        EmptyParameterErr: Label 'Email parameter %1 is empty.', Locked = true;
        NotEmptyParameterErr: Label 'Email parameter %1 is not empty.', Locked = true;
        NotTransferredParameterErr: Label 'Email parameter %1 is not transferred.', Locked = true;
        InvoiceIdErr: Label 'The invoice ID should differ from the quote ID.', Locked = true;
        InvoiceStatusErr: Label 'The invoice status is incorrect.';
        QuoteStatusErr: Label 'The quote status is incorrect.', Locked = true;
        MailingJobErr: Label 'The mailing job is not created.', Locked = true;
        GenJournalLineNotPostedErr: Label 'The general journal line was not correctly posted. The resulting Customer Ledger Entry is missing.';

    local procedure Initialize(ForSending: Boolean)
    begin
        if ForSending then begin
            CreateSMTPMailSetup;
            DeleteJobQueueEntry(CODEUNIT::"Document-Mailing");
            DeleteJobQueueEntry(CODEUNIT::"O365 Sales Cancel Invoice");
        end;

        if Initialized then
            exit;

        Initialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DraftInvoiceRecordRef: RecordRef;
        PostedInvoiceRecordRef: RecordRef;
        DocumentId: Guid;
        DocumentNo: Code[20];
        ResponseText: Text;
        TargetURL: Text;
        DraftInvoiceEmailAddress: Text;
        DraftInvoiceEmailSubject: Text;
        PostedInvoiceEmailAddress: Text;
        PostedInvoiceEmailSubject: Text;
    begin
        // [SCENARIO] User can post a sales invoice through the API.
        Initialize(false);

        // [GIVEN] Draft sales invoice exists
        CreateDraftSalesInvoice(SalesHeader);
        CreateEmailParameters(SalesHeader);
        DraftInvoiceRecordRef.GetTable(SalesHeader);
        GetEmailParameters(DraftInvoiceRecordRef, DraftInvoiceEmailAddress, DraftInvoiceEmailSubject);
        DocumentId := SalesHeader.SystemId;
        DocumentNo := SalesHeader."No.";
        Commit();
        Assert.IsTrue(DraftInvoiceEmailAddress <> '', StrSubstNo(EmptyParameterErr, 'Address'));
        Assert.IsTrue(DraftInvoiceEmailSubject <> '', StrSubstNo(EmptyParameterErr, 'Subject'));

        VerifyDraftSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionPostTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Invoice is posted
        FindPostedInvoiceByPreAssignedNo(DocumentNo, SalesInvoiceHeader);
        VerifyPostedSalesInvoice(SalesInvoiceHeader."Draft Invoice SystemId", TempSalesInvoiceEntityAggregate.Status::Open);

        // [THEN] Email parameters are transferred from the draft invoice to the posted invoice
        PostedInvoiceRecordRef.GetTable(SalesInvoiceHeader);
        GetEmailParameters(PostedInvoiceRecordRef, PostedInvoiceEmailAddress, PostedInvoiceEmailSubject);
        Assert.AreEqual(DraftInvoiceEmailAddress, PostedInvoiceEmailAddress, StrSubstNo(NotTransferredParameterErr, 'Address'));
        Assert.AreEqual(DraftInvoiceEmailSubject, PostedInvoiceEmailSubject, StrSubstNo(NotTransferredParameterErr, 'Subject'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostAndSendInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        DocumentNo: Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can post and send a sales invoice through the API.
        Initialize(true);

        // [GIVEN] Draft sales invoice exists
        CreateDraftSalesInvoice(SalesHeader);
        CreateEmailParameters(SalesHeader);
        DocumentNo := SalesHeader."No.";
        DocumentId := SalesHeader.SystemId;
        Commit();
        VerifyDraftSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionPostAndSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Invoice is posted
        FindPostedInvoiceByPreAssignedNo(DocumentNo, SalesInvoiceHeader);
        VerifyPostedSalesInvoice(SalesInvoiceHeader."Draft Invoice SystemId", TempSalesInvoiceEntityAggregate.Status::Open);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"Document-Mailing");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can cancel a posted sales invoice through API.
        Initialize(false);

        // [GIVEN] Posted sales invoice exists
        CreatePostedSalesInvoice(SalesInvoiceHeader);
        DocumentId := SalesInvoiceHeader."Draft Invoice SystemId";
        Commit();
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Open);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionCancelTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Invoice is canceled
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCancelAndSendInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can cancel a posted sales invoice through API.
        Initialize(true);

        // [GIVEN] Posted sales invoice exists
        CreatePostedSalesInvoice(SalesInvoiceHeader);
        DocumentId := SalesInvoiceHeader."Draft Invoice SystemId";
        Commit();
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Open);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(
            DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionCancelAndSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Invoice is canceled
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Canceled);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"O365 Sales Cancel Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSendPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can send a posted sales invoice through the API.
        Initialize(true);

        // [GIVEN] Posted sales invoice exists
        CreatePostedSalesInvoice(SalesInvoiceHeader);
        DocumentId := SalesInvoiceHeader."Draft Invoice SystemId";
        Commit();
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Open);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"Document-Mailing");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSendDraftInvoice()
    var
        SalesHeader: Record "Sales Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can send a draft sales invoice through the API.
        Initialize(true);

        // [GIVEN] Draft sales invoice exists
        CreateDraftSalesInvoice(SalesHeader);
        DocumentId := SalesHeader.SystemId;
        Commit();
        VerifyDraftSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"Document-Mailing");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSendCanceledInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can send a draft sales invoice through the API.
        Initialize(true);

        // [GIVEN] Canceled sales invoice exists
        CreateCanceledSalesInvoice(SalesInvoiceHeader);
        DocumentId := SalesInvoiceHeader."Draft Invoice SystemId";
        Commit();
        VerifyPostedSalesInvoice(DocumentId, TempSalesInvoiceEntityAggregate.Status::Canceled);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Invoice Entity", InvoiceServiceNameTxt, ActionSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"O365 Sales Cancel Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSendQuote()
    var
        SalesHeader: Record "Sales Header";
        TempSalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer" temporary;
        DocumentId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can send a sales quote throug the API.
        Initialize(true);

        // [GIVEN] Draft sales quote exists
        CreateSalesQuote(SalesHeader);
        DocumentId := SalesHeader.SystemId;
        Commit();
        VerifySalesQuote(DocumentId, TempSalesQuoteEntityBuffer.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Quote Entity", QuoteServiceNameTxt, ActionSendTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Quote is sent
        VerifySalesQuote(DocumentId, TempSalesQuoteEntityBuffer.Status::Sent);

        // [THEN] Mailing job is created
        CheckJobQueueEntry(CODEUNIT::"Document-Mailing");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMakeInvoiceFromQuote()
    var
        SalesHeader: Record "Sales Header";
        TempSalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer" temporary;
        TempSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate" temporary;
        QuoteRecordRef: RecordRef;
        InvoiceRecordRef: RecordRef;
        DocumentId: Guid;
        DocumentNo: Code[20];
        ResponseText: Text;
        TargetURL: Text;
        QuoteEmailAddress: Text;
        QuoteEmailSubject: Text;
        InvoiceEmailAddress: Text;
        InvoiceEmailSubject: Text;
    begin
        // [SCENARIO] User can convert a sales quote to a sales invoice through the API.
        Initialize(false);

        // [GIVEN] Sales quote exists
        CreateSalesQuote(SalesHeader);
        CreateEmailParameters(SalesHeader);
        QuoteRecordRef.GetTable(SalesHeader);
        GetEmailParameters(QuoteRecordRef, QuoteEmailAddress, QuoteEmailSubject);
        DocumentId := SalesHeader.SystemId;
        DocumentNo := SalesHeader."No.";
        Commit();
        Assert.IsTrue(QuoteEmailAddress <> '', StrSubstNo(EmptyParameterErr, 'Address'));
        Assert.IsTrue(QuoteEmailSubject <> '', StrSubstNo(EmptyParameterErr, 'Subject'));
        VerifySalesQuote(DocumentId, TempSalesQuoteEntityBuffer.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Sales Quote Entity", QuoteServiceNameTxt, ActionMakeInvoiceTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Quote is deleted
        SalesHeader.Reset();
        SalesHeader.SetRange(Id, DocumentId);
        Assert.IsFalse(SalesHeader.FindFirst, QuoteStillExistsErr);

        // [THEN] Invoice is created
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Quote No.", DocumentNo);
        Assert.IsTrue(SalesHeader.FindFirst, CannotFindDraftInvoiceErr);
        Assert.AreNotEqual(DocumentId, SalesHeader.SystemId, InvoiceIdErr);
        VerifyDraftSalesInvoice(SalesHeader.SystemId, TempSalesInvoiceEntityAggregate.Status::Draft);

        // [THEN] Email parameters are deleted
        InvoiceRecordRef.GetTable(SalesHeader);
        GetEmailParameters(InvoiceRecordRef, InvoiceEmailAddress, InvoiceEmailSubject);
        Assert.AreEqual('', InvoiceEmailAddress, StrSubstNo(NotEmptyParameterErr, 'Address'));
        Assert.AreEqual('', InvoiceEmailSubject, StrSubstNo(NotEmptyParameterErr, 'Subject'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostGenJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BalAccountNo: Code[20];
        CustomerNo: Code[20];
        Customer2No: Code[20];
        BalAccountType: Option;
        Amount: Decimal;
        Amount2: Decimal;
        GenJournalBatchId: Guid;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [GIVEN] A general journal batch with a general journal line
        BalAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting;
        BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
        CustomerNo := LibrarySales.CreateCustomerNo;
        Customer2No := LibrarySales.CreateCustomerNo;
        Amount := LibraryRandom.RandDecInRange(10000, 50000, 2);
        Amount2 := LibraryRandom.RandDecInRange(10000, 50000, 2);
        CreateGeneralJournalBatch(GenJournalBatch, BalAccountType, BalAccountNo);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer2No, Amount2);
        GenJournalBatchId := GenJournalBatch.Id;
        Commit();

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(GenJournalBatchId, PAGE::"Journal Entity", JournalServiceNameTxt, ActionPostTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] The general journal line is posted
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Amount, Amount);
        Assert.IsTrue(CustLedgerEntry.FindFirst, GenJournalLineNotPostedErr);
        CustLedgerEntry.SetRange("Customer No.", Customer2No);
        CustLedgerEntry.SetRange(Amount, Amount2);
        Assert.IsTrue(CustLedgerEntry.FindFirst, GenJournalLineNotPostedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TempPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate" temporary;
        DraftInvoiceRecordRef: RecordRef;
        DocumentId: Guid;
        DocumentNo: Code[20];
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can post a purchase invoice through the API.
        Initialize(false);

        // [GIVEN] Draft purchase invoice exists
        CreateDraftPurchaseInvoice(PurchaseHeader);
        DraftInvoiceRecordRef.GetTable(PurchaseHeader);
        DocumentId := PurchaseHeader.SystemId;
        DocumentNo := PurchaseHeader."No.";
        Commit();

        VerifyDraftPurchaseInvoice(DocumentId, TempPurchInvEntityAggregate.Status::Draft);

        // [WHEN] A POST request is made to the API.
        TargetURL :=
          LibraryGraphMgt.CreateTargetURLWithSubpage(DocumentId, PAGE::"Purchase Invoice Entity", PurchInvServiceNameTxt, ActionPostTxt);
        PostActionToWebService(TargetURL, '', ResponseText);

        // [THEN] Response should be empty
        Assert.AreEqual('', ResponseText, NotEmptyResponseErr);

        // [THEN] Invoice is posted
        FindPostedPurchaseInvoiceByPreAssignedNo(DocumentNo, PurchInvHeader);
        VerifyPostedPurchaseInvoice(PurchInvHeader."Draft Invoice SystemId", TempPurchInvEntityAggregate.Status::Open);
    end;

    local procedure CreateDraftSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SetCustomerEmail(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateDraftPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
    end;

    local procedure CreatePostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        InvoiceCode: Code[20];
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        InvoiceCode := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        SalesInvoiceHeader.Get(InvoiceCode);
        SetCustomerEmail(SalesInvoiceHeader."Sell-to Customer No.");
    end;

    local procedure CreateCanceledSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CreatePostedSalesInvoice(SalesInvoiceHeader);
        CODEUNIT.Run(CODEUNIT::"Correct Posted Sales Invoice", SalesInvoiceHeader);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");
        SetCustomerEmail(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateSMTPMailSetup()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        IsNew: Boolean;
    begin
        IsNew := not SMTPMailSetup.FindFirst;

        if IsNew then
            SMTPMailSetup.Init();
        SMTPMailSetup."SMTP Server" := 'SomeServer';
        SMTPMailSetup."SMTP Server Port" := 1000;
        SMTPMailSetup."Secure Connection" := true;
        SMTPMailSetup.Authentication := SMTPMailSetup.Authentication::Basic;
        SMTPMailSetup."User ID" := 'somebody@somewhere.com';
        SMTPMailSetup.SetPassword('Some Password');
        if IsNew then
            SMTPMailSetup.Insert(true)
        else
            SMTPMailSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateEmailParameters(var SalesHeader: Record "Sales Header")
    var
        EmailParameter: Record "Email Parameter";
    begin
        EmailParameter.SaveParameterValue(
          SalesHeader."No.", SalesHeader."Document Type",
          EmailParameter."Parameter Type"::Address,
          StrSubstNo('%1@home.local', CopyStr(CreateGuid, 2, 8)));
        EmailParameter.SaveParameterValue(
          SalesHeader."No.", SalesHeader."Document Type",
          EmailParameter."Parameter Type"::Subject, Format(CreateGuid));
    end;

    local procedure GetEmailParameters(var RecordRef: RecordRef; var Email: Text; var Subject: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EmailParameter: Record "Email Parameter";
    begin
        Email := '';
        Subject := '';
        case RecordRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecordRef.SetTable(SalesHeader);
                    if EmailParameter.GetEntryWithReportUsage(
                         SalesHeader."No.", SalesHeader."Document Type", EmailParameter."Parameter Type"::Address)
                    then
                        Email := EmailParameter.GetParameterValue;
                    if EmailParameter.GetEntryWithReportUsage(
                         SalesHeader."No.", SalesHeader."Document Type", EmailParameter."Parameter Type"::Subject)
                    then
                        Subject := EmailParameter.GetParameterValue;
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvoiceHeader);
                    if EmailParameter.GetEntryWithReportUsage(
                         SalesInvoiceHeader."No.", SalesHeader."Document Type"::Invoice, EmailParameter."Parameter Type"::Address)
                    then
                        Email := EmailParameter.GetParameterValue;
                    if EmailParameter.GetEntryWithReportUsage(
                         SalesInvoiceHeader."No.", SalesHeader."Document Type"::Invoice, EmailParameter."Parameter Type"::Subject)
                    then
                        Subject := EmailParameter.GetParameterValue;
                end;
        end;
    end;

    local procedure SetCustomerEmail(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."E-Mail" := 'somebody@somewhere.com';
        Customer.Modify(true);
    end;

    local procedure FindPostedInvoiceByPreAssignedNo(PreAssignedNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        Assert.IsTrue(SalesInvoiceHeader.FindFirst, CannotFindPostedInvoiceErr);
    end;

    local procedure FindPostedPurchaseInvoiceByPreAssignedNo(PreAssignedNo: Code[20]; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        PurchInvHeader.SetCurrentKey("Pre-Assigned No.");
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        Assert.IsTrue(PurchInvHeader.FindFirst, CannotFindPostedInvoiceErr);
    end;

    local procedure GetJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; CodeunitID: Integer): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);
        exit(JobQueueEntry.FindFirst);
    end;

    local procedure CheckJobQueueEntry(CodeunitID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not GetJobQueueEntry(JobQueueEntry, CodeunitID) then
            Error(MailingJobErr);
        JobQueueEntry.Cancel;
    end;

    local procedure DeleteJobQueueEntry(CodeunitID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        while JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, CodeunitID) do
            JobQueueEntry.Cancel;
    end;

    local procedure VerifyDraftSalesInvoice(DocumentId: Guid; Status: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesHeader.SetRange(Id, DocumentId);
        Assert.IsTrue(SalesHeader.FindFirst, CannotFindDraftInvoiceErr);

        SalesInvoiceEntityAggregate.SetRange(Id, DocumentId);
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindFirst, CannotFindDraftInvoiceErr);
        Assert.AreEqual(Status, SalesInvoiceEntityAggregate.Status, InvoiceStatusErr);
    end;

    local procedure VerifyDraftPurchaseInvoice(DocumentId: Guid; Status: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        PurchaseHeader.SetRange(Id, DocumentId);
        Assert.IsTrue(PurchaseHeader.FindFirst, CannotFindDraftInvoiceErr);

        PurchInvEntityAggregate.SetRange(Id, DocumentId);
        Assert.IsTrue(PurchInvEntityAggregate.FindFirst, CannotFindDraftInvoiceErr);
        Assert.AreEqual(Status, PurchInvEntityAggregate.Status, InvoiceStatusErr);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentId: Guid; Status: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesInvoiceHeader.SetRange("Draft Invoice SystemId", DocumentId);
        Assert.IsTrue(SalesInvoiceHeader.FindFirst, CannotFindPostedInvoiceErr);

        SalesInvoiceEntityAggregate.SetRange(Id, DocumentId);
        Assert.IsTrue(SalesInvoiceEntityAggregate.FindFirst, CannotFindPostedInvoiceErr);
        Assert.AreEqual(Status, SalesInvoiceEntityAggregate.Status, InvoiceStatusErr);
    end;

    local procedure VerifyPostedPurchaseInvoice(DocumentId: Guid; Status: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        PurchInvHeader.SetRange("Draft Invoice SystemId", DocumentId);
        Assert.IsTrue(PurchInvHeader.FindFirst, CannotFindPostedInvoiceErr);

        PurchInvEntityAggregate.SetRange(Id, DocumentId);
        Assert.IsTrue(PurchInvEntityAggregate.FindFirst, CannotFindPostedInvoiceErr);
        Assert.AreEqual(Status, PurchInvEntityAggregate.Status, InvoiceStatusErr);
    end;

    local procedure VerifySalesQuote(DocumentId: Guid; Status: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        SalesHeader.SetRange(Id, DocumentId);
        Assert.IsTrue(SalesHeader.FindFirst, CannotFindQuoteErr);

        SalesQuoteEntityBuffer.SetRange(Id, DocumentId);
        Assert.IsTrue(SalesQuoteEntityBuffer.FindFirst, CannotFindQuoteErr);
        Assert.AreEqual(Status, SalesQuoteEntityBuffer.Status, QuoteStatusErr);
    end;

    local procedure PostActionToWebService(TargetURL: Text; JSONBody: Text; var ResponseText: Text)
    begin
        PostActionToWebServiceExtended(TargetURL, JSONBody, ResponseText, 204);
    end;

    local procedure PostActionToWebServiceExtended(TargetURL: Text; JSONBody: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    begin
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, ExpectedResponseCode);
    end;
}

