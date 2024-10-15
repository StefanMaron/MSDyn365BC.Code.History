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
        CompanyInformationCISDErr: Label 'CISD must have a value in %1: Primary Key=. It cannot be zero or empty';
        DestinationFileErr: Label 'A destination file must be specified.';
        EnvelopeIdTxt: Label 'envelopeId';
        FlowCodeLetterATxt: Label 'A';
        FlowCodeLetterDTxt: Label 'D';
        FlowCodeTxt: Label 'flowCode';
        FormatTxt: Label '########';
        IntrastatJournalBatchReportedErr: Label 'Reported must be equal to ''No''  in Intrastat Jnl. Batch';
        IntrastatJournalLineQuantityErr: Label '%1 must be positive in %2';
        IntrastatJournalLineStatisticalErr: Label '%1 must be positive in %2';
        NothingToExportErr: Label 'There is nothing to export';
        PartyIDTxt: Label 'PSIId';
        SuccessfullyExportedMsg: Label 'The journal lines were successfully exported';
        TotalWeightTxt: Label 'IntrastatJnlLineTotalWeight';
        TransactionSpecificationErr: Label '%1 must have a value in %2';
        XMLPathTxt: Label '%1%2.XML';
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";

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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
        Initialize;
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
    [Scope('OnPrem')]
    procedure ReceiptExportDEBDTI()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OldCISD: Code[10];
    begin
        // Verify generated XML file for Type Receipt and confirmation message when XML file is successfully exported.

        // Setup: Create and Post Purchase Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");

        // Exercise.
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify Company Information - CISD, Flow Code as A and Get Party ID on generated XML file.
        VerifyXMLFile(IntrastatJnlLine."Journal Batch Name", CompanyInformation.CISD, FlowCodeLetterATxt, CompanyInformation.GetPartyID);

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CISDExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OldCISD: Code[10];
    begin
        // Verify Company Information - CISD mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Purchase Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, '');
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");

        // Exercise.
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(CompanyInformationCISDErr, CompanyInformation.TableCaption));

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransactionSpecificationExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OldCISD: Code[10];
    begin
        // Verify Intrastat Journal Line - Transaction Specification mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Purchase Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateTransactionSpecificationBlankIntrastatJnlLine(IntrastatJnlLine);

        // Exercise.
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(TransactionSpecificationErr, IntrastatJnlLine.FieldCaption("Transaction Specification"), IntrastatJnlLine.TableCaption));

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OldCISD: Code[10];
    begin
        // Verify Intrastat Journal Line - Quantity mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Purchase Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine, LibraryRandom.RandDec(10, 2), 0);  // Random value for Amount and Quantity - 0.

        // Exercise.
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(IntrastatJournalLineQuantityErr, IntrastatJnlLine.FieldCaption(Quantity), IntrastatJnlLine.TableCaption));

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmountExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OldCISD: Code[10];
    begin
        // Verify Intrastat Journal Line - Amount mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Purchase Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);  // GUILD value for Company Information - CISD.
        CreateAndPostPurchaseDocument(PurchRcptLine, PurchaseHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, PurchRcptLine."Document No.");
        UpdateAmountAndQuantityOnIntrastatJnlLine(IntrastatJnlLine, 0, LibraryRandom.RandDec(10, 2));  // Amount - 0 and Random value for Quantity.

        // Exercise.
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify error message.
        Assert.ExpectedError(
          StrSubstNo(IntrastatJournalLineStatisticalErr, IntrastatJnlLine.FieldCaption("Statistical Value"), IntrastatJnlLine.TableCaption));

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlankIntrastatJournalLineExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJournal: TestPage "Intrastat Journal";
        OldCISD: Code[10];
    begin
        // Verify Intrastat Journal Line mandatory behavior for DEB DTI +export Error.

        // Setup: Update Company Information for CISD.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID);  // Enqueue value for handler - ExportDEBDTIRequestPageHandler.

        // Exercise.
        IntrastatJournal.OpenEdit;
        asserterror IntrastatJournal."Export DEB DTI+".Invoke;  // Opens handler - ExportDEBDTIRequestPageHandler.

        // Verify: Verify error message.
        Assert.ExpectedError(NothingToExportErr);

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentExportDEBDTI()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        OldCISD: Code[10];
    begin
        // Verify generated XML file for type shipment and confirmation message when XML file is successfully exported.

        // Setup: Create and Post Sales Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");

        // Exercise.
        RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify Intrastat Journal Batch - Reported as True after running the Report -DEB DTI +export. Verify Company Information - CISD, Flow Code as D and Get Party ID on XML file.
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        IntrastatJnlBatch.TestField(Reported, true);
        VerifyXMLFile(IntrastatJnlLine."Journal Batch Name", CompanyInformation.CISD, FlowCodeLetterDTxt, CompanyInformation.GetPartyID);

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,ExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatJournalBatchReportedExportDEBDTIError()
    var
        CompanyInformation: Record "Company Information";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        OldCISD: Code[10];
    begin
        // Verify Intrastat Journal Batch - Reported as No mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Sales Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        OldCISD := UpdateCISDOnCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID);
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        UpdateReportedTrueOnIntrastatJnlBatch(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");

        // Exercise.
        asserterror RunExportDEBDTIReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify error message.
        Assert.ExpectedError(IntrastatJournalBatchReportedErr);

        // TearDown.
        UpdateCISDOnCompanyInformation(CompanyInformation, OldCISD)
    end;

    [Test]
    [HandlerFunctions('GetItemLedgerEntriesRequestPageHandler,BlankFileExportDEBDTIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlankFileNameExportDEBDTIError()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        // Verify XML File Name mandatory fields behavior for DEB DTI +export Error.

        // Setup: Create and Post Sales Order and Run Report - Get Item Ledger Entries on Intrastat Journal Line.
        Initialize;
        CreateAndPostSalesDocument(SalesShipmentLine, SalesHeader."Document Type"::Order, LibraryRandom.RandDec(10, 2));  // Random value for Quantity.
        RunGetItemLedgerEntriesReportAndUpdate(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, SalesShipmentLine."Document No.");
        IntrastatJournal.OpenEdit;
        Commit();  // Commit required for running report.

        // Exercise.
        asserterror IntrastatJournal."Export DEB DTI+".Invoke;  // Opens handler - BlankFileExportDEBDTIRequestPageHandler.

        // Verify: Verify error message.
        Assert.ExpectedError(DestinationFileErr);
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
        Initialize;

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
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField(Quantity, SalesLine1.Quantity + SalesLine2.Quantity);
        IntrastatJnlLine.TestField(Amount, Round(SalesLine1.Amount, 1) + Round(SalesLine2.Amount, 1));
    end;

    local procedure Initialize()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM INTRASTAT");
        LibraryVariableStorage.Clear;
        IntrastatJnlTemplate.DeleteAll();
        IntrastatJnlLine.DeleteAll();
    end;

    local procedure UpdateTransactionSpecificationBlankIntrastatJnlLine(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine.Validate("Transaction Specification", '');
        IntrastatJnlLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesShipmentLine: Record "Sales Shipment Line"; DocumentType: Option; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, Quantity);
        FindSalesShipmentLine(SalesShipmentLine, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentType: Option; Quantity: Decimal)
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
        Customer.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
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
        TariffNumber.FindFirst;
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
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure DeleteIntrastatJnlLine(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatJnlLine.SetFilter("Document No.", '<>%1', DocumentNo);
        if IntrastatJnlLine.FindFirst then
            IntrastatJnlLine.DeleteAll();
    end;

    local procedure FindIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; DocumentNo: Code[20])
    begin
        IntrastatJnlLine.SetRange(Type, Type);
        IntrastatJnlLine.SetRange("Document No.", DocumentNo);
        IntrastatJnlLine.FindFirst;
    end;

    local procedure FindPurchaseReceipt(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.FindFirst;
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        PurchRcptLine.SetRange("Document No.", ItemLedgerEntry."Document No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst;
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; InvoiceNo: Code[20])
    var
        ShipmentInvoiced: Record "Shipment Invoiced";
    begin
        ShipmentInvoiced.SetRange("Invoice No.", InvoiceNo);
        ShipmentInvoiced.FindFirst;
        SalesShipmentLine.SetRange("Document No.", ShipmentInvoiced."Shipment No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst;
    end;

    local procedure FindShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst;
        exit(ShipmentMethod.Code);
    end;

    local procedure RunExportDEBDTIReport(JournalBatchName: Code[10])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        LibraryVariableStorage.Enqueue(JournalBatchName);  // Enqueue value for ExportDEBDTIRequestPageHandler.
        Commit();  // Commit required for running report.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        IntrastatJournal."Export DEB DTI+".Invoke;  // Opens handler - ExportDEBDTIRequestPageHandler.
        IntrastatJournal.Close;
    end;

    local procedure RunIntrastatFormReport(JnlBatchName: Code[10])
    var
        IntrastatJournal: TestPage "Intrastat Journal";
    begin
        Commit();  // Commit required for running report.
        IntrastatJournal.OpenEdit;
        IntrastatJournal.CurrentJnlBatchName.SetValue(JnlBatchName);
        IntrastatJournal.Form.Invoke;  // Opens handler - IntrastatFormRequestPageHandler.
        IntrastatJournal.Close;
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
        GetItemLedgerEntries.Run;  // Opens handler - GetItemLedgerEntriesRequestPageHandler.
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
        TransactionSpecification.FindFirst;
        TransactionType.FindFirst;
        IntrastatJnlLine.Validate("Transaction Specification", TransactionSpecification.Code);
        IntrastatJnlLine.Validate("Transaction Type", TransactionType.Code);
        IntrastatJnlLine.Validate(Amount, LibraryRandom.RandDec(10, 2));
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
        LibraryXMLRead.Initialize(StrSubstNo(XMLPathTxt, TemporaryPath, XMLFileName));
        LibraryXMLRead.VerifyNodeValue(EnvelopeIdTxt, EnvelopeId);
        LibraryXMLRead.VerifyNodeValue(FlowCodeTxt, FlowCode);
        LibraryXMLRead.VerifyNodeValue(PartyIDTxt, PartyID);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlankFileExportDEBDTIRequestPageHandler(var ExportDEBDTI: TestRequestPage "Export DEB DTI")
    begin
        ExportDEBDTI.FileName.SetValue('');
        ExportDEBDTI.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportDEBDTIRequestPageHandler(var ExportDEBDTI: TestRequestPage "Export DEB DTI")
    var
        XMLFileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(XMLFileName);
        ExportDEBDTI.FileName.SetValue(StrSubstNo(XMLPathTxt, TemporaryPath, XMLFileName));
        ExportDEBDTI."Obligation Level".SetValue(LibraryRandom.RandIntInRange(1, 5));
        ExportDEBDTI.OK.Invoke;
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

