// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 148053 "OIOUBL-ERM Elec Document Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun();
    begin
        // [FEATURE] [OIOUBL]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLReadOnServer: Codeunit "Library - XML Read OnServer";
        LibraryUtility: Codeunit "Library - Utility";
        OIOUBLNewFileMock: Codeunit "OIOUBL-File Events Mock";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AmountErr: Label '%1 must be %2 in %3.', Comment = '"%1:FieldCaption';
        GLNNoTxt: Label '3974567891234';
        IDTxt: Label 'cbc:ID';
        AccountingCostCodeTxt: Label 'cbc:AccountingCostCode';
        TaxAmountTxt: Label 'cbc:TaxExclusiveAmount';
        DefaultProfileIDTxt: Label 'Procurement-BilSim-1.0';
        WrongAllowanceChargeErr: Label 'Wrong value of "AllowanceCharge".';
        DefaultCodeTxt: Label 'DEFAULT', Comment = 'Translate as we translate default term in local languages';
        OIOUBLFormatNameTxt: Label 'OIOUBL';
        PEPPOLFormatNameTxt: Label 'PEPPOL 2.1';
        WrongInvoiceLineCountErr: Label 'Wrong count of "InvoiceLine".';
        WrongAllowanceTotalAmountErr: Label 'Wrong count of "AllowanceTotalAmount".';
        BaseQuantityTxt: Label 'cbc:BaseQuantity';

    [Test]
    procedure GLEntryAfterPostSalesInvoice();
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify the GL Entry created after posting Sales Invoice.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);

        // Verify.
        VerifyGLEntry(DocumentNo, -SalesLine.Amount);
    end;

    [Test]
    procedure GLEntryAfterPostSalesCreditMemo();
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify the GL Entry created after posting Sales Credit Memo.
        Initialize();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo");

        // Verify.
        VerifyGLEntry(DocumentNo, SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateAndPostSalesInvoiceWithSingleLine();
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice with Single Line.
        CreateAndPostSalesDocumentWithSingleLine(SalesLine."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateAndPostSalesCreditMemoWithSingleLine();
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Single Line.
        CreateAndPostSalesDocumentWithSingleLine(SalesLine."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos");
    end;

    local procedure CreateAndPostSalesDocumentWithSingleLine(DocumentType: Option; ReportID: Integer);
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [GIVEN] Posted Sales Document with a single line.
        Initialize();
        CreateSalesDocument(SalesLine, DocumentType, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := (SalesLine."Line Amount" * SalesLine."VAT %") / 100;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Electronic Invoice or Credit Memo created.
        RunReport(ReportID, DocumentNo);

        // [THEN] The following values are verified on generated xml file of Electronic Invoice or Credit Memo: Sales Document No., Tax Amount, BaseQuantity.
        VerifyDocumentNoAndTaxAmount(DocumentNo, TaxAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ElectronicSalesCreditMemoWithMultipleGL();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Multiple GL and different VAT type and %.
        CreateAndPostSalesDocumentWithMultipleGL(SalesHeader."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ElectronicSalesInvoiceWithMultipleGL();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice with Multiple GL and different VAT type and %.
        CreateAndPostSalesDocumentWithMultipleGL(SalesHeader."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices");
    end;

    local procedure CreateAndPostSalesDocumentWithMultipleGL(DocumentType: Option; ReportID: Integer);
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [GIVEN] Posted Sales Document with a multiple GL and different VAT type and %.
        Initialize();
        CreateSalesDocument(SalesLine, DocumentType, SalesLine.Type::"G/L Account", CreateGLAccount(FindNormalVAT()));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(FindZeroVAT()));
        CreateSalesLine(
        SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
        CreateGLAccount(FindReverseChargeVAT(VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT")));
        TaxAmount := CalculateTaxAmount(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Electronic Invoice or Credit Memo created.
        RunReport(ReportID, DocumentNo);

        // [THEN] The following values are verified on generated xml file of Electronic Invoice or Credit Memo: Sales Document No., Tax Amount, BaseQuantity.
        VerifyDocumentNoAndTaxAmount(DocumentNo, TaxAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ElectronicSalesCreditMemoMultipleItemsChargeItemAndGL();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Multiple Item,Charge Item and GL.
        CreateAndPostSalesDocumentMultipleItemsChargeItemAndGL(
        SalesHeader."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ElectronicSalesInvoiceMultipleItemsChargeItemAndGL();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice with Multiple Item,Charge Item and GL.
        CreateAndPostSalesDocumentMultipleItemsChargeItemAndGL(
        SalesHeader."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices");
    end;

    local procedure CreateAndPostSalesDocumentMultipleItemsChargeItemAndGL(DocumentType: Option; ReportID: Integer);
    var
        Item: Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [GIVEN] Posted Sales Document with a multiple Item, Charge Item and GL.
        Initialize();
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateSalesDocument(SalesLine, DocumentType, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        LibrarySales.CreateSalesLine(
        SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
        LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDec(10, 2));  // Random Value for Quantity.
        SalesLine.VALIDATE("Unit of Measure", UnitOfMeasure.Code);
        SalesLine.VALIDATE("Unit Price", LibraryRandom.RandDec(100, 2));  // Random Value for Unit Price.
        SalesLine.MODIFY(true);
        LibraryInventory.CreateItemChargeAssignment(
        ItemChargeAssignmentSales, SalesLine,
        SalesLine."Document Type"::Invoice, SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(FindNormalVAT()));
        TaxAmount := CalculateTaxAmount(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Electronic Invoice or Credit Memo created.
        RunReport(ReportID, DocumentNo);

        // [THEN] The following values are verified on generated xml file of Electronic Invoice or Credit Memo: Sales Document No., Tax Amount, BaseQuantity.
        VerifyDocumentNoAndTaxAmount(DocumentNo, TaxAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesCreditMemoSalesLineTypeBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Line Type Blank.
        CreateAndPostSalesDocumentSalesLineTypeBlank(
        SalesHeader."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos", FindStandardText(), '');  // Use Blank for Descrption.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesInvoiceSalesLineTypeBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice Sales Line Type Blank.
        CreateAndPostSalesDocumentSalesLineTypeBlank(
        SalesHeader."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices", FindStandardText(), '');  // Use Blank for Descrption.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesCreditMemoSalesLineNoBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Line No. Blank.
        CreateAndPostSalesDocumentSalesLineTypeBlank(
        SalesHeader."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos", '', 'Follow the Items Below');  // Use Blank for Sales Line No.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesInvoiceSalesLineNoBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice Sales Line No. Blank.
        CreateAndPostSalesDocumentSalesLineTypeBlank(
        SalesHeader."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices", '', 'Follow the Items Below');  // Use Blank for Sales Line No.
    end;

    local procedure CreateAndPostSalesDocumentSalesLineTypeBlank(DocumentType: Option; ReportID: Integer; LineNo: Code[20]; Descrption: Text[50]);
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [GIVEN] Created and Posted Sales Document Sales Line Type Blank
        Initialize();
        CreateSalesDocument(SalesLine, DocumentType, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLineWithBlankLines(
        SalesLine."Line No.", DocumentType, SalesHeader."No.", LineNo, Descrption);  // Use Blank for Descrption.
        TaxAmount := CalculateTaxAmount(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Electronic Invoice or Credit Memo created.
        RunReport(ReportID, DocumentNo);

        // [THEN] The following values are verified on generated xml file of Electronic Invoice or Credit Memo: Sales Document No., Tax Amount, BaseQuantity.
        VerifyDocumentNoAndTaxAmount(DocumentNo, TaxAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesCreditMemoSalesLineTypeAndNoBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Credit Memo from posted Sales Credit Memo with Type and Line No. Blank.
        CreateAndPostSalesDocumentSalesLineTypeAndNoBlank(
        SalesHeader."Document Type"::"Credit Memo", REPORT::"OIOUBL-Create Elec. Cr. Memos");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure ElectronicSalesInvoiceSalesLineTypeAndNoBlank();
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify created Electronic Invoice from posted Sales Invoice with Type and Line No. Blank.
        CreateAndPostSalesDocumentSalesLineTypeAndNoBlank(SalesHeader."Document Type"::Invoice, REPORT::"OIOUBL-Create Elec. Invoices");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckAllowanceChargeInOIOUBLReport();
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        ExpectedResult: Decimal;
    begin
        // [SCENARIO 377873] OIOUBL XML File shouldn'l contain XML node "LegalMonetaryTotal/AllowanceTotalAmount" and should contain XML node "InvoiceLine/AllowanceCharge" with line discount
        // [SCENARIO 280609] CurrencyID attribute has value of "LCY Code" of General Ledger Setup in exported OIOUBL file
        Initialize();

        // [GIVEN] "LCY Code" is "DKK" in "General Ledger Setup"
        // [GIVEN] Posted sales invoice with two sales lines
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] First sales line with line discount = "X"
        ExpectedResult := CreateSalesLineWithDiscount(SalesHeader, LibraryRandom.RandIntInRange(1, 50));

        // [GIVEN] Second sales line without line discount
        CreateSalesLineWithDiscount(SalesHeader, 0);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "OIOUBL-Create Elec. Invoices"
        RunReportCreateElecSalesInvoices(DocumentNo);

        // [THEN] OIOUBL XML file contains XML node "LegalMonetaryTotal/AllowanceTotalAmount"
        // [THEN] Contains XML node "InvoiceLine/cac:AllowanceCharge/cbc:Amount" with value = "X" for first invoice line
        // [THEN] Doesn't contain XML node "InvoiceLine/cac:AllowanceCharge" for second invoice line
        // [THEN] CurrencyID attribute is "DKK" in exported file
        VerifyAllowanceCharge(DocumentNo, ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesInvoiceToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 378908] Post And Send Sales Invoice to Disk = Electronic Document (OIOUBL) should create electronic document
        Initialize();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"OIOUBL-Export Sales Invoice");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document"; Sales Invoice;
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);

        // [WHEN] PostAndSend to Disk = Electronic Document.
        SalesInvoice.OPENEDIT();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.PostAndSend.INVOKE();

        // [THEN] Sales Invoice is posted
        // [THEN] OIOUBL Electronic Document is created at the location, specified in Sales Setup.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        SalesInvoiceHeader.TESTFIELD("OIOUBL-Electronic Invoice Created", true);
        VerifyElectronicSalesDocument(SalesInvoiceHeader."No.", SalesInvoiceHeader."OIOUBL-Account Code");
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Inv.", SalesInvoiceHeader."No.");

        DefaultDocumentSendingProfile.DELETE();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler')]
    procedure SendPostedSalesInvoiceToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 378908] Send Posted Sales Invoice to Disk = Electronic Document (OIOUBL) should create electronic document.
        Initialize();
        DocumentSendingProfile.DeleteAll();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"OIOUBL-Export Sales Invoice");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document", Format = OIOUBL; Posted Sales Invoice;
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);
        PostedDocNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);

        // [WHEN] Run "Send" for Posted Sales Invoice.
        SalesInvoiceHeader.SetRange("No.", PostedDocNo);
        SalesInvoiceHeader.SendRecords();

        // [THEN] OIOUBL Electronic Document is created at the location, specified in Sales Setup.
        SalesInvoiceHeader.Get(PostedDocNo);
        SalesInvoiceHeader.TESTFIELD("OIOUBL-Electronic Invoice Created", true);
        VerifyElectronicSalesDocument(SalesInvoiceHeader."No.", SalesInvoiceHeader."OIOUBL-Account Code");
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Inv.", SalesInvoiceHeader."No.");

        DefaultDocumentSendingProfile.Delete();
    end;

    [Test]
    [HandlerFunctions('ProfileSelectionMethodStrMenuHandler')]
    procedure SendMultiplePostedSalesInvoicesToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedDocNoLst: List of [Code[20]];
        AccountCodeLst: List of [Text[30]];
        PostedDocNoFilter: Text;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Zip]
        // [SCENARIO 318500] Send multiple Posted Sales Invoices to Disk = Electronic Document (OIOUBL).
        Initialize();
        DocumentSendingProfile.DeleteAll();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"OIOUBL-Export Sales Invoice");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document", Format = OIOUBL; three Posted Sales Invoices;
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);
        CreateMultiplePostedSalesDocuments(PostedDocNoLst, PostedDocNoFilter, SalesLine."Document Type"::Invoice, 3);

        // [WHEN] Run "Send" for these Posted Sales Invoices.
        SalesInvoiceHeader.SetFilter("No.", PostedDocNoFilter);
        SalesInvoiceHeader.SendRecords();

        // [THEN] One ZIP file is created at the location, specified in Sales Setup.
        // [THEN] ZIP file contains OIOUBL Electronic Document for each Posted Sales Invoice.
        foreach PostedDocNo in PostedDocNoLst do begin
            SalesInvoiceHeader.Get(PostedDocNo);
            SalesInvoiceHeader.TESTFIELD("OIOUBL-Electronic Invoice Created", true);
            VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Inv.", SalesInvoiceHeader."No.");
            AccountCodeLst.Add(SalesInvoiceHeader."OIOUBL-Account Code");
        end;
        VerifyElectronicSalesDocumentInZipArchive(PostedDocNoLst, AccountCodeLst);

        DefaultDocumentSendingProfile.Delete();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesInvoiceToDiskEDnonOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 299031] Post and Send Sales Invoice in case non-OIOUBL profile is selected.
        Initialize();
        UpdateCompanySwiftCode();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          PEPPOLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"Export Sales Inv. - PEPPOL 2.1");

        // [GIVEN] Document Sending Profile = PEPPOL; Sales Invoice.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", PEPPOLFormatNameTxt);

        // [WHEN] Post And Send to Disk = Electronic Document.
        SalesInvoice.OPENEDIT();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.PostAndSend.INVOKE();

        // [THEN] Sales Invoice is posted.
        // [THEN] Electronic Document is not created at the location, specified in Sales Setup - file path is not in the queue.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        SalesInvoiceHeader.TESTFIELD("OIOUBL-Electronic Invoice Created", false);
        LibraryVariableStorage.AssertEmpty();

        DefaultDocumentSendingProfile.DELETE();
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesInvoiceDiskIsNotElectronicDocument();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 299031] Post and Send Sales Invoice in case Disk = No in Document Sending Profile.
        Initialize();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"OIOUBL-Export Sales Invoice");

        // [GIVEN] Document Sending Profile = OIOUBL, Disk = No; Sales Invoice.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::No, OIOUBLFormatNameTxt);

        // [WHEN] Post And Send.
        SalesInvoice.OPENEDIT();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.PostAndSend.INVOKE();

        // [THEN] Sales Invoice is posted.
        // [THEN] Electronic Document is not created at the location, specified in Sales Setup - file path is not in the queue.
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader."No.");
        SalesInvoiceHeader.TESTFIELD("OIOUBL-Electronic Invoice Created", false);
        LibraryVariableStorage.AssertEmpty();

        DefaultDocumentSendingProfile.DELETE();
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesCreditMemoToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 378908] Post And Send Sales Credit Memo to Disk = Electronic Document (OIOUBL) should create electronic document
        Initialize();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"OIOUBL-Export Sales Cr. Memo");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document"; Sales Credit Memo;
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);

        // [WHEN] PostAndSend to Disk = Electronic Document.
        SalesCreditMemo.OPENEDIT();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.PostAndSend.INVOKE();

        // [THEN] Sales Credit Memo is posted.
        // [THEN] OIOUBL Electronic Document is created at the location, specified in Sales Setup.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        SalesCrMemoHeader.TESTFIELD("OIOUBL-Electronic Credit Memo Created", true);
        VerifyElectronicSalesDocument(SalesCrMemoHeader."No.", SalesCrMemoHeader."OIOUBL-Account Code");
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Cr. Memo", SalesCrMemoHeader."No.");

        DefaultDocumentSendingProfile.DELETE();
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler')]
    procedure SendPostedSalesCreditMemoToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 378908] Send Posted Sales Credit Memo to Disk = Electronic Document (OIOUBL) should create electronic document.
        Initialize();
        DocumentSendingProfile.DeleteAll();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"OIOUBL-Export Sales Cr. Memo");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document", Format = OIOUBL; Posted Sales Credit Memo;
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);
        PostedDocNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run "Send" for Posted Sales Credit Memo.
        SalesCrMemoHeader.SetRange("No.", PostedDocNo);
        SalesCrMemoHeader.SendRecords();

        // [THEN] OIOUBL Electronic Document is created at the location, specified in Sales Setup.
        SalesCrMemoHeader.Get(PostedDocNo);
        SalesCrMemoHeader.TESTFIELD("OIOUBL-Electronic Credit Memo Created", true);
        VerifyElectronicSalesDocument(SalesCrMemoHeader."No.", SalesCrMemoHeader."OIOUBL-Account Code");
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Cr. Memo", SalesCrMemoHeader."No.");

        DefaultDocumentSendingProfile.Delete();
    end;

    [Test]
    [HandlerFunctions('ProfileSelectionMethodStrMenuHandler')]
    procedure SendMultiplePostedSalesCreditMemosToDiskEDOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedDocNoLst: List of [Code[20]];
        AccountCodeLst: List of [Text[30]];
        PostedDocNoFilter: Text;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Zip]
        // [SCENARIO 318500] Send multiple Posted Sales Credit Memo to Disk = Electronic Document (OIOUBL).
        Initialize();
        DocumentSendingProfile.DeleteAll();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"OIOUBL-Export Sales Cr. Memo");

        // [GIVEN] DefaultDocumentSendingProfile Disk::"Electronic Document", Format = OIOUBL; three Posted Sales Credit Memos.
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", OIOUBLFormatNameTxt);
        CreateMultiplePostedSalesDocuments(PostedDocNoLst, PostedDocNoFilter, SalesLine."Document Type"::"Credit Memo", 3);

        // [WHEN] Run "Send" for these Posted Sales Credit Memos.
        SalesCrMemoHeader.SetFilter("No.", PostedDocNoFilter);
        SalesCrMemoHeader.SendRecords();

        // [THEN] One ZIP file is created at the location, specified in Sales Setup.
        // [THEN] ZIP file contains OIOUBL Electronic Document for each Posted Sales Credit Memo.
        foreach PostedDocNo in PostedDocNoLst do begin
            SalesCrMemoHeader.Get(PostedDocNo);
            SalesCrMemoHeader.TESTFIELD("OIOUBL-Electronic Credit Memo Created", true);
            VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Cr. Memo", SalesCrMemoHeader."No.");
            AccountCodeLst.Add(SalesCrMemoHeader."OIOUBL-Account Code");
        end;
        VerifyElectronicSalesDocumentInZipArchive(PostedDocNoLst, AccountCodeLst);

        DefaultDocumentSendingProfile.Delete();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesCreditMemoToDiskEDnonOIOUBL();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 299031] Post and Send Service Credit Memo in case non-OIOUBL profile is selected.
        Initialize();
        UpdateCompanySwiftCode();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          PEPPOLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"Export Sales Cr.M. - PEPPOL2.1");

        // [GIVEN] Document Sending Profile = PEPPOL; Sales Credit Memo.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::"Electronic Document", PEPPOLFormatNameTxt);

        // [WHEN] PostAndSend to Disk = Electronic Document.
        SalesCreditMemo.OPENEDIT();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.PostAndSend.INVOKE();

        // [THEN] Sales Credit Memo is posted.
        // [THEN] Electronic Document is created at the location, specified in Sales Setup - file path is not in the queue.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        SalesCrMemoHeader.TESTFIELD("OIOUBL-Electronic Credit Memo Created", false);
        LibraryVariableStorage.AssertEmpty();

        DefaultDocumentSendingProfile.DELETE();
    end;

    [Test]
    [HandlerFunctions('PostandSendModalPageHandler')]
    procedure PostAndSendSalesCreditMemoDiskIsNotElectronicDocument();
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Item: Record Item;
        DocumentSendingProfile: Record "Document Sending Profile";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 299031] Post and Send Service Credit Memo in case Disk = No in Document Sending Profile.
        Initialize();
        DocumentSendingProfile.DELETEALL();
        CreateElectronicDocumentFormat(
          OIOUBLFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"OIOUBL-Export Sales Cr. Memo");

        // [GIVEN] Document Sending Profile = OIOUBL, Disk = No; Sales Credit Memo.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");
        SetDocumentSendingProfile(DefaultDocumentSendingProfile, DefaultDocumentSendingProfile.Disk::No, OIOUBLFormatNameTxt);

        // [WHEN] Post And Send.
        SalesCreditMemo.OPENEDIT();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.PostAndSend.INVOKE();

        // [THEN] Sales Credit Memo is posted.
        // [THEN] Electronic Document is not created at the location, specified in Sales Setup - file path is not in the queue.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        SalesCrMemoHeader.TESTFIELD("OIOUBL-Electronic Credit Memo Created", false);
        LibraryVariableStorage.AssertEmpty();

        DefaultDocumentSendingProfile.DELETE();
    end;

    local procedure Initialize();
    var
        SalesHeader: Record "Sales Header";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        UpdateSalesReceivablesSetup();
        UpdateOIOUBLCountryRegionCode();
        LibraryVariableStorage.Clear();
        LibraryERM.DisableMyNotifications(CopyStr(UserId(), 1, 50), SalesHeader.GetModifyCustomerAddressNotificationId());

        DocumentSendingProfile.DeleteAll();
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile."Electronic Format" := OIOUBLFormatNameTxt;
        DocumentSendingProfile.Insert();

        OIOUBLNewFileMock.Setup(OIOUBLNewFileMock);
    end;

    local procedure CreateAndPostSalesDocumentSalesLineTypeAndNoBlank(DocumentType: Option; ReportID: Integer);
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [GIVEN] Created and Posted Sales Document Sales Line Type and Line No. Blank.
        Initialize();
        CreateSalesHeader(SalesHeader, DocumentType);
        CreateSalesLineWithBlankLines(SalesLine."Line No.", DocumentType, SalesHeader."No.", '', 'Test');  // Use Blank for Sales Line No.,Value not important required only for test Purpoase.
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        TaxAmount := CalculateTaxAmount(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Electronic Invoice or Credit Memo created.
        RunReport(ReportID, DocumentNo);

        // [THEN] The following values are verified on generated xml file of Electronic Invoice or Credit Memo: Sales Document No., Tax Amount, BaseQuantity.
        VerifyDocumentNoAndTaxAmount(DocumentNo, TaxAmount);
    end;

    local procedure CalculateTaxAmount(SalesHeader: Record "Sales Header"): Decimal;
    var
        TaxAmount: Decimal;
    begin
        SalesHeader.CALCFIELDS(Amount, "Amount Including VAT");
        TaxAmount := SalesHeader."Amount Including VAT" - SalesHeader.Amount;
        exit(TaxAmount);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option): Code[20];
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        CreateSalesDocument(SalesLine, DocumentType, SalesLine.Type::Item, LibraryInventory.CreateItem(Item));
        SalesHeader.GET(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateMultiplePostedSalesDocuments(var PostedDocNoLst: List of [Code[20]]; var PostedDocNoFilter: Text; DocumentType: Option; NumberOfDocuments: Integer);
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        Clear(PostedDocNoLst);
        PostedDocNoFilter := '';

        for i := 1 to NumberOfDocuments do begin
            PostedDocNoLst.Add(CreateAndPostSalesDocument(SalesLine, DocumentType));
            PostedDocNoFilter += PostedDocNoLst.Get(i) + '|';
        end;
        PostedDocNoFilter := DelChr(PostedDocNoFilter, '>', '|');
    end;

    local procedure CreateCustomer(): Code[20];
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.GET();
        LibrarySales.CreateCustomer(Customer);
        Customer.VALIDATE("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.VALIDATE("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Customer.VALIDATE(GLN, GLNNoTxt);
        Customer.MODIFY(true);
        exit(Customer."No.")
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20];
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.VALIDATE("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.VALIDATE("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.VALIDATE("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.MODIFY(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; Type: Option; No: Code[20]);
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType);
        CreateSalesLine(SalesLine, SalesHeader, Type, No);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option);
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.FindPostCode(PostCode);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.VALIDATE("Sell-to Contact", SalesHeader."No.");
        SalesHeader.VALIDATE("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.VALIDATE("Bill-to City", PostCode.City);
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Ship-to City", PostCode.City);
        SalesHeader.MODIFY(true);
        ClearVATRegistrationForCustomer(SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Option; No: Code[20]);
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibrarySales.CreateSalesLine(
        SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random Value for Quantity.
        SalesLine.VALIDATE("Unit Price", LibraryRandom.RandDec(10, 2));  // Random Value for Unit Price.
        SalesLine.VALIDATE("Unit of Measure", UnitOfMeasure.Code);
        SalesLine.MODIFY(true);
    end;

    local procedure CreateSalesLineWithBlankLines(LineNo: Integer; DocumentType: Option; DocumentNo: Code[20]; No: Code[20]; Description: Text[50]);
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.VALIDATE("Document Type", DocumentType);
        SalesLine.VALIDATE("Document No.", DocumentNo);
        SalesLine.VALIDATE("Line No.", LineNo + 1);  // Value Not Mandatory, require only for test
        SalesLine.INSERT(true);  // Feature Specific,Since Blank Type, No and Line Required in tests.
        SalesLine.VALIDATE(Type, SalesLine.Type::" ");
        SalesLine.VALIDATE("No.", No);
        SalesLine.VALIDATE(Description, Description);
        SalesLine.MODIFY(true);
    end;

    local procedure CreateSalesLineWithDiscount(SalesHeader: Record "Sales Header"; Discount: Integer): Decimal;
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesLine.VALIDATE("Line Discount %", Discount);
        SalesLine.MODIFY(true);
        exit(SalesLine."Inv. Discount Amount" + SalesLine."Line Discount Amount");
    end;

    local procedure CreateElectronicDocumentFormat(Code: Code[20]; Usage: Option; CodeunitID: Integer);
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        with ElectronicDocumentFormat do begin
            SetRange(Code, Code);
            DeleteAll();
            Validate(Code, Code);
            Validate(Usage, Usage);
            Validate("Codeunit ID", CodeunitID);
            Insert(true);
        end;
    end;

    local procedure CreateOIOUBLProfile(): Code[10];
    var
        OIOUBLProfile: Record "OIOUBL-Profile";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        with OIOUBLProfile do begin
            VALIDATE("OIOUBL-Code", LibraryUtility.GenerateRandomCode(FIELDNO("OIOUBL-Code"), DATABASE::"OIOUBL-Profile"));
            VALIDATE("OIOUBL-Profile ID", DefaultProfileIDTxt);

            INSERT(true);
            exit("OIOUBL-Code");
        end;
    end;

    local procedure ClearVATRegistrationForCustomer(CustomerNo: Code[20]);
    var
        Customer: Record Customer;
    begin
        Customer.GET(CustomerNo);
        Customer."VAT Registration No." := '';
        Customer.MODIFY();
    end;

    local procedure FindStandardText(): Code[20];
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.FINDFIRST();
        exit(StandardText.Code);
    end;

    local procedure FindNormalVAT(): Code[10];
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindReverseChargeVAT(VATCalculationType: Option): Code[10];
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        VATPostingSetup.VALIDATE("VAT %", 0); // Value 0 is required for zero Vat Amount;
        VATPostingSetup.MODIFY(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindZeroVAT(): Code[10];
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SETRANGE("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SETRANGE("VAT %", 0);
        VATPostingSetup.FINDFIRST();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; PreAssignedNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst();
    end;

    local procedure RunReport(ReportID: Integer; No: Code[20]);
    begin
        if ReportID = REPORT::"OIOUBL-Create Elec. Cr. Memos" then
            RunReportCreateElecSalesCrMemos(No)
        else
            RunReportCreateElecSalesInvoices(No);
    end;

    local procedure RunReportCreateElecSalesCrMemos(No: Code[20]);
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CreateElecSalesCrMemos: Report "OIOUBL-Create Elec. Cr. Memos";
    begin
        CLEAR(CreateElecSalesCrMemos);
        SalesCrMemoHeader.SETRANGE("No.", No);
        CreateElecSalesCrMemos.SETTABLEVIEW(SalesCrMemoHeader);
        CreateElecSalesCrMemos.USEREQUESTPAGE(false);
        CreateElecSalesCrMemos.RUN();
    end;

    local procedure RunReportCreateElecSalesInvoices(No: Code[20]);
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CreateElecSalesInvoice: Report "OIOUBL-Create Elec. Invoices";
    begin
        CLEAR(CreateElecSalesInvoice);
        SalesInvoiceHeader.SETRANGE("No.", No);
        SalesInvoiceHeader.FindFirst();
        CreateElecSalesInvoice.SETTABLEVIEW(SalesInvoiceHeader);
        CreateElecSalesInvoice.USEREQUESTPAGE(false);
        CreateElecSalesInvoice.RUN();
    end;

    local procedure SetDocumentSendingProfile(var DefaultDocumentSendingProfile: Record "Document Sending Profile"; DiskType: Option; DiskFormatCode: Code[20]);
    begin
        with DefaultDocumentSendingProfile do begin
            Init();
            Code := DefaultCodeTxt;
            Disk := DiskType;
            "Disk Format" := DiskFormatCode;
            Default := true;
            if not Insert() then
                Modify();
        end;
    end;

    local procedure UpdateOIOUBLCountryRegionCode();
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SETRANGE("OIOUBL-Country/Region Code", '');
        if CountryRegion.FINDFIRST() then
            CountryRegion.MODIFYALL("OIOUBL-Country/Region Code", CountryRegion.Code);
    end;

    local procedure UpdateSalesReceivablesSetup();
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Use TEMPORARYPATH to save the generated xml to avoid hardcoding for path.
        with SalesReceivablesSetup do begin
            Get();
            Validate("OIOUBL-Invoice Path", TemporaryPath());
            Validate("OIOUBL-Cr. Memo Path", TemporaryPath());
            Validate("OIOUBL-Default Profile Code", CreateOIOUBLProfile());
            Modify(true);
        end;
    end;

    local procedure UpdateCompanySwiftCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get();
            Validate("SWIFT Code", DelStr(LibraryUtility.GenerateGUID(), 1, 2));
            Modify(true);
        end;
    end;

    local procedure VerifyElectronicSalesDocument(DocumentNo: Code[20]; AccountCode: Text[30]);
    begin
        LibraryXMLReadOnServer.Initialize(OIOUBLNewFileMock.PopFilePath());
        LibraryXMLReadOnServer.VerifyNodeValue(IDTxt, DocumentNo);
        LibraryXMLReadOnServer.VerifyNodeValue(AccountingCostCodeTxt, AccountCode);
    end;

    local procedure VerifyElectronicSalesDocumentInZipArchive(DocumentNoLst: List of [Code[20]]; AccountCodeLst: List of [Text[30]]);
    var
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ZipFile: File;
        ZipFileInStream: InStream;
        ZipEntryOutStream: OutStream;
        XMLInStream: InStream;
        ZipEntryList: List of [Text];
        ZipEntry: Text;
        ZipEntryLength: Integer;
        i: Integer;
    begin
        for i := 1 to DocumentNoLst.Count() do // dequeue unused XML files names
            OIOUBLNewFileMock.PopFilePath();

        i := 0;
        ZipFile.WriteMode(false);
        ZipFile.Open(OIOUBLNewFileMock.PopFilePath());
        ZipFile.CreateInStream(ZipFileInStream);
        DataCompression.OpenZipArchive(ZipFileInStream, false);
        DataCompression.GetEntryList(ZipEntryList);
        foreach ZipEntry in ZipEntryList do begin
            i += 1;
            Clear(TempBlob);
            TempBlob.CreateOutStream(ZipEntryOutStream);
            DataCompression.ExtractEntry(ZipEntry, ZipEntryOutStream, ZipEntryLength);
            TempBlob.CreateInStream(XMLInStream);
            LibraryXMLReadOnServer.LoadXMLDocFromInStream(XMLInStream);
            LibraryXMLReadOnServer.VerifyNodeValue(IDTxt, DocumentNoLst.Get(i));
            LibraryXMLReadOnServer.VerifyNodeValue(AccountingCostCodeTxt, AccountCodeLst.Get(i));
        end;
        DataCompression.CloseZipArchive();
        ZipFile.Close();
    end;

    local procedure VerifyDocumentNoAndTaxAmount(DocumentNo: Code[20]; TaxAmount: Decimal);
    begin
        LibraryXMLReadOnServer.Initialize(OIOUBLNewFileMock.PopFilePath()); // Initialize generated Electronic Invoice and Credit Memo.
        LibraryXMLReadOnServer.VerifyNodeValue(IDTxt, DocumentNo);
        LibraryXMLReadOnServer.VerifyNodeValue(TaxAmountTxt, FORMAT(ROUND(TaxAmount, LibraryERM.GetAmountRoundingPrecision()), 0, '<Precision,2:3><Sign><Integer><Decimals><Comma,.>'));
        LibraryXMLReadOnServer.VerifyNodeValue(BaseQuantityTxt, '1');
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal);
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SETRANGE("Document No.", DocumentNo);
        GLEntry.FINDFIRST();
        Assert.AreNearlyEqual(
        Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
        STRSUBSTNO(AmountErr, GLEntry.FIELDCAPTION(Amount), GLEntry.Amount, GLEntry.TABLECAPTION()));
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Option; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    local procedure VerifyAllowanceCharge(DocumentNo: Code[20]; ExpectedValue: Decimal);
    var
        GeneralLedgerSetup: record "General Ledger Setup";
    begin
        LibraryXMLReadOnServer.Initialize(OIOUBLNewFileMock.PopFilePath());
        LibraryXMLReadOnServer.VerifyNodeValue(IDTxt, DocumentNo);
        Assert.AreEqual(1, LibraryXMLReadOnServer.GetNodesCount('cbc:AllowanceTotalAmount'), WrongAllowanceTotalAmountErr);
        Assert.AreEqual(2, LibraryXMLReadOnServer.GetNodesCount('cac:InvoiceLine'), WrongInvoiceLineCountErr);
        LibraryXMLReadOnServer.VerifyNodeValueInSubtree('cac:InvoiceLine', 'cbc:Amount', FORMAT(ExpectedValue, 0, '<Precision,2:3><Sign><Integer><Decimals><Comma,.>'));
        Assert.AreEqual(2, LibraryXMLReadOnServer.GetNodesCount('cac:AllowanceCharge'), WrongAllowanceChargeErr);

        GeneralLedgerSetup.Get();
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:PaymentTerms', 'cbc:Amount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:AllowanceCharge', 'cbc:Amount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:AllowanceCharge', 'cbc:BaseAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:TaxTotal', 'cbc:TaxAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:TaxSubtotal', 'cbc:TaxableAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:TaxSubtotal', 'cbc:TaxAmount', 'currencyID', GeneralLedgerSetup."LCY Code");

        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:LineExtensionAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxExclusiveAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxInclusiveAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:AllowanceTotalAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:PayableAmount', 'currencyID', GeneralLedgerSetup."LCY Code");

        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:InvoiceLine', 'cbc:LineExtensionAmount', 'currencyID', GeneralLedgerSetup."LCY Code");
        LibraryXMLReadOnServer.VerifyAttributeValueInSubtree('cac:Price', 'cbc:PriceAmount', 'currencyID', GeneralLedgerSetup."LCY Code")
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean);
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Meassage: Text[1024]);
    begin
    end;

    [StrMenuHandler]
    procedure ProfileSelectionMethodStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3; // Use the default profile for all selected documents without confimation.
    end;

    [ModalPageHandler]
    procedure PostandSendModalPageHandler(var PostandSendConfirmation: TestPage "Post and Send Confirmation");
    begin
        PostandSendConfirmation.Yes().INVOKE();
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;
}

