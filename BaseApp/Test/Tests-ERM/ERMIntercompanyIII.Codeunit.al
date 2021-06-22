codeunit 134154 "ERM Intercompany III"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ICSetupPageHandler')]
    [Scope('OnPrem')]
    procedure TestConfirmYesOpensIntercompanySetupWhenSetupIsMissing()
    var
        CompanyInformation: Record "Company Information";
        ICPartnerList: TestPage "IC Partner List";
    begin
        // [SCENARIO ] When Intercompany Setup is missing, opening the Intercompany Partners page opens up a confirmation to setup intercompany information. Invoking Yes on the
        // confirmation opens up the Intercompany Setup page
        Initialize();

        // [GIVEN] Company Information where IC Partner Code = ''
        CompanyInformation.Get();
        CompanyInformation.Validate("IC Partner Code", '');
        CompanyInformation.Modify(true);

        // [WHEN] Intercompany Partners page is not opened
        asserterror ICPartnerList.OpenEdit;

        // [THEN] Verification is that the ConfirmHandler is hit and the ICSetup page is hit
    end;

    [Test]
    [HandlerFunctions('ComfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestConfirmNoDoesNotOpenIntercompanySetupWhenSetupIsMissing()
    var
        CompanyInformation: Record "Company Information";
        ICPartnerList: TestPage "IC Partner List";
    begin
        // [SCENARIO ] When Intercompany Setup is missing, opening the Intercompany Partners page opens up a confirmation to setup intercompany information. Invoking No on the
        // confirmation does not open up the Intercompany Setup page
        Initialize();

        // [GIVEN] Company Information where IC Partner Code = ''
        CompanyInformation.Get();
        CompanyInformation.Validate("IC Partner Code", '');
        CompanyInformation.Modify(true);

        // [WHEN] Intercompany Partners page is not opened
        asserterror ICPartnerList.OpenEdit;

        // [THEN] Verification is that the ConfirmHandler is hit and the ICSetup page is not
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoConfirmWhenIntercompanySetupExists()
    var
        CompanyInformation: Record "Company Information";
        ICPartnerList: TestPage "IC Partner List";
    begin
        // [SCENARIO ] When Intercompany Setup exists, opening the Intercompany Partners page
        // does not open up a confirmation but opens Intercompany Partners page.
        Initialize();

        // [GIVEN] Company Information where IC Partner Code <> ''
        CompanyInformation.Get();
        CompanyInformation.Validate("IC Partner Code", CopyStr(
            LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("IC Partner Code"), DATABASE::"Company Information"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Company Information", CompanyInformation.FieldNo("IC Partner Code"))));
        CompanyInformation.Modify(true);

        // [WHEN] Intercompany Partners page is opened
        ICPartnerList.OpenEdit;

        // [THEN] Verification is that the ConfirmHandler is not hit
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesDocumentFromICSalesDocWithDimension()
    var
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Dimensions]
        // [SCENARIO 227855] Sales Order should contains merged Dimension Set from Customer and IC inbox
        Initialize();

        // [GIVEN] Dimensions and Dimension Values:
        // [GIVEN] Dimension "D1" with Dimension Value "DV1"
        // [GIVEN] Dimension "D2" with Dimension Values "DV2-1" and "DV2-1"
        // [GIVEN] Dimension "D3" with Dimension Value "DV3"
        // [GIVEN] Dimension "D4" with Dimension Value "DV4"
        CreateSetOfDimValues(DimensionValue);

        // [GIVEN] Customer with Default Dimensions:
        // [GIVEN] Dimension - "D1" and "Dimension Value" - "DV1"
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-1"
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);

        // [GIVEN] IC Inbox Sales Order with
        // [GIVEN] Dimensions of Sales Header
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-2"
        // [GIVEN] Dimension - "D3" and "Dimension Value" - "DV3"
        // [GIVEN] Dimensions of Sales Line
        // [GIVEN] Dimension - "D4" and "Dimension Value" - "DV4"
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, CustomerNo);

        // [WHEN] Invoke CreateSalesDocument
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate);

        // [THEN] Created Sales Order has dimensions:
        // [THEN] Sales header:
        // [THEN] Dimension "D1" with Dimension Value "DV1"
        // [THEN] Dimension "D2" with Dimension Value "DV2-2"
        // [THEN] Dimension "D3" with Dimension Value "DV3"
        // [THEN] Sales Line:
        // [THEN] Dimensions are same as in the header and
        // [THEN] Dimension "D4" with Dimension Value "DV4"
        VerifySalesDocDimSet(DimensionValue, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchDocumentFromICPurchDocWithDimension()
    var
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Dimensions]
        // [SCENARIO 227855] Purchase Order should contains merged Dimension Set from Vendor and IC inbox
        Initialize();

        // [GIVEN] Dimensions and Dimension Values:
        // [GIVEN] Dimension "D1" with Dimension Value "DV1"
        // [GIVEN] Dimension "D2" with Dimension Values "DV2-1" and "DV2-2"
        // [GIVEN] Dimension "D3" with Dimension Value "DV3"
        // [GIVEN] Dimension "D4" with Dimension Value "DV4"
        CreateSetOfDimValues(DimensionValue);

        // [GIVEN] Vendor with Default Dimensions:
        // [GIVEN] Dimension - "D1" and "Dimension Value" - "DV1"
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-1"
        VendorNo := CreateVendorWithDefaultDimensions(DimensionValue);

        // [GIVEN] IC Inbox Purchase Order with
        // [GIVEN] Dimensions of Purchase Header
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-2"
        // [GIVEN] Dimension - "D3" and "Dimension Value" - "DV3"
        // [GIVEN] Dimensions of Purchase Line
        // [GIVEN] Dimension - "D4" and "Dimension Value" - "DV4"
        MockICInboxPurchOrder(ICInboxPurchaseHeader, DimensionValue, VendorNo);

        // [WHEN] Invoke CreatePurchDocument
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate);

        // [THEN] Created Purchase Order has dimensions:
        // [THEN] Purchase header:
        // [THEN] Dimension "D1" with Dimension Value "DV1"
        // [THEN] Dimension "D2" with Dimension Value "DV2-2"
        // [THEN] Dimension "D3" with Dimension Value "DV3"
        // [THEN] Purchase Line:
        // [THEN] Dimensions are same as in the header and
        // [THEN] Dimension "D4" with Dimension Value "DV4"
        VerifyPurchDocDimSet(DimensionValue, VendorNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreateICDimValuesFromDimValuesWithBeginEndTotalAndZeroIndentation()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ExpectedIndentation: array[6] of Integer;
    begin
        // [FEATURE] [Indentation] [Dimensions]
        // [SCENARIO 273581] Create IC Dimension Values from Dimension Values with Begin-Total/End-Total types and zero indentation.
        Initialize();

        // [GIVEN] Dimension Values of Begin-Total and End-Total types with nested Dimension Values. All records have zero Indentation.
        CreateDimValuesBeginEndTotalZeroIndentation(DimensionValue, ExpectedIndentation);

        // [WHEN] Create IC Dimension Values from Dimension Values.
        RunCopyICDimensionsFromDimensions;

        // [THEN] Indentation of nested IC Dimension Values is greater than zero. Indentation of children is 1 greater than the parent's indentation.
        VerifyIndentationICDimensionValuesAfterCopy(DimensionValue, ExpectedIndentation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoSendWorksForMultilineTransactions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICGLAccount: Record "IC G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        CompanyInformation: Record "Company Information";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Journal] [Post]
        // [SCENARIO 279681] User can post a multi-line IC transaction with Auto-send enabled
        Initialize();

        // [GIVEN] An IC journal batch, IC Partner Code, IC G/L Account, DocumentNo and an amount
        ICPartnerCode := CreateICPartnerWithInbox;
        LibraryERM.CreateICGLAccount(ICGLAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDec(1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID;

        // [GIVEN] Auto Send Transactions was enabled
        CompanyInformation.Get();
        CompanyInformation."Auto. Send Transactions" := true;
        CompanyInformation."IC Partner Code" := ICPartnerCode;
        CompanyInformation.Modify();

        // [GIVEN] 2 IC General journal lines for 1 Document No
        CreateICGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", '', ICGLAccount."No.", Amount, DocumentNo);
        CreateICGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner", ICPartnerCode,
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '', -Amount, DocumentNo);

        // [WHEN] Posting journal batch
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(HandledICOutboxTrans);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingGenJournalLineDoesntCallIntercompanyCodeunitOnNonICLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CodeCoverage: Record "Code Coverage";
    begin
        // [FEATURE] [Journal] [Post]
        // [SCENARIO 290373] When posting non-InterCompany Gen. Journal Line - Codeunit "IC Outbox Export" is not called
        Initialize();
        CodeCoverageMgt.StopApplicationCoverage;

        // [GIVEN] A non-InterCompany General Journal Batch
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] A Gen. Journal Line in this Journal Batch
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Post this Gen. Journal Line
        CodeCoverageMgt.StartApplicationCoverage;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CodeCoverageMgt.StopApplicationCoverage;

        // [THEN] Codeunit "IC Outbox Export" is not called
        Assert.AreEqual(
          0, CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"IC Outbox Export", ''),
          'IC Outbox Export was called');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryOfPostedSalesInvoice()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Post]
        // [SCENARIO 305580] Posting Sales Invoice with non-default Bill-to Customer with IC Partner Code results in Ledger Entry having the same IC Partner Code
        Initialize();

        // [GIVEN] Customer "X" with IC Partner Code "Y".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo);
        Customer.Modify(true);

        // [GIVEN] Sales Invoice with non-default Bill-to Customer "Y".
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [WHEN] Sales Invoice is posted.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Ledger Entry has IC Partner Code "Y".
        CustLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        CustLedgerEntry.FindFirst;
        Assert.AreEqual(Customer."IC Partner Code", CustLedgerEntry."IC Partner Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryOfPostedSalesInvoice()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase Invoice] [Post]
        // [SCENARIO 305580] Posting Purchase Invoice with non-default Pay-to Vendor with IC Partner Code results in Ledger Entry having the same IC Partner Code
        Initialize();

        // [GIVEN] Vendor "X" with IC Partner Code "Y".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo);
        Vendor.Modify(true);

        // [GIVEN] Sales Invoice with non-default Bill-to Customer "Y".
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [WHEN] Purchase Invoice is posted.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Ledger Entry has IC Partner Code "Y".
        VendorLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        VendorLedgerEntry.FindFirst;
        Assert.AreEqual(Vendor."IC Partner Code", VendorLedgerEntry."IC Partner Code", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Intercompany III");

        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Intercompany III");
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Intercompany III");
    end;

    local procedure CreateSetOfDimValues(var DimensionValue: array[5] of Record "Dimension Value")
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], DimensionValue[2]."Dimension Code");
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[5]);
    end;

    local procedure CreateICGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Option; AccountNo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20]; ICPartnerGLAccNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("IC Partner G/L Acc. No.", ICPartnerGLAccNo);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateICPartnerWithInbox(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::Database);
        ICPartner.Validate("Inbox Details", CompanyName);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateDimValuesBeginEndTotalZeroIndentation(var DimensionValue: array[6] of Record "Dimension Value"; var ExpectedIndentation: array[6] of Integer)
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateDimensionValue(
          DimensionValue[1], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[1]."Dimension Value Type"::"Begin-Total", '', false, 0);
        ExpectedIndentation[1] := 0;

        CreateDimensionValue(
          DimensionValue[2], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[2]."Dimension Value Type"::"Begin-Total", '', false, 0);
        ExpectedIndentation[2] := 1;  // incremented by 1 due to "Begin-Total" type above

        CreateDimensionValue(
          DimensionValue[3], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[3]."Dimension Value Type"::Standard, '', false, 0);
        ExpectedIndentation[3] := 2;  // incremented by 1 due to "Begin-Total" type above

        CreateDimensionValue(
          DimensionValue[4], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[4]."Dimension Value Type"::Standard, '', false, 0);
        ExpectedIndentation[4] := 2;  // not updated because the type is not "End-Total" and "Begin-Total" is not above

        CreateDimensionValue(
          DimensionValue[5], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[5]."Dimension Value Type"::"End-Total", '', false, 0);
        ExpectedIndentation[5] := 1;  // decremented by 1 due to "End-Total" type

        CreateDimensionValue(
          DimensionValue[6], Dimension.Code, LibraryUtility.GenerateGUID,
          DimensionValue[6]."Dimension Value Type"::"End-Total", '', false, 0);
        ExpectedIndentation[6] := 0;  // decremented by 1 due to "End-Total" type
    end;

    local procedure CreateCustomerWithDefaultDimensions(DimensionValue: array[5] of Record "Dimension Value") CustomerNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure CreateVendorWithDefaultDimensions(DimensionValue: array[5] of Record "Dimension Value") VendorNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo;
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; "Code": Code[20]; Type: Option; Totaling: Text[250]; Blocked: Boolean; Indentation: Integer)
    begin
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Code, DimensionCode);
        DimensionValue.Validate("Dimension Value Type", Type);
        DimensionValue.Validate(Totaling, Totaling);
        DimensionValue.Validate(Blocked, Blocked);
        DimensionValue.Validate(Indentation, Indentation);
        DimensionValue.Modify(true);
    end;

    local procedure GetICDimensionValueFromDimensionValue(var ICDimensionValue: Record "IC Dimension Value"; DimensionValue: Record "Dimension Value")
    begin
        ICDimensionValue.Reset();
        ICDimensionValue.SetRange("Dimension Code", DimensionValue."Dimension Code");
        ICDimensionValue.SetRange(Code, DimensionValue.Code);
        ICDimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type");
        ICDimensionValue.FindFirst;
    end;

    local procedure MockICInboxSalesOrder(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; DimensionValue: array[5] of Record "Dimension Value"; CustomerNo: Code[20])
    begin
        MockICInboxSalesHeader(ICInboxSalesHeader, CustomerNo);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[3], DATABASE::"IC Inbox Sales Header", 0);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[4], DATABASE::"IC Inbox Sales Header", 0);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[5], DATABASE::"IC Inbox Sales Line", MockICInboxSalesLine(ICInboxSalesHeader));
    end;

    local procedure MockICInboxSalesHeader(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; CustomerNo: Code[20])
    begin
        ICInboxSalesHeader.Init();
        ICInboxSalesHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxSalesHeader, ICInboxSalesHeader.FieldNo("IC Transaction No."));
        ICInboxSalesHeader."IC Partner Code" :=
          LibraryUtility.GenerateRandomCode(ICInboxSalesHeader.FieldNo("IC Partner Code"), DATABASE::"IC Inbox Sales Header");
        ICInboxSalesHeader."Document Type" := ICInboxSalesHeader."Document Type"::Order;
        ICInboxSalesHeader."Sell-to Customer No." := CustomerNo;
        ICInboxSalesHeader."Bill-to Customer No." := CustomerNo;
        ICInboxSalesHeader."Posting Date" := WorkDate;
        ICInboxSalesHeader."Document Date" := WorkDate;
        ICInboxSalesHeader.Insert();
    end;

    local procedure MockICInboxSalesLine(ICInboxSalesHeader: Record "IC Inbox Sales Header"): Integer
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
    begin
        ICInboxSalesLine.Init();
        ICInboxSalesLine."Line No." :=
          LibraryUtility.GetNewRecNo(ICInboxSalesLine, ICInboxSalesLine.FieldNo("Line No."));
        ICInboxSalesLine."IC Transaction No." := ICInboxSalesHeader."IC Transaction No.";
        ICInboxSalesLine."IC Partner Code" := ICInboxSalesHeader."IC Partner Code";
        ICInboxSalesLine."Transaction Source" := ICInboxSalesHeader."Transaction Source";
        ICInboxSalesLine."IC Partner Ref. Type" := ICInboxSalesLine."IC Partner Ref. Type"::Item;
        ICInboxSalesLine."IC Partner Reference" := LibraryInventory.CreateItemNo;
        ICInboxSalesLine.Insert();
        exit(ICInboxSalesLine."Line No.");
    end;

    local procedure MockICInboxPurchOrder(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; DimensionValue: array[5] of Record "Dimension Value"; VendorNo: Code[20])
    begin
        MockICInboxPurchHeader(ICInboxPurchaseHeader, VendorNo);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[3], DATABASE::"IC Inbox Purchase Header", 0);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[4], DATABASE::"IC Inbox Purchase Header", 0);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[5], DATABASE::"IC Inbox Purchase Line", MockICInboxPurchLine(ICInboxPurchaseHeader));
    end;

    local procedure MockICInboxPurchHeader(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; VendorNo: Code[20])
    begin
        ICInboxPurchaseHeader.Init();
        ICInboxPurchaseHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxPurchaseHeader, ICInboxPurchaseHeader.FieldNo("IC Transaction No."));
        ICInboxPurchaseHeader."IC Partner Code" :=
          LibraryUtility.GenerateRandomCode(ICInboxPurchaseHeader.FieldNo("IC Partner Code"), DATABASE::"IC Inbox Purchase Header");
        ICInboxPurchaseHeader."Document Type" := ICInboxPurchaseHeader."Document Type"::Order;
        ICInboxPurchaseHeader."Buy-from Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Pay-to Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Posting Date" := WorkDate;
        ICInboxPurchaseHeader."Document Date" := WorkDate;
        ICInboxPurchaseHeader.Insert();
    end;

    local procedure MockICInboxPurchLine(ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"): Integer
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
    begin
        ICInboxPurchaseLine.Init();
        ICInboxPurchaseLine."Line No." :=
          LibraryUtility.GetNewRecNo(ICInboxPurchaseLine, ICInboxPurchaseLine.FieldNo("Line No."));
        ICInboxPurchaseLine."IC Transaction No." := ICInboxPurchaseHeader."IC Transaction No.";
        ICInboxPurchaseLine."IC Partner Code" := ICInboxPurchaseHeader."IC Partner Code";
        ICInboxPurchaseLine."Transaction Source" := ICInboxPurchaseHeader."Transaction Source";
        ICInboxPurchaseLine."IC Partner Ref. Type" := ICInboxPurchaseLine."IC Partner Ref. Type"::Item;
        ICInboxPurchaseLine."IC Partner Reference" := LibraryInventory.CreateItemNo;
        ICInboxPurchaseLine.Insert();
        exit(ICInboxPurchaseLine."Line No.");
    end;

    local procedure MockICDocumentDimension(ICPartnerCode: Code[20]; TransactionNo: Integer; DimensionValue: Record "Dimension Value"; TableID: Integer; LineNo: Integer)
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        ICDocumentDimension: Record "IC Document Dimension";
    begin
        LibraryDimension.CreateAndMapICDimFromDim(ICDimension, DimensionValue."Dimension Code");
        LibraryDimension.CreateAndMapICDimValueFromDimValue(ICDimensionValue, DimensionValue.Code, DimensionValue."Dimension Code");
        ICDocumentDimension.Init();
        ICDocumentDimension."IC Partner Code" := ICPartnerCode;
        ICDocumentDimension."Transaction No." := TransactionNo;
        ICDocumentDimension."Table ID" := TableID;
        ICDocumentDimension."Dimension Code" := ICDimensionValue."Dimension Code";
        ICDocumentDimension."Dimension Value Code" := ICDimensionValue.Code;
        ICDocumentDimension."Line No." := LineNo;
        ICDocumentDimension.Insert();
    end;

    local procedure RunCopyICDimensionsFromDimensions()
    var
        ICDimensions: TestPage "IC Dimensions";
    begin
        ICDimensions.OpenView;
        ICDimensions.CopyFromDimensions.Invoke;
        ICDimensions.Close;
    end;

    local procedure SetFilterDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionValue: Record "Dimension Value")
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifySalesDocDimSet(DimensionValue: array[5] of Record "Dimension Value"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst;
        VerifyDimensionSet(DimensionValue, SalesHeader."Dimension Set ID");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        VerifyLineDimSet(DimensionValue, SalesLine."Dimension Set ID");
    end;

    local procedure VerifyPurchDocDimSet(DimensionValue: array[5] of Record "Dimension Value"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst;
        VerifyDimensionSet(DimensionValue, PurchaseHeader."Dimension Set ID");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
        VerifyLineDimSet(DimensionValue, PurchaseLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionSet(DimensionValue: array[5] of Record "Dimension Value"; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[1]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[2]);
        Assert.RecordIsEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[3]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[4]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    local procedure VerifyLineDimSet(DimensionValue: array[5] of Record "Dimension Value"; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        VerifyDimensionSet(DimensionValue, DimSetID);
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[5]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    local procedure VerifyIndentationICDimensionValuesAfterCopy(DimensionValue: array[6] of Record "Dimension Value"; ExpectedIndentation: array[6] of Integer)
    var
        ICDimensionValue: Record "IC Dimension Value";
        i: Integer;
    begin
        for i := 1 to ArrayLen(DimensionValue) do begin
            GetICDimensionValueFromDimensionValue(ICDimensionValue, DimensionValue[i]);
            ICDimensionValue.TestField(Indentation, ExpectedIndentation[i]);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ComfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ICSetupPageHandler(var ICSetup: TestPage "IC Setup")
    begin
        ICSetup.Cancel.Invoke;
    end;
}

