codeunit 144032 "ERM INTRASTAT"
{
    // // [FEATURE] [Intrastat]
    // 
    //  1. Verify Intrastat Journal Line - Shipment Method Code and VAT Registration Number for Shipment.
    //  2. Verify Customer VAT Registration Number in Intrastat Journal for a vendor - The same as customer No. and with positive quantity on the Purchase invoice.
    //  3. Verify Customer VAT Registration Number in Intrastat Journal for a vendor - The same as customer No. and with negative quantity on the Purchase invoice.
    //  4. Verify Customer VAT Registration Number as a blank in Intrastat Journal for a vendor.
    //  5. Verify Customer VAT Registration No. in Intrastat Journal for a customer.
    //  6. Verify Customer VAT Registration No. in Intrastat Journal for a customer - The same as vendor No. and with positive quantity on the Sales invoice.
    //  7. Verify Customer VAT Registration No. in Intrastat Journal for a customer - The same as vendor No. and with negative quantity on the Sales invoice.
    //  8. Verify Total Weight for shipment type is calculated and shown correctly on Report.
    //  9. Verify Total Weight for receipt type is calculated and shown correctly on Report.
    // 10. Verify generated XML file for type receipt and confirmation message when XML file is successfully exported.
    // 11. Verify Company Information - CISD mandatory fields behavior for DEB DTI +export Error.
    // 12. Verify Intrastat Journal Line - Transaction Specification mandatory fields behavior for DEB DTI +export Error.
    // 13. Verify Intrastat Journal Line - Quantity mandatory fields behavior for DEB DTI +export Error.
    // 14. Verify Intrastat Journal Line - Amount mandatory fields behavior for DEB DTI +export Error.
    // 15. Verify Intrastat Journal Line mandatory behavior for DEB DTI +export Error.
    // 16. Verify generated XML file for type shipment and confirmation message when XML file is successfully exported.
    // 17. Verify Intrastat Journal Batch - Reported as No mandatory fields behavior for DEB DTI +export Error.
    // 18. Verify XML File Name mandatory fields behavior for DEB DTI +export Error.
    // 
    //   Covers Test Cases for WI - 344097, 345143, 345145.
    //   -------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                               TFS ID
    //   -------------------------------------------------------------------------------------------------------
    //   ShipmentMethodOnIntrastatJournalLine                                                             152655
    //   CustVATRegNoForReceiptSameCustWithPositiveQty                                                    154702
    //   CustVATRegNoForReceiptSameCustWithNegativeQty                                                    154704
    //   CustVATRegNoForReceipt                                                                           154706
    //   CustVATRegNoForShipment                                                                          154712
    //   CustVATRegNoForShipmentSameVendWithPositiveQty                                                   154709
    //   CustVATRegNoForShipmentSameVendWithNegativeQty                                                   154710
    //   TotalWeightForShipmentReportForm                                                                 217425
    //   TotalWeightForReceiptReportForm                                                                  217423
    //   ReceiptExportDEBDTI                                                  298057,298061,298064,298065,298069
    //   CISDExportDEBDTIError, TransactionSpecificationExportDEBDTIError,
    //   BlankIntrastatJournalLineExportDEBDTIError                                                       298059
    //   QuantityExportDEBDTIError, AmountExportDEBDTIError                                        298059,298074
    //   ShipmentExportDEBDTI                                                               298064,298069,298072
    //   IntrastatJournalBatchReportedExportDEBDTIError ,BlankFileNameExportDEBDTIError            298067,298070

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        FileMgt: Codeunit "File Management";
        ObligationLevel: Option ,"1","2","3","4","5";
        IsInitialized: Boolean;
        CompanyInformationCISDErr: Label 'CISD must have a value in %1: Primary Key=. It cannot be zero or empty';
        EnvelopeIdTxt: Label 'envelopeId';
        FlowCodeLetterATxt: Label 'A';
        FlowCodeLetterDTxt: Label 'D';
        FlowCodeTxt: Label 'flowCode';
        FormatTxt: Label '########';
        IntrastatJournalBatchReportedErr: Label 'This batch is already marked as reported. If you want to export an XML file for another obligation level, clear the Reported field in the Intrastat journal batch';
        IntrastatJournalLineQuantityErr: Label '%1 must be positive in %2';
        IntrastatJournalLineStatisticalErr: Label '%1 must be positive in %2';
        NothingToExportErr: Label 'There is nothing to export';
        PartyIDTxt: Label 'PSIId';
        SuccessfullyExportedMsg: Label 'The journal lines were successfully exported';
        TotalWeightTxt: Label 'IntrastatJnlLineTotalWeight';
        TransactionSpecificationErr: Label '%1 must have a value in %2';
        AdvChecklistErr: Label 'There are one or more errors. For details, see the journal error FactBox.';

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentMethodOnIntrastatJournalLine()
    var
        Customer: Record Customer;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Intrastat Journal Line - Shipment Method Code and VAT Registration Number for Shipment.

        // Setup: Create and Post Sales Order.
        Initialize();
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.

        // Exercise.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");

        // Verify: Verify Shipment Method Code and VAT Registration Number on Intrastat Journal Line.
        Customer.Get(SalesShipmentLine."Sell-to Customer No.");
        VerifyValuesOnIntrastatJnlLine(
          IntrastatJnlLine, Customer."Shipment Method Code", SalesShipmentLine."No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForReceiptSameCustWithPositiveQty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Verify Customer VAT Registration Number in Intrastat Journal for a vendor - The same as customer No. and with positive quantity on the Purchase invoice.
        // Setup.
        Initialize();
        CustVATRegNoForReceiptSameCustomer(IntrastatJnlLine.Type::Receipt, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForReceiptSameCustWithNegativeQty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Verify Customer VAT Registration Number in Intrastat Journal for a vendor - The same as customer No. and with negative quantity on the Purchase invoice.
        // Setup.
        Initialize();
        CustVATRegNoForReceiptSameCustomer(IntrastatJnlLine.Type::Shipment, -LibraryRandom.RandDec(10, 2));  // Negative Random value for Quantity.
    end;

    local procedure CustVATRegNoForReceiptSameCustomer(Type: Option; Quantity: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        CustomerNo: Code[20];
    begin
        // Create and Post Purchase Invoice, Create and Rename Customer as Vendor Number.
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Invoice, Quantity);
        CustomerNo := CreateAndRenameCustomer(PurchRcptLine."Buy-from Vendor No.");

        // Exercise.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, Type, PurchRcptLine."Document No.");

        // Verify: Verify Vendor Number as a Customer Number. Verify Shipment Method Code, Item Number and VAT Registration Number with blank value on Intrastat Journal Line.
        Vendor.Get(PurchRcptLine."Buy-from Vendor No.");
        Vendor.TestField("No.", CustomerNo);
        VerifyValuesOnIntrastatJnlLine(IntrastatJnlLine, Vendor."Shipment Method Code", PurchRcptLine."No.", '');
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForReceipt()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
    begin
        // Verify Customer VAT Registration Number as a blank in Intrastat Journal for a vendor.

        // Setup: Create and Post Purchase Invoice.
        Initialize();
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.

        // Exercise.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");

        // Verify: Verify Shipment Method Code, Item Number and VAT Registration Number with blank value on Intrastat Journal Line.
        Vendor.Get(PurchRcptLine."Buy-from Vendor No.");
        VerifyValuesOnIntrastatJnlLine(IntrastatJnlLine, Vendor."Shipment Method Code", PurchRcptLine."No.", '');
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForShipment()
    var
        Customer: Record Customer;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Customer VAT Registration No. in Intrastat Journal for a customer.

        // Setup: Create and Post Sales Invoice.
        Initialize();
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.

        // Exercise.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");

        // Verify: Verify Shipment Method Code, Item Number and VAT Registration Number on Intrastat Journal Line.
        Customer.Get(SalesShipmentLine."Sell-to Customer No.");
        VerifyValuesOnIntrastatJnlLine(
          IntrastatJnlLine, Customer."Shipment Method Code", SalesShipmentLine."No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForShipmentSameVendWithPositiveQty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Verify Customer VAT Registration No. in Intrastat Journal for a customer - The same as vendor No. and with positive quantity on the Sales invoice.
        // Setup.
        Initialize();
        CustVATRegNoForShipmentSameVendor(IntrastatJnlLine.Type::Shipment, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustVATRegNoForShipmentSameVendWithNegativeQty()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Verify Customer VAT Registration No. in Intrastat Journal for a customer - The same as vendor No. and with negative quantity on the Sales invoice.
        // Setup.
        Initialize();
        CustVATRegNoForShipmentSameVendor(IntrastatJnlLine.Type::Receipt, -LibraryRandom.RandDec(10, 2));  // Negative Random value for Quantity.
    end;

    local procedure CustVATRegNoForShipmentSameVendor(Type: Option; Quantity: Decimal)
    var
        Customer: Record Customer;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        VendorNo: Code[20];
    begin
        // Create and Post Sales Invoice, Create and Rename Vendor as Customer Number.
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Invoice, Quantity);
        VendorNo := CreateAndRenameVendor(SalesShipmentLine."Sell-to Customer No.");

        // Exercise.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, Type, SalesShipmentLine."Document No.");

        // Verify: Verify Customer Number as a Vendor Number. Verify Shipment Method Code, Item Number and VAT Registration Number on Intrastat Journal Line.
        Customer.Get(SalesShipmentLine."Sell-to Customer No.");
        Customer.TestField("No.", VendorNo);
        VerifyValuesOnIntrastatJnlLine(
          IntrastatJnlLine, Customer."Shipment Method Code", SalesShipmentLine."No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatFormRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalWeightForShipmentReportIntrastatForm()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Total Weight for Shipment Type is calculated and shown correctly on Report.

        // Setup: Create and Post Sales Order, Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize();
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        LibraryVariableStorage.Enqueue(IntrastatJnlLine.Type::Shipment);  // Enqueue value for handler - IntrastatFormRequestPageHandler.

        // Exercise.
        RunIntrastatFormReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify Total Weight on generated XML file for Report - Intrastat - Form.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(TotalWeightTxt, Round(IntrastatJnlLine."Total Weight", 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,IntrastatFormRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalWeightForReceiptReportIntrastatForm()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify Total Weight for Receipt Type is calculated and shown correctly on Report.

        // Setup: Create and Post Purchase Order, Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize();
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        LibraryVariableStorage.Enqueue(IntrastatJnlLine.Type::Receipt);  // Enqueue value for handler - IntrastatFormRequestPageHandler.

        // Exercise.
        RunIntrastatFormReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify Total Weight on generated XML file for Report - Intrastat - Form.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(TotalWeightTxt, Round(IntrastatJnlLine."Total Weight", 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ReceiptExportDEBDTI()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO 425804] Verify generated XML file for Type Receipt and confirmation message when XML file is successfully exported.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Type "Receipt" and Transaction Specification 11 (Receipt).
        UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID());
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '11');

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Verify Company Information - CISD, Flow Code as A and Get Party ID on generated XML file.
        VerifyXMLFile(IntrastatJnlLine."Journal Batch Name", CompanyInformation.CISD, FlowCodeLetterATxt, CompanyInformation.GetPartyID());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure CISDExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO] Verify Company Information - CISD mandatory fields behavior for DEB DTI +export Error.
        Initialize();

        // [GIVEN] Intrastat Journal Line. Company Information has blank CISD.
        UpdateCISDOnCompanyInformation(CompanyInformation, '');
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");

        // [WHEN] Run Export DEB DTI report.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "CISD must have a value in Company Information" is thrown.
        Assert.ExpectedError(StrSubstNo(CompanyInformationCISDErr, CompanyInformation.TableCaption));

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure TransactionSpecificationExportDEBDTIError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO] Verify Intrastat Journal Line - Transaction Specification mandatory fields behavior for DEB DTI +export Error.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Type "Receipt" and blank Transaction Specification.
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '');

        // [WHEN] Run Export DEB DTI report with Obligation Level 2.
        LibraryVariableStorage.Enqueue(ObligationLevel::"2");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Verify error message.
        Assert.ExpectedError(
            StrSubstNo(TransactionSpecificationErr, IntrastatJnlLine.FieldCaption("Transaction Specification"), IntrastatJnlLine.TableCaption));

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure QuantityExportDEBDTIWithObligationLevel1()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO 425804] Check Quantity field of Intrastat Journal Line when Export DEB DTI report is run with Obligation Level 1.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Quantity = 0, Type "Receipt" and Transaction Specification 11 (Receipt).
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '11');
        UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine, LibraryRandom.RandDec(10, 2), 0);  // Quantity = 0.

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "Quantity must be positive" is thrown.
        Assert.ExpectedError(
            StrSubstNo(IntrastatJournalLineQuantityErr, IntrastatJnlLine.FieldCaption(Quantity), IntrastatJnlLine.TableCaption));
        Assert.ExpectedErrorCode('TestWrapped:CSide');

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure QuantityExportDEBDTIWithObligationLevel4()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO 425804] Check Quantity field of Intrastat Journal Line when Export DEB DTI report is run with Obligation Level 4.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Quantity = 0, Type "Shipment" and Transaction Specification 21 (Shipment).
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '21');
        UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine, LibraryRandom.RandDecInRange(10, 20, 2), 0);  // Quantity = 0.

        // [WHEN] Run Export DEB DTI report with Obligation Level 4.
        LibraryVariableStorage.Enqueue(ObligationLevel::"4");
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] No error is thrown. XML file is created.
        Assert.IsTrue(File.Exists(LibraryVariableStorage.DequeueText()), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure AmountExportDEBDTIError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO] Verify Intrastat Journal Line - Amount mandatory fields behavior for DEB DTI +export Error.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Type "Receipt", Transaction Specification "11" and Amount = 0.
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '11');
        UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine, 0, LibraryRandom.RandDec(10, 2));  // Amount = 0 and Random value for Quantity.

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "Statistical Value must be positive" is thrown.
        Assert.ExpectedError(
            StrSubstNo(IntrastatJournalLineStatisticalErr, IntrastatJnlLine.FieldCaption("Statistical Value"), IntrastatJnlLine.TableCaption));

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExportDEBDTIRequestPageHandler')]
    procedure BlankIntrastatJournalLineExportDEBDTIError()
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // [SCENARIO] Verify Intrastat Journal Line mandatory behavior for DEB DTI +export Error.
        Initialize();

        // [GIVEN] No Intrastat Journal lines are created.

        // [WHEN] Run Export DEB DTI report with Obligation Level 2.
        LibraryVariableStorage.Enqueue(ObligationLevel::"2");
        IntrastatJournal.OpenEdit();
        asserterror IntrastatJournal."Export DEB DTI+".Invoke;  // Opens handler - ExportDEBDTIRequestPageHandler.

        // [THEN] Error "There is nothing to export" is thrown.
        Assert.ExpectedError(NothingToExportErr);

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ShipmentExportDEBDTI()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO 425804] Verify generated XML file for type shipment and confirmation message when XML file is successfully exported.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Type "Shipment" and Transaction Specification 21 (Shipment).
        UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID());
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '21');

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Verify Intrastat Journal Batch - Reported as True after running the Report -DEB DTI +export. Verify Company Information - CISD, Flow Code as D and Get Party ID on XML file.
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, true);
        VerifyXMLFile(IntrastatJnlLine."Journal Batch Name", CompanyInformation.CISD, FlowCodeLetterDTxt, CompanyInformation.GetPartyID);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure IntrastatJournalBatchReportedExportDEBDTIError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO 425804] Run Export DEB DTI report when Intrastat Journal Batch has Reported = true.
        Initialize();

        // [GIVEN] Intrastat Journal Line with Type "Shipment" and Transaction Specification "21".
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '21');
        UpdateReportedTrueOnIntrastatJnlBatch(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "This batch is already marked as reported" is thrown.
        Assert.ExpectedError(IntrastatJournalBatchReportedErr);
        Assert.ExpectedErrorCode('Dialog');

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GroupEntriesOnInGetItemLedgerEntriesReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 207564] Check Get Item Ledger Entries report with "Group Entries" option summarized Quantity and Amount on Intrastat Journal when another Intrastat Batch has lines
        Initialize();

        // [GIVEN] Sales shipment is posted for Item "X" with Quantity = 1 Amount = 10 on 01 january
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        LibrarySales.CreateSalesLine(
          SalesLine1, SalesHeader, SalesLine1.Type::Item, CreateItemWithUnitPrice, LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales shipment is posted with 2 lines for Item "X" : Quantity = 2 Amount = 20, Quantity = 3 Amount = 30 on 01 february
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        SalesHeader.Validate("Posting Date", WorkDate + 1);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine1, SalesHeader, SalesLine1.Type::Item, SalesLine1."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesLine1."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Intrastat Journal Lines created on 01 january for Item "X" with "Group Entries" = No
        RunGetItemLedgerEntriesReport(IntrastatJnlLine, WorkDate, false);

        // [WHEN] Run Get Item Ledger Entries report on 01 february for Item "X" with "Group Entries" = Yes
        RunGetItemLedgerEntriesReport(IntrastatJnlLine, WorkDate + 1, true);

        // [THEN] Intrastat Journal Line in second batch for Item "X" has Quantity = 5, Amount = 50.
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlLine.SetRange("Item No.", SalesLine2."No.");
        IntrastatJnlLine.FindFirst();
        IntrastatJnlLine.TestField(Quantity, SalesLine1.Quantity + SalesLine2.Quantity);
        IntrastatJnlLine.TestField(Amount, Round(SalesLine1.Amount, 1) + Round(SalesLine2.Amount, 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GroupEntriesMultipleBatchesReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        IntrastatJnlLine1: Record "Intrastat Jnl. Line";
        IntrastatJnlLine2: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 444061] Check Get Item Ledger Entries report with "Group Entries" option summarized Quantity and Amount on Intrastat Journal when another Intrastat Batch has lines
        Initialize();

        // [GIVEN] Sales shipment is posted for Item "X" with Quantity = 10 and Quantity = 50 on 01 january
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        LibrarySales.CreateSalesLine(
          SalesLine1, SalesHeader, SalesLine1.Type::Item, CreateItemWithUnitPrice, 10);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesLine1."No.", 50);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales shipment is posted with 2 lines for Item "X" :  Quantity = 30 on 01 february
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        SalesHeader.Validate("Posting Date", WorkDate + 1);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine3, SalesHeader, SalesLine3.Type::Item, SalesLine1."No.", 30);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Get Item Ledger Entries report on 01 february for Item "X" with "Group Entries" = No
        RunGetItemLedgerEntriesReport(IntrastatJnlLine1, WorkDate + 1, false);

        // [GIVEN] Intrastat Journal Lines created on 01 january for Item "X" with "Group Entries" = Yes
        RunGetItemLedgerEntriesReport(IntrastatJnlLine2, WorkDate(), true);

        // [THEN] Intrastat Journal Line in the second batch for Item "X" has Quantity = 60.
        IntrastatJnlLine2.SetRange("Journal Batch Name", IntrastatJnlLine2."Journal Batch Name");
        IntrastatJnlLine2.FindFirst();
        IntrastatJnlLine2.TestField(Quantity, 60);
        IntrastatJnlLine2.TestField(Amount, Round(SalesLine1.Amount, 1) + Round(SalesLine2.Amount, 1));

        // [THEN] Intrastat Journal Line in the first batch for Item "X" has Quantity = 30.
        IntrastatJnlLine1.Reset();
        IntrastatJnlLine1.SetRange("Journal Batch Name", IntrastatJnlLine1."Journal Batch Name");
        IntrastatJnlLine1.SetRange("Item No.", SalesLine3."No.");
        IntrastatJnlLine1.FindFirst();
        IntrastatJnlLine1.TestField(Quantity, 30);
        IntrastatJnlLine1.TestField(Amount, Round(SalesLine3.Amount, 1));
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIObligationLevel1WhenTransactionSpecification_11_19()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 1) for Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        Initialize();

        // [GIVEN] Two Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        NumberOfLines := 2;
        TransactionSpecifications.AddRange('11', '19');
        IntrastatJnlBatchName := CreateMultipleReceiptIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] Two lines were exported to xml file. Each XML node "Item" contains the following nodes:
        // [THEN] itemNumber, CN8Code, MSConsDestCode, countryOfOriginCode, netMass, invoicedAmount, statisticalProcedureCode, natureOfTransactionACode, modeOfTransportCode, regionCode.
        VerifyExtendedItemNodesInXMLFile(LibraryVariableStorage.DequeueText(), TransactionSpecifications, 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIObligationLevel1WhenTransactionSpecification_21_29()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 1) for Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21 and 29.
        Initialize();

        // [GIVEN] Two Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21 and 29.
        NumberOfLines := 2;
        TransactionSpecifications.AddRange('21', '29');
        IntrastatJnlBatchName := CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] Two lines were exported to xml file. Each XML node "Item" contains the following nodes:
        // [THEN] itemNumber, CN8Code, MSConsDestCode, countryOfOriginCode, netMass, invoicedAmount, partnerId, statisticalProcedureCode, natureOfTransactionACode, modeOfTransportCode, regionCode.
        VerifyExtendedItemNodesInXMLFile(LibraryVariableStorage.DequeueText(), TransactionSpecifications, NumberOfLines);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure ExportDEBDTIObligationLevel1WhenTransactionSpecification_25_26_31()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 1) for Intrastat Journal Lines with Type "Shipment" and Transaction Specification 25, 26 and 31.
        Initialize();

        // [GIVEN] Three Intrastat Journal Lines with Type "Shipment" and Transaction Specification 25, 26 and 31.
        NumberOfLines := 3;
        TransactionSpecifications.AddRange('25', '26', '31');
        IntrastatJnlBatchName := CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] No lines were exported, xml file was not created. Error "There is nothing to export" is thrown.
        Assert.ExpectedError(NothingToExportErr);
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(File.Exists(LibraryVariableStorage.DequeueText()), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure ExportDEBDTIObligationLevel4WhenTransactionSpecification_11_19()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 4) for Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        Initialize();

        // [GIVEN] Two Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        NumberOfLines := 2;
        TransactionSpecifications.AddRange('11', '19');
        IntrastatJnlBatchName := CreateMultipleReceiptIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 4.
        LibraryVariableStorage.Enqueue(ObligationLevel::"4");
        asserterror RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] No lines were exported, xml file was not created. Error "There is nothing to export" is thrown.
        Assert.ExpectedError(NothingToExportErr);
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(File.Exists(LibraryVariableStorage.DequeueText()), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIObligationLevel4WhenTransactionSpecification_21_25_26_29_31()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 4) for Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21, 25, 26, 29, 31.
        Initialize();

        // [GIVEN] Five Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21, 25, 26, 29, 31.
        NumberOfLines := 5;
        TransactionSpecifications.AddRange('21', '25', '26', '29', '31');
        IntrastatJnlBatchName := CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 4.
        LibraryVariableStorage.Enqueue(ObligationLevel::"4");
        RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] Four lines were exported to xml file - line with Transaction Specification 29 was not exported.
        // [THEN] Each XML node "Item" contains the following nodes: itemNumber, invoicedAmount, partnerId, statisticalProcedureCode.
        TransactionSpecifications.Remove('29');
        VerifySimpleItemNodesInXMLFile(LibraryVariableStorage.DequeueText(), TransactionSpecifications, NumberOfLines - 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure ExportDEBDTIObligationLevel5WhenTransactionSpecification_11_19()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 5) for Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        Initialize();

        // [GIVEN] Two Intrastat Journal Lines with Type "Receipt" and Transaction Specification 11 and 19.
        NumberOfLines := 2;
        TransactionSpecifications.AddRange('11', '19');
        IntrastatJnlBatchName := CreateMultipleReceiptIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 5.
        LibraryVariableStorage.Enqueue(ObligationLevel::"5");
        asserterror RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] No lines were exported, xml file was not created. Error "There is nothing to export" is thrown.
        Assert.ExpectedError(NothingToExportErr);
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(File.Exists(LibraryVariableStorage.DequeueText()), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIObligationLevel5WhenTransactionSpecification_21_29()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 5) for Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21 and 29.
        Initialize();

        // [GIVEN] Two Intrastat Journal Lines with Type "Shipment" and Transaction Specification 21 and 29.
        NumberOfLines := 2;
        TransactionSpecifications.AddRange('21', '29');
        IntrastatJnlBatchName := CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 5.
        LibraryVariableStorage.Enqueue(ObligationLevel::"5");
        RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] Two lines were exported to xml file. Each XML node "Item" contains the following nodes:
        // [THEN] itemNumber, CN8Code, MSConsDestCode, countryOfOriginCode, netMass, invoicedAmount, partnerId, statisticalProcedureCode, natureOfTransactionACode, modeOfTransportCode, regionCode.
        VerifyExtendedItemNodesInXMLFile(LibraryVariableStorage.DequeueText(), TransactionSpecifications, NumberOfLines);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIObligationLevel5WhenTransactionSpecification_25_26_31()
    var
        TransactionSpecifications: List of [Code[10]];
        IntrastatJnlBatchName: Code[10];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 425804] Run Export DEB DTI report (Obligation Level 5) for Intrastat Journal Lines with Type "Shipment" and Transaction Specification 25, 26 and 31.
        Initialize();

        // [GIVEN] Three Intrastat Journal Lines with Type "Shipment" and Transaction Specification 25, 26 and 31.
        NumberOfLines := 3;
        TransactionSpecifications.AddRange('25', '26', '31');
        IntrastatJnlBatchName := CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications, NumberOfLines);

        // [WHEN] Run Export DEB DTI report with Obligation Level 5.
        LibraryVariableStorage.Enqueue(ObligationLevel::"5");
        RunExportDEBDTIReport(IntrastatJnlBatchName);

        // [THEN] Three lines were exported to xml file.
        // [THEN] Each XML node "Item" contains the following nodes: itemNumber, invoicedAmount, partnerId, statisticalProcedureCode.
        VerifySimpleItemNodesInXMLFile(LibraryVariableStorage.DequeueText(), TransactionSpecifications, NumberOfLines);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure ExportDEBDTIBlankAreaWhenAdvIntrastatChecklistHasRuleOnArea()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [FEATURE] [Advanced Intrastat Checklist]
        // [SCENARIO 425804] Run Export DEB DTI report for Intrastat Jnl Line with blank "Area" when Adv. Intrastat Checklist has rule on "Area" field of "Export DEB DTI" report.
        Initialize();

        // [GIVEN] Enabled Advanced Intrastat Checklist. Checklist has one line with Report "Export DEB DTI" and Field Name "Area".
        EnableAdvIntrastatChecklist();
        AdvancedIntrastatChecklist.DeleteAll();
        CreateAdvIntrastatChecklistRule(Report::"Export DEB DTI", IntrastatJnlLine.FieldNo("Area"), '');

        // [GIVEN] Intrastat Journal Line with blank Area field.
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        IntrastatJnlLine.Validate("Area", '');
        IntrastatJnlLine.Modify(true);

        // [WHEN] Run Export DEB DTI report.
        LibraryVariableStorage.Enqueue(ObligationLevel::"2");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "There are one or more errors. For details, see the journal error FactBox." was thrown.
        // [THEN] Error "Area in Intrastat Journal Line must not be blank" was shown in the Error Messages factbox of Intrastat Journal.
        Assert.ExpectedError(AdvChecklistErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifyIntrastatJnlLineSingleError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Area"));

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    procedure ExportDEBDTIShipmentBlankPartnerVATIDWhenAdvIntrastatChecklistHasRuleOnPartnerVATIDFilterShipment()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [FEATURE] [Advanced Intrastat Checklist]
        // [SCENARIO 425804] Run Export DEB DTI report for Intrastat Jnl Line with Type "Shipment" and blank "Partner VAT ID" when Adv. Intrastat Checklist has rule on "Partner VAT ID" of "Export DEB DTI" report with filter on Shipment.
        Initialize();

        // [GIVEN] Enabled Advanced Intrastat Checklist. Checklist has one line with Report "Export DEB DTI" and Field Name "Partner VAT ID" with Filter "Type: Shipment".
        EnableAdvIntrastatChecklist();
        AdvancedIntrastatChecklist.DeleteAll();
        CreateAdvIntrastatChecklistRule(Report::"Export DEB DTI", IntrastatJnlLine.FieldNo("Partner VAT ID"), 'Type:Shipment');

        // [GIVEN] Intrastat Journal Line with Type "Shipment" and blank Partner VAT ID field.
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '21');
        IntrastatJnlLine.Validate("Partner VAT ID", '');
        IntrastatJnlLine.Modify(true);

        // [WHEN] Run Export DEB DTI report.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] Error "There are one or more errors. For details, see the journal error FactBox." was thrown.
        // [THEN] Error "Partner VAT ID in Intrastat Journal Line must not be blank" was shown in the Error Messages factbox of Intrastat Journal.
        Assert.ExpectedError(AdvChecklistErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifyIntrastatJnlLineSingleError(IntrastatJnlLine, IntrastatJnlLine.FieldName("Partner VAT ID"));

        LibraryVariableStorage.DequeueText();   // xml file name
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    procedure ExportDEBDTIReceiptBlankPartnerVATIDWhenAdvIntrastatChecklistHasRuleOnPartnerVATIDFilterShipment()
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Advanced Intrastat Checklist]
        // [SCENARIO 425804] Run Export DEB DTI report for Intrastat Jnl Line with Type "Receipt" and blank "Partner VAT ID" when Adv. Intrastat Checklist has rule on "Partner VAT ID" of "Export DEB DTI" report with filter on Shipment.
        Initialize();

        // [GIVEN] Enabled Advanced Intrastat Checklist. Checklist has one line with Report "Export DEB DTI" and Field Name "Partner VAT ID" with Filter "Type: Shipment".
        EnableAdvIntrastatChecklist();
        AdvancedIntrastatChecklist.DeleteAll();
        CreateAdvIntrastatChecklistRule(Report::"Export DEB DTI", IntrastatJnlLine.FieldNo("Partner VAT ID"), 'Type:Shipment');

        // [GIVEN] Intrastat Journal Line with Type "Receipt", Transaction Specification 11 (Receipt) and blank Partner VAT ID field.
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDecInRange(10, 20, 2));
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationOnIntrastatJnlLine(IntrastatJnlLine, '11');
        IntrastatJnlLine.Validate("Partner VAT ID", '');
        IntrastatJnlLine.Modify(true);

        // [WHEN] Run Export DEB DTI report with Obligation Level 1.
        LibraryVariableStorage.Enqueue(ObligationLevel::"1");
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // [THEN] No errors were thrown. XML file was created.
        Assert.IsTrue(File.Exists(LibraryVariableStorage.DequeueText()), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM INTRASTAT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        IntrastatJnlTemplate.DeleteAll();
        IntrastatJnlLine.DeleteAll();
        ItemLedgerEntry.SetRange("Posting Date", WorkDate());
        ItemLedgerEntry.DeleteAll();

        if IsInitialized then
            exit;

        UpdateCISDOnCompanyInformation();
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.Save(Database::"Intrastat Setup");

        IsInitialized := true;
    end;

    local procedure UpdateTransactionSpecificationOnIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TransactionSpecification: Code[10])
    begin
        IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification);
        IntrastatJnlLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesShipmentLine: Record "Sales Shipment Line"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, Quantity);
        FindSalesShipmentLine(SalesShipmentLine, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, Quantity);
        FindPurchaseReceipt(PurchRcptLine, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true))
    end;

    local procedure CreateAndRenameVendor(CustomerNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor);
        Vendor.Rename(CustomerNo);
        exit(Vendor."No.");
    end;

    local procedure CreateAndRenameCustomer(VendorNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer);
        Customer.Rename(VendorNo);
        exit(Customer."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipment Method Code", FindShipmentMethod);
        Customer.Validate("Country/Region Code", CreateVATRegistrationNoFormat);
        Customer.Validate("VAT Registration No.", LibraryUtility.GenerateGUID());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJournalBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate("Statistics Period", Format(WorkDate, 0, LibraryFiscalYear.GetStatisticsPeriod));
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalBatch(IntrastatJnlBatch);
        IntrastatJnlLine.Init();
        IntrastatJnlLine.Validate("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.Validate("Journal Batch Name", IntrastatJnlBatch.Name);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tariff No.", TariffNumber."No.");
        Item.Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithUnitPrice(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVATRegistrationNoFormat(): Code[10]
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion);
        VATRegistrationNoFormat.Validate(Format, CopyStr(LibraryUtility.GenerateGUID, 1, 2) + FormatTxt);
        VATRegistrationNoFormat.Modify(true);
        exit(VATRegistrationNoFormat."Country/Region Code");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", FindShipmentMethod);
        Vendor.Validate("Country/Region Code", CreateVATRegistrationNoFormat);
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateMultipleShipmentIntrastatJnlLines(TransactionSpecifications: List of [Code[10]]; NumberOfLines: Integer) IntrastatJnlBatchName: Code[10]
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNumbers: List of [Code[20]];
        i: Integer;
    begin
        for i := 1 to NumberOfLines do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandDecInRange(10, 20, 2));
            ItemNumbers.Add(SalesLine."No.");
            SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
            SalesLine.Modify(true);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;

        RunGetItemLedgerEntriesReport(IntrastatJnlLine, WorkDate(), false);
        IntrastatJnlBatchName := IntrastatJnlLine."Journal Batch Name";

        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        for i := 1 to NumberOfLines do begin
            IntrastatJnlLine.SetRange("Item No.", ItemNumbers.Get(i));
            IntrastatJnlLine.FindFirst();
            UpdateExportFieldsOnIntrastatJnlLine(IntrastatJnlLine, TransactionSpecifications.Get(i));
        end;
    end;

    local procedure CreateMultipleReceiptIntrastatJnlLines(TransactionSpecifications: List of [Code[10]]; NumberOfLines: Integer) IntrastatJnlBatchName: Code[10]
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNumbers: List of [Code[20]];
        i: Integer;
    begin
        for i := 1 to NumberOfLines do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, LibraryRandom.RandDecInRange(10, 20, 2));
            ItemNumbers.Add(PurchaseLine."No.");
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
            PurchaseLine.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;

        RunGetItemLedgerEntriesReport(IntrastatJnlLine, WorkDate(), false);
        IntrastatJnlBatchName := IntrastatJnlLine."Journal Batch Name";

        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlLine."Journal Batch Name");
        for i := 1 to NumberOfLines do begin
            IntrastatJnlLine.SetRange("Item No.", ItemNumbers.Get(i));
            IntrastatJnlLine.FindFirst();
            UpdateExportFieldsOnIntrastatJnlLine(IntrastatJnlLine, TransactionSpecifications.Get(i));
        end;
    end;

    local procedure CreateEntryExitPoint(): Code[10]
    var
        EntryExitPoint: Record "Entry/Exit Point";
    begin
        EntryExitPoint.Init();
        EntryExitPoint.Validate(Code, LibraryUtility.GenerateGUID());
        EntryExitPoint.Validate(Description, LibraryUtility.GenerateGUID());
        EntryExitPoint.Insert(true);
        exit(EntryExitPoint.Code);
    end;

    local procedure CreateArea(): Code[10]
    var
        AreaRec: Record "Area";
    begin
        AreaRec.Init();
        AreaRec.Validate(Code, LibraryUtility.GenerateGUID());
        AreaRec.Validate(Text, LibraryUtility.GenerateGUID());
        AreaRec.Insert(true);
        exit(AreaRec.Code);
    end;

    local procedure CreateTransactionType(): Code[10]
    var
        TransactionType: Record "Transaction Type";
    begin
        TransactionType.Init();
        TransactionType.Validate(Code, LibraryUtility.GenerateGUID());
        TransactionType.Validate(Description, LibraryUtility.GenerateGUID());
        TransactionType.Insert(true);
        exit(TransactionType.Code);
    end;

    local procedure CreateTransportMethod(): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.Init();
        TransportMethod.Validate(Code, LibraryUtility.GenerateGUID());
        TransportMethod.Validate(Description, LibraryUtility.GenerateGUID());
        TransportMethod.Insert(true);
        exit(TransportMethod.Code);
    end;

    local procedure CreateAdvIntrastatChecklistRule(ReportId: Integer; FieldNo: Integer; FilterExpression: Text)
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        AdvancedIntrastatChecklist.Init();
        AdvancedIntrastatChecklist.Validate("Object Type", AdvancedIntrastatChecklist."Object Type"::Report);
        AdvancedIntrastatChecklist.Validate("Object Id", ReportId);
        AdvancedIntrastatChecklist.Validate("Field No.", FieldNo);
        AdvancedIntrastatChecklist.Validate(
            "Filter Expression",
            CopyStr(FilterExpression, 1, MaxStrLen(AdvancedIntrastatChecklist."Filter Expression")));
        AdvancedIntrastatChecklist.Validate("Reversed Filter Expression", false);
        AdvancedIntrastatChecklist.Insert(true);
    end;

    local procedure DeleteIntrastatJnlLine(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetFilter("Document No.", '<>%1', DocumentNo);
        if IntrastatJnlLine.FindFirst() then
            IntrastatJnlLine.DeleteAll();
    end;


    local procedure EnableAdvIntrastatChecklist()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        if not IntrastatSetup.Get() then
            IntrastatSetup.Insert();
#if not CLEAN19
        IntrastatSetup."Use Advanced Checklist" := true;
        IntrastatSetup.Modify;
#endif
    end;

    local procedure FindIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; DocumentNo: Code[20])
    begin
        IntrastatJnlLine.SetRange(Type, Type);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindFirst();
    end;

    local procedure FindPurchaseReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.FindFirst();
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        PurchRcptLine.SetRange("Document No.", ItemLedgerEntry."Document No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; InvoiceNo: Code[20])
    var
        ShipmentInvoiced: Record "Shipment Invoiced";
    begin
        ShipmentInvoiced.SetRange("Invoice No.", InvoiceNo);
        ShipmentInvoiced.FindFirst();
        SalesShipmentLine.SetRange("Document No.", ShipmentInvoiced."Shipment No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst();
        exit(ShipmentMethod.Code);
    end;

    local procedure RunExportDEBDTIReport(JournalBatchName: Code[10])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        Commit();  // Commit required for running report.
        IntrastatJournal.OpenEdit();
        IntrastatJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        IntrastatJournal."Export DEB DTI+".Invoke();  // Opens handler - ExportDEBDTIRequestPageHandler.
        IntrastatJournal.Close();
    end;

    local procedure RunIntrastatFormReport(JnlBatchName: Code[10])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        Commit();  // Commit required for running report.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CurrentJnlBatchName.SetValue(JnlBatchName);
        IntrastatJournal.Form.Invoke;  // Opens handler - IntrastatFormRequestPageHandler.
        IntrastatJournal.Close();
    end;

    local procedure RunGetItemLedgerEntriesReportAndUpdate(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; DocumentNo: Code[20])
    begin
        RunGetItemLedgerEntriesReport(IntrastatJnlLine, WorkDate, false);

        // Delete unnecessary Intrastat Journal Lines, find necessary Intrastat Journal Line and updated with mandatory fields.
        DeleteIntrastatJnlLine(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name", DocumentNo);
        FindIntrastatJnlLine(IntrastatJnlLine, Type, DocumentNo);
        UpdateTransactionOnIntrastatJnlLine(IntrastatJnlLine);
    end;

    local procedure RunGetItemLedgerEntriesReport(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ReportingDate: Date; GroupEntries: Boolean)
    var
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        CreateIntrastatJnlLine(IntrastatJnlLine); // Create blank line for running report.
        Commit();  // Commit required for running report.
        LibraryVariableStorage.Enqueue(ReportingDate);
        LibraryVariableStorage.Enqueue(GroupEntries);
        Clear(GetItemLedgerEntries);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        GetItemLedgerEntries.Run();  // Opens handler - GetItemLedgerEntriesRequestPageHandler.
    end;

    local procedure UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine: Record "Intrastat Jnl. Line"; Amount: Decimal; Quantity: Decimal)
    begin
        IntrastatJnlLine.Validate(Amount, Amount);
        IntrastatJnlLine.Validate(Quantity, Quantity);
        IntrastatJnlLine.Modify(true);
    end;

    local procedure UpdateCISDOnCompanyInformation(var CompanyInformation: Record "Company Information"; NewCISD: Code[10]) OLDCISD: Code[10]
    begin
        CompanyInformation.Get();
        OLDCISD := CompanyInformation.CISD;
        CompanyInformation.Validate(CISD, NewCISD);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCISDOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(CISD, LibraryUtility.GenerateGUID());
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateReportedTrueOnIntrastatJnlBatch(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get(JournalTemplateName, JournalBatchName);
        IntrastatJnlBatch.Validate(Reported, true);
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure UpdateTransactionOnIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        TransactionSpecification: Record "Transaction Specification";
        TransactionType: Record "Transaction Type";
    begin
        TransactionSpecification.FindFirst();
        TransactionType.FindFirst();
        IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification.Code);
        IntrastatJnlLine.Validate("Transaction Type", TransactionType.Code);
        IntrastatJnlLine.Validate(Amount, LibraryRandom.RandDec(10, 2));
        IntrastatJnlLine.Modify(true);
    end;

    local procedure UpdateExportFieldsOnIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; TransactionSpecification: Code[10])
    begin
        IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification);
        IntrastatJnlLine.Validate("Entry/Exit Point", CreateEntryExitPoint());
        IntrastatJnlLine.Validate("Country/Region of Origin Code", CreateCountryRegion());
        IntrastatJnlLine.Validate("Transaction Type", CreateTransactionType());
        IntrastatJnlLine.Validate("Transport Method", CreateTransportMethod());
        IntrastatJnlLine.Validate("Area", CreateArea());
        IntrastatJnlLine.Modify(true);
    end;

    local procedure VerifyValuesOnIntrastatJnlLine(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ShipmentMethodCode: Code[10]; ItemNo: Code[20]; CustVATRegistrationNo: Text[20])
    begin
        IntrastatJnlLine.TestField("Item No.", ItemNo);
        IntrastatJnlLine.TestField("Shpt. Method Code", ShipmentMethodCode);
        IntrastatJnlLine.TestField("Partner VAT ID", CustVATRegistrationNo);
    end;

    local procedure VerifyXMLFile(XMLFileName: Text[10]; EnvelopeId: Code[10]; FlowCode: Text; PartyID: Code[18])
    begin
        LibraryXMLRead.Initialize(LibraryVariableStorage.DequeueText());
        LibraryXMLRead.VerifyNodeValue(EnvelopeIdTxt, EnvelopeId);
        LibraryXMLRead.VerifyNodeValue(FlowCodeTxt, FlowCode);
        LibraryXMLRead.VerifyNodeValue(PartyIDTxt, PartyID);
    end;

    local procedure VerifyExtendedItemNodesInXMLFile(FileName: Text; TransactionSpecifications: List of [Code[10]]; PartnerIdNodeCount: Integer)
    var
        Node: DotNet XmlNode;
        ItemNodes: List of [Text];
        NumberOfNodes: Integer;
        i: Integer;
    begin
        NumberOfNodes := TransactionSpecifications.Count;
        LibraryXPathXMLReader.Initialize(FileName, '');
        for i := 1 to TransactionSpecifications.Count do
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Declaration/Item/statisticalProcedureCode', TransactionSpecifications.Get(i), i - 1);

        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/itemNumber', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/CN8/CN8Code', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/MSConsDestCode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/countryOfOriginCode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/netMass', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/invoicedAmount', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/partnerId', PartnerIdNodeCount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/statisticalProcedureCode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/NatureOfTransaction/natureOfTransactionACode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/modeOfTransportCode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/regionCode', NumberOfNodes);

        // check nodes order
        ItemNodes.AddRange('itemNumber', 'CN8', 'MSConsDestCode', 'countryOfOriginCode', 'netMass', 'invoicedAmount');
        if PartnerIdNodeCount > 0 then
            ItemNodes.Add('partnerId');
        ItemNodes.AddRange('statisticalProcedureCode', 'NatureOfTransaction', 'modeOfTransportCode', 'regionCode');

        LibraryXPathXMLReader.GetNodeByXPath('//Declaration/Item', Node);
        Assert.AreEqual(ItemNodes.Count, Node.ChildNodes.Count, '');
        for i := 1 to Node.ChildNodes.Count do
            Assert.AreEqual(ItemNodes.Get(i), Node.ChildNodes.Item(i - 1).Name, '');
    end;

    local procedure VerifySimpleItemNodesInXMLFile(FileName: Text; TransactionSpecifications: List of [Code[10]]; PartnerIdNodeCount: Integer)
    var
        Node: DotNet XmlNode;
        ItemNodes: List of [Text];
        NumberOfNodes: Integer;
        i: Integer;
    begin
        NumberOfNodes := TransactionSpecifications.Count;
        LibraryXPathXMLReader.Initialize(FileName, '');
        for i := 1 to TransactionSpecifications.Count do
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Declaration/Item/statisticalProcedureCode', TransactionSpecifications.Get(i), i - 1);

        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/itemNumber', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/CN8/CN8Code');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/CN8/CN8Code');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/MSConsDestCode');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/countryOfOriginCode');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/netMass');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/invoicedAmount', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/partnerId', PartnerIdNodeCount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item/statisticalProcedureCode', NumberOfNodes);
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/NatureOfTransaction/natureOfTransactionACode');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/modeOfTransportCode');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Declaration/Item/regionCode');

        // check nodes order
        ItemNodes.AddRange('itemNumber', 'invoicedAmount');
        if PartnerIdNodeCount > 0 then
            ItemNodes.Add('partnerId');
        ItemNodes.Add('statisticalProcedureCode');

        LibraryXPathXMLReader.GetNodeByXPath('//Declaration/Item', Node);
        Assert.AreEqual(ItemNodes.Count, Node.ChildNodes.Count, '');
        for i := 1 to Node.ChildNodes.Count do
            Assert.AreEqual(ItemNodes.Get(i), Node.ChildNodes.Item(i - 1).Name, '');
    end;

    local procedure VerifyIntrastatJnlLineSingleError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldName: Text)
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Record ID", IntrastatJnlLine.RecordId());
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(FieldName, ErrorMessage.Description);
    end;

    [RequestPageHandler]
    procedure ExportDEBDTIRequestPageHandler(var ExportDEBDTI: TestRequestPage "Export DEB DTI")
    var
        XMLFileName: Text;
        ObligationLevel: Integer;
    begin
        ObligationLevel := LibraryVariableStorage.DequeueInteger();
        XMLFileName := FileMgt.ServerTempFileName('xml');
        LibraryVariableStorage.Enqueue(XMLFileName);
        ExportDEBDTI.FileName.SetValue(XMLFileName);
        ExportDEBDTI."Obligation Level".SetValue(ObligationLevel);
        ExportDEBDTI.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesRequestPageHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    var
        ReportingDate: Date;
    begin
        ReportingDate := LibraryVariableStorage.DequeueDate;
        GetItemLedgerEntries.StartingDate.SetValue(ReportingDate);
        GetItemLedgerEntries.EndingDate.SetValue(ReportingDate);
        GetItemLedgerEntries.GroupEntries.SetValue(LibraryVariableStorage.DequeueBoolean);
        GetItemLedgerEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormRequestPageHandler(var IntrastatForm: TestRequestPage "Intrastat - Form")
    var
        Type: Variant;
    begin
        LibraryVariableStorage.Dequeue(Type);
        IntrastatForm."Intrastat Jnl. Line".SetFilter(Type, Format(Type));
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, SuccessfullyExportedMsg) > 0, Message);
    end;
}

