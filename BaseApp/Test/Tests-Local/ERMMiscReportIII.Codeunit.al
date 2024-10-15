codeunit 142062 "ERM Misc. Report III"
{
    // Verify ERM Miscellaneous Reports:
    //  1. Verify Aged Accounts Payable Report with Due Date option.
    //  2. Verify Aged Accounts Payable Report with Trans Date option.
    //  3. Verify Aged Accounts Payable Report with Document Date option.
    //  4. Verify Payment Journal Test Report with Show Dimensions option.
    //  5. Verify Top Vendor List Report with Show as Balances.
    //  6. Verify Top Vendor List Report with Show as Purchases.
    //  7. Verify Sales Invoice Report with Company Address and without Log Interaction.
    //  8. Verify Sales Invoice Report without Company Address and with Log Interaction.
    //  9. Verify Sales Shipment Report with Company Address and Log Interaction.
    // 10. Verify Sales Quote Report with Company Address and Log Interaction.
    // 11. Verify Sales Order Report with Company Address and Log Interaction.
    // 12. Verify Sales Credit Memo Report with Company Address and Log Interaction.
    // 13. Verify Item Turnover Report with Item No. filter.
    // 14. Verify Item Turnover Report with only Date filter and other fields are blank.
    // 15. Verify Purchase Advice Report without filter.
    // 16. Verify Purchase Advice Report using filters.
    // 17. Verify Purchase Order Status Report without filter.
    // 18. Verify Purchase Order Status Report With filters.
    // 19. Verify GST/HST Internet File Transfer Report without Start Date.
    // 20. Verify GST/HST Internet File Transfer Report without End Date.
    // 21. Verify Sales Order Report with Line Amount Excl. Tax. BUGID:151937.
    // 23. Verify Sales Invoice Report with 'Show Assembly Components' option.
    // 32. Verify Total caption for Sales Invoice Report (given currency).
    // 33. Verify Total caption for Sales Invoice Report (local currency).
    // 34. Verify Total caption for Purchase Invoice Report (given currency).
    // 35. Verify Total caption for Purchase Invoice Report (local currency).
    // 
    // Covers Test Cases for WI - 332267
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // PaymentJournalTestWithShowDimensions                                                            171128
    // TopVendorListWithShowAsBalances, TopVendorListWithShowAsPurchases                               171178
    // 
    // Covers Test Cases for WI - 329576
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportWithCompanyAddress, SalesInvoiceReportWithLogInteraction                      157066
    // SalesShipmentReport                                                                             171083
    // SalesQuoteReport                                                                                171082
    // SalesOrderReport                                                                                171081
    // SalesCreditMemoReport                                                                           171079
    // 
    // Covers Test Cases for WI - 327944
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // RunItemTurnOverWithItemNoFilter, RunItemTurnOverWithDatefilter                                  171090
    // RunPurchaseAdviceReportWithoutFilter, RunPurchaseAdviceReportWithFilters                        171103
    // RunPurchaseOrderStatusReportWithoutFilter, RunPurchaseOrderStatusReportWithFilters              171100
    // 
    // Covers Test Cases for WI - 330785
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // GSTHSTInternetFileTransferWithBlankStartDate                                                    202397
    // GSTHSTInternetFileTransferWithBlankEndDate                                                      202397
    // 
    // Covers Test Cases for WI - 338154
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesOrderConfirmationReport                                                                    151937
    // 
    // BUG ID 58797
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name
    // ------------------------------------------------------------------------------------------------------
    // AgedAccountsPayableWithUseExternalDocNo
    // 
    // Covers Test Cases for HFR - 351480
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportWithAssemblyComponents                                                        351480
    // 
    // Covers Test Cases for HFR - 354445
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // CheckTotalAmountOnAgedAccountsPayable,CheckTotalAmountOnReportWithMultipleVendor                354445
    // CheckTotalAmountOnAgedAccountsReceivable,CheckTotalAmountOnReportWithMultipleCustomer
    // CheckTotalAmountOnAgedAccountsPayableWithCurrency,
    // CheckTotalAmountOnReportWithMultipleVendorWithCurrency,
    // CheckTotalAmountOnAgedAccountsReceivableWithCurrency,
    // CheckTotalAmountOnReportWithMultipleCustomerWithCurrency
    // 
    // Covers Test Cases for HFR - 351480
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // SalesInvoiceReportTotalsWithCurrency                                                            360300
    // SalesInvoiceReportTotalsWithoutCurrency                                                         360300
    // PurchInvoiceReportTotalsWithCurrency                                                            360300
    // PurchInvoiceReportTotalsWithoutCurrency                                                         360300

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        AmountDue1Cap: Label 'AmountDue_1_';
        AmountDue2Cap: Label 'AmountDue_2_';
        AmountDue3Cap: Label 'AmountDue_3_';
        AmountDue4Cap: Label 'AmountDue_4_';
        BalancesCap: Label 'Balances';
        ColHeadCap: Label 'ColHead';
        CompanyAddress: Label 'CompanyAddress1';
        CrMemoItemNo: Label 'TempSalesCrMemoLineNo';
        CrMemoQuantity: Label 'TempSalesCrMemoLineQty';
        DimTextCap: Label 'DimText';
        "Filter": Label '%1..%2';
        Filter2: Label '%1 - %2';
        GLAccNetChangeNetChangeinJnlCap: Label 'GLAccNetChange__Net_Change_in_Jnl__';
        GenJournaLineDocumentNoCap: Label 'Gen__Journal_Line__Document_No__';
        GenJournalLineAccountNoCap: Label 'Gen__Journal_Line__Account_No__';
        GenJournalLineAmountCap: Label 'Gen__Journal_Line_Amount';
        GrandTotalCap: Label 'GrandTotal';
        ICaption: Label 'i', Comment = 'i for Rank';
        InvoiceItemNo: Label 'TempSalesInvoiceLineNo';
        ItemNoCap: Label 'Item__No__';
        MainTitleCap: Label 'MainTitle_';
        DateError: Label '%1 should not be blank.';
        OrderedQty: Label 'OrderedQuantity';
        QtyOnSalesOrder: Label 'Item__Qty__on_Sales_Order_';
        PurchasesCap: Label 'Purchases';
        PurchaseLineQuantity: Label 'Purchase_Line_Quantity';
        SalesInvoiceNo: Label 'No_SalesInvHeader';
        SalesShipmentNo: Label 'No_SalesShptHeader';
        SalesHeaderNo: Label 'No_SalesHeader';
        SalesCrMemoNo: Label 'No_SalesCrMemoHeader';
        SalesLineItemNo: Label 'TempSalesLineNo';
        SalesLineQuantity: Label 'TempSalesLineQuantity';
        ShipmentItemNo: Label 'TempSalesShptLineNo';
        ShortDateTitleCap: Label 'ShortDateTitle';
        TrxDateCap: Label 'Trx Date';
        Top2VendorsCap: Label 'Top 20 Vendors';
        TopNoiCaption: Label 'TopNo_i_';
        TopAmountiCaption: Label 'TopAmount_i_';
        TopCap: Label 'Top__';
        TotalPrice: Label 'AmountExclInvDisc';
        ValueMustMatch: Label 'Value must match.';
        WrongTotalAmountErr: Label 'Wrong total Amount.';
        GrandTotalBalanceDueCap: Label 'GrandTotalBalanceDue_';
        GrandBalanceDue1Cap: Label 'GrandBalanceDue_1_';
        GrandBalanceDue2Cap: Label 'GrandBalanceDue_2_';
        GrandBalanceDue3Cap: Label 'GrandBalanceDue_3_';
        GrandBalanceDue4Cap: Label 'GrandBalanceDue_4_';
        PercentString1Cap: Label 'PercentString_1_';
        PercentString2Cap: Label 'PercentString_2_';
        PercentString3Cap: Label 'PercentString_3_';
        PercentString4Cap: Label 'PercentString_4_';
        TotalBalanceDueCap: Label 'TotalBalanceDue__';
        BalanceDue1Cap: Label 'BalanceDue___1_';
        BalanceDue2Cap: Label 'BalanceDue___2_';
        BalanceDue3Cap: Label 'BalanceDue___3_';
        BalanceDue4Cap: Label 'BalanceDue___4_';
        FormatString: Label '<Precision,2:3><Standard Format,2>';
        TotalCaptionCapTxt: Label 'TotalCaption';
        TotalCaptionTxt: Label 'Total %1:';
        PurchaseInvoiceNoTxt: Label 'No_PurchInvHeader';
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        FieldMustBeVisibleInAreaErr: Label 'Field %1 must be visible in %2.';
        TestFieldNotFoundErr: Label 'TestFieldNotFound';

    [Test]
    [HandlerFunctions('PaymentJournalTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalTestWithShowDimensions()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Payment Journal Test report with Show Dimensions option.

        // Setup: Create a payment entry for a vendor with dimensions.
        Initialize;
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, CreateVendor, Dimension.Code, DimensionValue.Code);
        CreateGenJournalLine(
          GenJournalLine, DefaultDimension."No.", GenJournalLine."Account Type"::Vendor,
          LibraryRandom.RandDec(10, 2));

        // Enqueue values for PaymentJournalTestRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Payment Journal - Test");

        // Verify: Verify Dimension and Amounts on generated Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, StrSubstNo(Filter2, Dimension.Code, DimensionValue.Code));
        LibraryReportDataset.AssertElementWithValueExists(GLAccNetChangeNetChangeinJnlCap, -GenJournalLine.Amount);
        VerifyValuesOnReport(
          GenJournalLine."Document No.", GenJournaLineDocumentNoCap, GenJournalLineAccountNoCap, GenJournalLine."Account No.");
        LibraryReportDataset.AssertCurrentRowValueEquals(GenJournalLineAmountCap, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopVendorListWithShowAsBalances()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Verify Top Vendor List Report with Show as Balances.

        // Setup: Create and post invoices for two vendors.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);  // Use random for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Use random for Direct Unit Cost.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry, Quantity, 3 * DirectUnitCost);  // To generate greater amount.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry2, Quantity, DirectUnitCost);
        EnqueueValuesForReport(StrSubstNo(Filter, VendorLedgerEntry."Vendor No.", VendorLedgerEntry2."Vendor No."), 0);  // Using 0 for Balances option.

        // Exercise.
        REPORT.Run(REPORT::"Top __ Vendor List");

        // Verify: Verify rank and amount on generated Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportTopVendorList(
          BalancesCap, VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry2."Vendor No.", Abs(VendorLedgerEntry."Amount (LCY)"), Abs(VendorLedgerEntry2."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('TopVendorListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopVendorListWithShowAsPurchases()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Verify Top Vendor List Report with Show as Purchases.

        // Setup: Create and post invoices for two vendors.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);  // Use random for Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Use random for Direct Unit Cost.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry, Quantity, 3 * DirectUnitCost);  // To generate greater amount.
        CreateAndPostInvoiceAndFindVendorLedgerEntry(VendorLedgerEntry2, Quantity, DirectUnitCost);
        EnqueueValuesForReport(StrSubstNo(Filter, VendorLedgerEntry."Vendor No.", VendorLedgerEntry2."Vendor No."), 1);  // Using 1 for Purchases option.

        // Exercise.
        REPORT.Run(REPORT::"Top __ Vendor List");

        // Verify: Verify rank and amount on generated Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportTopVendorList(
          PurchasesCap, VendorLedgerEntry."Vendor No.",
          VendorLedgerEntry2."Vendor No.", Abs(VendorLedgerEntry."Purchase (LCY)"), Abs(VendorLedgerEntry2."Purchase (LCY)"));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithCompanyAddress()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify Sales Invoice Report with Company Address and without Log Interaction.
        Initialize;
        CompanyInformation.Get();
        RunAndVerifySalesInvoiceReport(CompanyInformation.Name, true, false, true);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithLogInteraction()
    begin
        // Verify Sales Invoice Report without Company Address and with Log Interaction.
        Initialize;
        RunAndVerifySalesInvoiceReport('', false, true, false);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Sales Shipment Report with Company Address and Log Interaction.

        // Setup: Create and post Sales Invoice.
        Initialize;
        CompanyInformation.Get();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Order, false);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for SalesShipmentRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Shipment NA");

        // Verify: Verify Company Information and Posted Sales Shipment values on Sales Shipment Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, CompanyAddress, CompanyInformation.Name);
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, ShipmentItemNo, SalesLine."No.");
        VerifyValuesOnReport(DocumentNo, SalesShipmentNo, OrderedQty, SalesLine.Quantity);
        VerifyLogInteraction(DocumentNo, false);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Quote Report with Company Address and Log Interaction.

        // Setup: Create Sales Quote.
        Initialize;
        CompanyInformation.Get();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesQuoteRequestPageHandler.
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Quote NA");

        // Verify: Verify Company Information and Sales Quote values on Sales Quote Report.
        VerifySalesReport(
          SalesLine, SalesLine."Document No.", CompanyInformation.Name, SalesHeaderNo, SalesLineItemNo, SalesLineQuantity, false);
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order Report with Company Address and Log Interaction.

        // Setup: Create Sales Order.
        Initialize;
        CompanyInformation.Get();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesOrderRequestPageHandler.
        Commit();  // Required to run the Report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Order");

        // Verify: Verify Company Information and Sales Order values on Sales Order Report.
        VerifySalesReport(
          SalesLine, SalesLine."Document No.", CompanyInformation.Name, SalesHeaderNo, SalesLineItemNo, SalesLineQuantity, false);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoReport()
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Sales Credit Memo Report with Company Address and Log Interaction.

        // Setup: Create and post Sales Credit Memo.
        Initialize;
        CompanyInformation.Get();
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", true);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue value for SalesCreditMemoRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Sales Credit Memo NA");

        // Verify: Verify Company Information and Posted Sales Credit Memo values on Sales Credit Memo Report.
        VerifySalesReport(SalesLine, DocumentNo, CompanyInformation.Name, SalesCrMemoNo, CrMemoItemNo, CrMemoQuantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunItemTurnOverWithItemNoFilter()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item Turnover Report with Item No. filter.

        // Setup.
        Initialize;
        CreateAndPostItemJournalLine(ItemJournalLine);

        // Exercise.
        RunItemTurnoverReport(ItemJournalLine."Item No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(ItemNoCap, ItemJournalLine."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTurnoverReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunItemTurnOverWithDatefilter()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
    begin
        // Verify Item Turnover Report with only Date filter and other fields are blank.

        // Setup: Create and post Item Journal with different Items.
        Initialize;
        CreateAndPostItemJournalLine(ItemJournalLine);
        CreateAndPostItemJournalLine(ItemJournalLine2);

        // Exercise.
        RunItemTurnoverReport('');  // Using blank value for Item No. filter.

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyReportValues(ItemNoCap, ItemJournalLine."Item No.", ItemJournalLine2."Item No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseAdviceReportWithoutFilter()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Purchase Advice Report without filter.
        RunAndVerifyPurchaseAdviceReport(SalesLine, 0D, '');  // Using blank value for Item No. filter.
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseAdviceReportWithFilters()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Purchase Advice Report using filters.
        RunAndVerifyPurchaseAdviceReport(SalesLine, WorkDate, SalesLine."No.");
    end;

    local procedure RunAndVerifyPurchaseAdviceReport(var SalesLine: Record "Sales Line"; DateFilter: Date; No: Code[20])
    begin
        // Setup: Create Sales Order
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);

        // Exercise.
        RunPurchaseAdviceReport(DateFilter, No);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(QtyOnSalesOrder, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatusReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseOrderStatusReportWithoutFilter()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Status Report without filter.
        RunAndVerifyPurchaseOrderStatusReport(PurchaseLine, 0D, '');  // Using blank value for Item No. filter.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatusReqPageHandler')]
    [Scope('OnPrem')]
    procedure RunPurchaseOrderStatusReportWithFilters()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Status Report With filters.
        RunAndVerifyPurchaseOrderStatusReport(PurchaseLine, WorkDate, PurchaseLine."No.");
    end;

    local procedure RunAndVerifyPurchaseOrderStatusReport(var PurchaseLine: Record "Purchase Line"; DateFilter: Date; No: Code[20])
    begin
        // Setup: Create Purchase Order.
        Initialize;
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateItem,
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Used Random value for Quantity.

        // Exercise.
        RunPurchaseOrderStatusReport(DateFilter, No);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLineQuantity, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferWithBlankStartDate()
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without Start Date.
        GSTHSTInternetFileTransferWithoutMandatoryFilters(0D, WorkDate, 'Start Date');  // Taking 0D for Starting Date.
    end;

    [Test]
    [HandlerFunctions('GSTHSTInternetFileTransferRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferWithBlankEndDate()
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without End Date.
        GSTHSTInternetFileTransferWithoutMandatoryFilters(WorkDate, 0D, 'End Date');  // Taking 0D for End Date.
    end;

    local procedure GSTHSTInternetFileTransferWithoutMandatoryFilters(StartDate: Date; EndDate: Date; DateString: Text[10])
    begin
        // Verify the error thrown when report GST/HST Internet File Transfer is run without mandatory filters.

        // Setup.
        Initialize;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        LibraryVariableStorage.Enqueue(StartDate);  // Enqueue values for GSTHSTInternetFileTransferRequestPageHandler.
        LibraryVariableStorage.Enqueue(EndDate);
        Commit();  // Required to run the report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"GST/HST Internet File Transfer");

        // Verify.
        Assert.ExpectedError(StrSubstNo(DateError, DateString));
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderConfirmationReport()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order Report with Line Amount Excl. Tax. BUGID:151937.

        // Setup: Create Sales Order.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");  // Enqueue value for SalesOrderRequestPageHandler.
        Commit();  // Codeunit 313 Sales-Printed OnRun Calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Sales Order");

        // Verify: Verify Total Price on Sales Order Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(TotalPrice, SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceAssemblyRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportWithAssemblyComponents()
    begin
        // Verify Sales Invoice Report with 'Show Assembly Components' option.
        Initialize;
        LibraryApplicationArea.DisableApplicationAreaSetup;
        RunAndVerifySalesInvoiceReportAssembly(2);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportTotalsWithCurrency()
    begin
        // Verify Total caption for Sales Invoice Report (given currency).
        Initialize;
        RunAndVerifySalesInvoiceReportTotals(CreateCurrencyWithExchangeRate);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportTotalsWithoutCurrency()
    begin
        // Verify Total caption for Sales Invoice Report (local currency).
        Initialize;
        RunAndVerifySalesInvoiceReportTotals('');
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportTotalsWithCurrency()
    var
        Vendor: Record Vendor;
    begin
        // Verify Total caption for Purchase Invoice Report (given currency).
        Initialize;
        CreateVendorWithCurrency(Vendor);
        RunAndVerifyPurchInvoiceReportTotals(Vendor);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportTotalsWithoutCurrency()
    var
        Vendor: Record Vendor;
    begin
        // Verify Total caption for Purchase Invoice Report (local currency).
        Initialize;
        LibraryPurchase.CreateVendor(Vendor);
        RunAndVerifyPurchInvoiceReportTotals(Vendor);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceAssemblyRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportComponentOrderQtyWithAdjmtValueEntry()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Sales Invoice] [Assembly]
        // [SCENARIO 375200] Sales Invoice Report should not take into account adjustment Value Entry for calculating Order Qty of assembly components
        Initialize;
        LibraryApplicationArea.DisableApplicationAreaSetup;

        // [GIVEN] Component Item with "Quantity Per" = "X" of Assembly Item
        // [GIVEN] Posted Sales Invoice for Assembly Item for Quantity = "Y"
        // [GIVEN] Adjustment Value Entry for Component Item of Quantity = "X * Y"
        Qty := LibraryRandom.RandDec(10, 2);
        QtyPer := LibraryRandom.RandDec(10, 2);

        CreateSalesDocumentWithItem(SalesLine, SalesLine."Document Type"::Order, CreateAssemblyItemWithComponents(1, QtyPer), Qty);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run Sales Invoice Report with option "DisplayAsmInfo"
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for SalesInvoiceAssemblyRequestPageHandler
        LibraryVariableStorage.Enqueue(true); // Show Assembly Components
        REPORT.Run(REPORT::"Sales Invoice NA");

        // [THEN] "Order Qty" in Sales Invoice Report for Component Item is "X * Y"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesInvHeader', DocumentNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('TempPostedAsmLineQuantity', QtyPer * Qty);
    end;

    [HandlerFunctions('GenJournalBatchesPageHandler,ConfirmHandler,DepositRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckTotalDepositReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Deposit: Report Deposit;
        DocumentNo: Code[20];
        TotalDepositAmount: Decimal;
    begin
        // [SCENARIO 376193] Totals should be showing and correct in Deposit report after applying
        Initialize;

        // [GIVEN] Deposit with one line applying to posted sales invoice
        // [GIVEN] Total Deposit Amount = "X"
        UpdateGLSetupDepositNos;
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, true);
        TotalDepositAmount := CreateAndPostDepositWithApplyDoc(DocumentNo, SalesLine."Sell-to Customer No.");
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName);
        Commit();

        // [WHEN] Invoke Deposit report
        Deposit.Run;

        // [THEN] Field of total = "X"
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValueOnWorksheet(
          17, 12, LibraryReportValidation.FormatDecimalValue(TotalDepositAmount), '1');
    end;

    [Test]
    [HandlerFunctions('SalesInvReqPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvReportAdditionalDescription()
    var
        DocumentNo: Code[20];
        Desc: array[2] of Text;
        DescLineNo: array[2] of Integer;
    begin
        // [SCENARIO 378362] Additional descriptions in posted sales invoice should be show on Sales Invoice report
        Initialize;

        // [GIVEN] Posted sales invoice with additional descriptions in lines
        // [GIVEN] First line has Type = Item
        // [GIVEN] Second and third lines have Type = <blank> and descriptions = "DESC1"/"DESC2"
        DocumentNo := CreateAndPostSalesInvWithAdditionalDescription(Desc, DescLineNo);

        // [WHEN] Invoke Sales Invoice report
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(REPORT::"Sales Invoice NA");

        // [THEN] Report should contain line with "DESC1"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('TempSalesInvoiceLineLineNo', DescLineNo[1]);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('HighDescriptionToPrint', Desc[1]);

        // [THEN] Report should contain line with "DESC2"
        LibraryReportDataset.SetRange('TempSalesInvoiceLineLineNo', DescLineNo[2]);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('HighDescriptionToPrint', Desc[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingListReportAvailableInSuiteAppArea()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 256995] "Picking List by Order" report should be available under #Suite application area

        Initialize;
        LibrarySales.DisableWarningOnCloseUnpostedDoc;

        LibraryApplicationArea.EnableFoundationSetup;
        SalesOrder.OpenView;
        Assert.IsTrue(SalesOrder."Report Picking List by Order".Enabled, 'Action must be enabled in Foundation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingListReportNotAvailableInBasicAppArea()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 256995] "Picking List by Order" report should not be available under #Basic application area

        Initialize;
        LibrarySales.DisableWarningOnCloseUnpostedDoc;

        LibraryApplicationArea.EnableBasicSetup;
        SalesOrder.OpenView;
        asserterror SalesOrder."Report Picking List by Order".Invoke;

        Assert.ExpectedErrorCode('TestActionNotFound');
    end;

    [Test]
    [HandlerFunctions('PrintStubStubCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubStubCheck()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10401 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10401 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Stub/Check)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubStubCheckReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubStubCheck()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10401 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10401 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Stub/Check)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubCheckStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10411 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10411 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Check/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintStubCheckStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepStubCheckStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10411 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10411 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Stub/Check/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepCheckStubStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10412 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintCheckStubStubReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepCheckStubStub()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10412 Check is 10
        MaxEntries := 10;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10412 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Check (Check/Stub/Stub)");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintThreeChecksPerPageReqPageHandler')]
    [Scope('OnPrem')]
    procedure VendorCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepThreeChecksPerPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Vendor]
        // [SCENARIO 294940] Vendor Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Maximum amount of entries on one page of REP10413 Check is 30
        MaxEntries := 30;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Vendor, Vendor."No.", -1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);

        // [GIVEN] Report 10413 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Three Checks per Page");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PrintThreeChecksPerPageReqPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCheckForPaymentExceedingSumOfMaxIterationsInvoicesRepThreeChecksPerPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReportSelections: Record "Report Selections";
        PaymentJournal: TestPage "Payment Journal";
        MaxEntries: Integer;
        PaymentAmount: Integer;
    begin
        // [FEATURE] [Report] [Check] [Customer]
        // [SCENARIO 294940] Customer Check total is equal to Payment Amount, when Payment Amount is larger than sum of 10 Purchases
        Initialize;

        // [GIVEN] "External Document No Mandatory" set to false
        LibraryPurchase.SetExtDocNo(false);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Maximum amount of entries on one page of REP10413 Check is 30
        MaxEntries := 30;

        // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
        // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
        SetupGenJournalLinesForCheckReports(
          GenJournalLine, PaymentAmount, MaxEntries, GenJournalLine."Account Type"::Customer, Customer."No.", 1);

        // [GIVEN] Ledger Entries "Applies-to ID" is set to Paymet Gen. Jnl. Line "Document No."
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // [GIVEN] Report 10413 is set as report for Check
        ReportSelections.Get(ReportSelections.Usage::"B.Check", 1);
        ReportSelections.Validate("Report ID", REPORT::"Three Checks per Page");
        ReportSelections.Modify(true);

        // [WHEN] Check printed from Payment Journal page
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10000)));
        BankAccount.Modify(true);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();

        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentJournal.PrintCheck.Invoke;

        // [THEN] Check Total is equal to Payment ammount
        VerifyTotalLineAmountOnReport(PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order" available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Order", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order" available under #Suite application area
        Initialize;

        LibraryApplicationArea.EnableFoundationSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Order", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderPrePrintedRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order (Pre-Printed)" available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Order (Pre-Printed)", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Basic'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderPrePrintedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseOrderPrePrintedRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Order (Pre-Printed)" available under #Suite application area
        Initialize;

        LibraryApplicationArea.EnableFoundationSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Order (Pre-Printed)", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckReturnOrderConfirmRequestPageOptonsVisibilityInPurchaseReturnOrderAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Return Order Confirm" available under #PurchaseReturnOrder application area
        Initialize;

        LibraryApplicationArea.EnablePurchaseReturnOrderSetup;
        Commit();

        REPORT.Run(REPORT::"Return Order Confirm", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Purchase Return Order'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Purchase Return Order'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Purchase Return Order'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Purchase Return Order'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckReturnOrderConfirmRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Return Order Confirm" are not available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Return Order Confirm", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseBlanketOrderRequestPageOptonsVisibilityInFoundationAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Blanket Order" available under #Suite application area
        Initialize;

        LibraryApplicationArea.EnableFoundationSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Blanket Order", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Foundation'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseBlanketOrderWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseBlanketOrderRequestPageOptonsVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Purchase Blanket Order" are not available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Purchase Blanket Order", true, false, PurchaseHeader);

        with LibraryVariableStorage do begin
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceCrMemoSalesTaxRequestPageOptonsVisibilityInServiceAppArea()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" available under #Service application area
        Initialize;

        LibraryApplicationArea.EnableServiceManagementSetup;
        Commit();

        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax", true, false, ServiceCrMemoHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Service'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Service'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoSalesTaxWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceCrMemoSalesTaxRequestPageOptonsVisibilityInBasicAppArea()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" are not available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Service Credit Memo-Sales Tax", true, false, ServiceCrMemoHeader);

        with LibraryVariableStorage do begin
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceSalesTaxRequestPageOptonsVisibilityInServiceAppArea()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" available under #Service application area
        Initialize;

        LibraryApplicationArea.EnableServiceManagementSetup;
        Commit();

        REPORT.Run(REPORT::"Service Invoice-Sales Tax", true, false, ServiceInvoiceHeader);

        with LibraryVariableStorage do begin
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Service'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Service'));
            Assert.IsTrue(DequeueBoolean, StrSubstNo(FieldMustBeVisibleInAreaErr, DequeueText, 'Service'));
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceSalesTaxWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceInvoiceSalesTaxRequestPageOptonsVisibilityInBasicAppArea()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [Purchase] [Application Area] [UT]
        // [SCENARIO 313611] Request page options of report "Service Credit Memo-Sales Tax" are not available under #Basic application area
        Initialize;

        LibraryApplicationArea.EnableBasicSetup;
        Commit();

        REPORT.Run(REPORT::"Service Invoice-Sales Tax", true, false, ServiceInvoiceHeader);

        with LibraryVariableStorage do begin
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            Assert.AreEqual(TestFieldNotFoundErr, DequeueText, '');
            AssertEmpty;
        end;

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceSaveAsPDFReqPageHandler')]
    [Scope('OnPrem')]
    procedure PrintPurchaseAdvice()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 333888] Report "Purchase Advice" can be printed without RDLC rendering errors
        Initialize;

        // [WHEN] Report "Purchase Advice" is being printed to PDF
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        RunPurchaseAdviceReport(WorkDate, SalesLine."No.");

        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceSKUVisibilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseAdviceUseSKUOptionVisibilityInWarehouseAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Stockkeeping Unit] [Planning] [Application Area] [UT]
        // [SCENARIO 367615] "Use Stockkeeping Unit" option of report "Purchase Advice" is available under #Planning application area        Initialize();
        Initialize();

        EnablePlanningApplicationAreaSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Advice", true, false);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), StrSubstNo(FieldMustBeVisibleInAreaErr, LibraryVariableStorage.DequeueText(), 'Planning'));
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('PurchaseAdviceWithErrorRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPurchaseAdviceUseSKUOptionVisibilityInBasicAppArea()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Stockkeeping Unit] [Basic] [Application Area] [UT]
        // [SCENARIO 367615] "Use Stockkeeping Unit" option of report "Purchase Advice" is not available under #Basic application area
        Initialize();

        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        REPORT.Run(REPORT::"Purchase Advice", true, false);

        Assert.AreEqual(TestFieldNotFoundErr, LibraryVariableStorage.DequeueText(), '');
        LibraryVariableStorage.AssertEmpty();

        // Tear Down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        TaxSetup: Record "Tax Setup";
    begin
        LibrarySetupStorage.Restore;
        LibraryApplicationArea.EnableFoundationSetup;

        if IsInitialized then
            exit;

        LibraryVariableStorage.Clear;
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData;

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure CalculateAmountWithCurrency(CurrencyCode: Code[10]; var Amount: array[4] of Decimal) GrandTotal: Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Factor: Decimal;
        Counter: Integer;
    begin
        Factor := CurrencyExchangeRate.GetCurrentCurrencyFactor(CurrencyCode);
        for Counter := 1 to ArrayLen(Amount) do begin
            Amount[Counter] := Amount[Counter] / Factor;
            GrandTotal += Amount[Counter];
        end;
    end;

    local procedure CalculateGrandTotal(Amount: array[4] of Decimal) GrandTotal: Decimal
    var
        Counter: Integer;
    begin
        for Counter := 1 to ArrayLen(Amount) do
            GrandTotal += Amount[Counter];
    end;

    local procedure CreateGenJournalLineWithBankAccount(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; BankPaymentType: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DateInterval: Text; AccountNo: Code[20]; AccountType: Option; Amount: Decimal)
    var
        PeriodDifference: DateFormula;
    begin
        CreateGenJournalLine(GenJournalLine, AccountNo, AccountType, Amount);
        Evaluate(PeriodDifference, DateInterval);
        GenJournalLine.Validate("Posting Date", CalcDate(PeriodDifference, GenJournalLine."Posting Date"));
        // Test MAX length = 35 (TFS ID: 305391)
        GenJournalLine."External Document No." := CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostGenJournalLines(GenJnlTemplateType: Option; "Page": Option; DocumentType: Integer; AccountType: Option; AccountNo: Code[20]; GenJnlLinesCount: Integer; PurchaseAmount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalTemplate.Get(LibraryJournals.SelectGenJournalTemplate(GenJnlTemplateType, Page));
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        with GenJournalLine do begin
            for i := 1 to GenJnlLinesCount do
                LibraryJournals.CreateGenJournalLine2(
                  GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocumentType,
                  AccountType, AccountNo, "Account Type"::"G/L Account", GLAccount."No.", PurchaseAmount);
            // Test MAX length = 35 (TFS ID: 305391)
            "External Document No." := CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1);
            Modify;

            SetRange("Account No.", AccountNo);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure CreateAndPostMultipleGenJnlLine(AccountType: Option; AccountNo: Code[20]; GenJournalLineAmount: Decimal; var TotalAmount: array[4] of Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        Counter: Integer;
    begin
        for Counter := 1 to ArrayLen(TotalAmount) do begin
            CreateAndPostGenJournalLine(
              GenJournalLine, StrSubstNo('<-%1M>', Counter - 1), AccountNo, AccountType, GenJournalLineAmount);
            TotalAmount[Counter] := Abs(GenJournalLineAmount);
        end;
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; ToInvoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, ToInvoice));
    end;

    local procedure CreateAndPostSalesDocumentWithCustomer(var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; ToInvoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, CustomerNo, CreateItem, LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, ToInvoice));
    end;

    local procedure CreateAndPostInvoiceAndFindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostPurchaseInvoice(CreateItem, Quantity, DirectUnitCost);
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
    end;

    local procedure CreateAndPostPurchaseInvoice(ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, ItemNo, Quantity, DirectUnitCost);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVendor(ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocumentWithVendor(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, ItemNo, Quantity, DirectUnitCost, VendorNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          CreateItem, LibraryRandom.RandDec(100, 2));  // Using Random values for Quantity.
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(1000, 2));  // Using Random values for Unit Amount.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithQty(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, Quantity);  // Using Random values for Quantity.
        with ItemJournalLine do begin
            Validate("Unit Amount", LibraryRandom.RandDec(1000, 2));  // Using Random values for Unit Amount.
            Validate("Location Code", LocationCode);
            Modify(true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostSalesInvWithAdditionalDescription(var Desc: array[2] of Text; var DescLineNo: array[2] of Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        CreateBlankSalesLineWithDesc(Desc[1], DescLineNo[1], SalesHeader."No.", SalesHeader."Document Type");
        CreateBlankSalesLineWithDesc(Desc[2], DescLineNo[2], SalesHeader."No.", SalesHeader."Document Type");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBlankSalesLineWithDesc(var Desc: Text; var DescLineNo: Integer; DocNo: Code[20]; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine."Document No." := DocNo;
        SalesLine."Document Type" := DocumentType;
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        DescLineNo := SalesLine."Line No.";
        SalesLine.Description := LibraryUtility.GenerateGUID;
        Desc := SalesLine.Description + ' ';
        SalesLine.Insert();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Maximum Inventory", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAssemblyItemWithComponents(NumberOfComponents: Integer; QtyPer: Decimal): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
        LibraryAssembly: Codeunit "Library - Assembly";
        ItemNo: Code[20];
    begin
        LibraryAssembly.CreateItem(
          AssemblyItem, AssemblyItem."Costing Method"::Average, AssemblyItem."Replenishment System"::Assembly, '', '');
        AssemblyItem.Validate("Assembly Policy", AssemblyItem."Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        AssemblyItem.Modify(true);
        if NumberOfComponents <= 0 then
            NumberOfComponents := 1;
        while NumberOfComponents > 0 do begin
            NumberOfComponents -= 1;
            ItemNo := CreateItem;
            CreateAndPostItemJournalLineWithQty(ItemNo, 100 + LibraryRandom.RandDec(10, 2), '');
            LibraryAssembly.CreateAssemblyListComponent(
              BOMComponent.Type::Item, ItemNo, AssemblyItem."No.", '',
              BOMComponent."Resource Usage Type", QtyPer, true);
        end;
        exit(AssemblyItem."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Option; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreatePaymentGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        CreatePurchaseDocumentWithVendor(PurchaseLine, DocumentType, ItemNo, Quantity, DirectUnitCost, CreateVendor);
    end;

    local procedure CreatePurchaseDocumentWithVendor(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, Customer."No.", CreateItem, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesDocumentWithItem(var SalesLine: Record "Sales Line"; DocumentType: Option; ItemNo: Code[20]; Qty: Decimal)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithCustomerAndItem(SalesLine, DocumentType, Customer."No.", ItemNo, Qty);
    end;

    local procedure CreateSalesDocumentWithCustomerAndItem(var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrencyWithExchangeRate);
        Vendor.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Modify(true);
        CreateExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(
          CurrencyExchangeRate, CurrencyCode, CalcDate(StrSubstNo('<-%1M>', LibraryRandom.RandIntInRange(4, 8)), WorkDate));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDecInDecimalRange(50, 100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount",
          LibraryRandom.RandIntInRange(2, 5) * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateAndPostDepositWithApplyDoc(DocumentNo: Code[20]; CustomerNo: Code[20]): Decimal
    var
        DepositHeader: Record "Deposit Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibrarySales.CreateDepositHeader(DepositHeader, GenJournalBatch);
        DepositHeader.Validate("Bank Account No.", LibraryERM.CreateBankAccountNo);
        DepositHeader.Modify(true);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
          -LibraryRandom.RandInt(1000));
        ApplyCustLedgerEntry(DocumentNo, GenJournalLine."Document No.");
        DepositHeader.CalcFields("Total Deposit Lines");
        DepositHeader."Total Deposit Amount" := DepositHeader."Total Deposit Lines";
        DepositHeader.Modify();
        LibraryVariableStorage.Enqueue(DepositHeader."No.");
        LibrarySales.PostDepositDocument(DepositHeader);
        exit(DepositHeader."Total Deposit Amount");
    end;

    local procedure ApplyCustLedgerEntry(DocumentNo: Code[20]; GenJnlLineNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst;
        CustLedgerEntry."Applies-to Doc. No." := GenJnlLineNo;
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Modify();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure EnqueueValuesForReport(VendorNo: Text; OptionValue: Option)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue values for TopVendorListRequestPageHandler.
        LibraryVariableStorage.Enqueue(OptionValue);
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst;
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst;
    end;

    local procedure RunAndVerifySalesInvoiceReport(CompanyInformationName: Text[100]; PrintCompany: Boolean; LogInteraction: Boolean; ActualLogInteraction: Boolean)
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        DocumentNo := CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(PrintCompany);
        LibraryVariableStorage.Enqueue(LogInteraction);

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify: Verify Company Information and Posted Sales Invoice values on Sales Invoice Report.
        VerifySalesReport(SalesLine, DocumentNo, CompanyInformationName, SalesInvoiceNo, InvoiceItemNo, OrderedQty, ActualLogInteraction);
    end;

    local procedure RunAndVerifySalesInvoiceReportAssembly(NumberOfComponents: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LibraryInventory: Codeunit "Library - Inventory";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Order.
        CreateSalesDocumentWithItem(
          SalesLine, SalesLine."Document Type"::Order,
          CreateAssemblyItemWithComponents(NumberOfComponents, LibraryRandom.RandDec(10, 2)), LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(true); // Show Assembly Components

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify: Verify total Amount in report.
        VerifySalesReportWithAssembly(SalesLine.Amount);
    end;

    local procedure RunAndVerifySalesInvoiceReportTotals(CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        CreateCustomerWithCurrency(Customer, CurrencyCode);
        DocumentNo := CreateAndPostSalesDocumentWithCustomer(SalesLine, SalesLine."Document Type"::Invoice, Customer."No.", true);

        // Enqueue value for SalesInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(false); // PrintCompany
        LibraryVariableStorage.Enqueue(false); // LogInteraction

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice NA");

        // Verify.
        VerifySalesPurchaseReportTotals(DocumentNo, SalesInvoiceNo, CurrencyCode);
    end;

    local procedure RunAndVerifyPurchInvoiceReportTotals(Vendor: Record Vendor)
    var
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice.
        DocumentNo :=
          CreateAndPostPurchaseInvoiceWithVendor(
            CreateItem, LibraryRandom.RandIntInRange(1, 10),
            LibraryRandom.RandDecInDecimalRange(10, 100, 2), Vendor."No.");

        // Enqueue value for PurchaseInvoiceRequestPageHandler.
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Purchase Invoice NA");

        // Verify.
        VerifySalesPurchaseReportTotals(DocumentNo, PurchaseInvoiceNoTxt, Vendor."Currency Code");
    end;

    local procedure RunItemTurnoverReport(ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for ItemTurnoverReqPageHandler.
        REPORT.Run(REPORT::"Item Turnover");
    end;

    local procedure RunPurchaseAdviceReport(PostingDate: Date; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue value for PurchaseAdviceReqPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for PurchaseAdviceReqPageHandler.
        Commit();  // Commit is required to run Report.
        REPORT.Run(REPORT::"Purchase Advice");
    end;

    local procedure RunPurchaseOrderStatusReport(PostingDate: Date; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue value for PurchaseOrderStatusReqPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue value for PurchaseOrderStatusReqPageHandler.
        Commit();  // Commit is required to run Report.
        REPORT.Run(REPORT::"Purchase Order Status");
    end;

    local procedure SetupGenJournalLinesForCheckReports(var GenJournalLine: Record "Gen. Journal Line"; var PaymentAmt: Integer; MaxEntries: Integer; AccountType: Option; AccountNo: Code[20]; Sign: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchaseAmt: Integer;
    begin
        PurchaseAmt := Sign * LibraryRandom.RandInt(10);
        with GenJournalLine do begin
            // [GIVEN] Payment Gen. Jnl Line with Payment amount larger than sum of posted Purchases
            PaymentAmt := LibraryRandom.RandIntInRange(Sign * (MaxEntries + 1) * PurchaseAmt, Sign * (MaxEntries + 9) * PurchaseAmt);
            CreateGenJournalLineWithBankAccount(
              GenJournalLine, "Document Type"::Payment, AccountType,
              AccountNo, PaymentAmt, "Bank Payment Type"::"Computer Check");
            Validate("Applies-to ID", UserId);
            Modify(true);
            // [GIVEN] MaxEntries number of Purchases Gen. Jnl Lines posted
            CreateAndPostGenJournalLines(
              GenJournalTemplate.Type::Purchases, PAGE::"Purchase Journal",
              "Document Type"::Invoice, AccountType, AccountNo, MaxEntries, PurchaseAmt);
        end;
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateGLSetupDepositNos()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Deposit Nos." := LibraryERM.CreateNoSeriesCode;
        GeneralLedgerSetup.Modify();
    end;

    local procedure EnablePlanningApplicationAreaSetup()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        ApplicationAreaSetup.Validate("Company Name", CompanyName);
        ApplicationAreaSetup.Validate(Planning, true);
        ApplicationAreaSetup.Insert(true);
        ApplicationAreaMgmtFacade.SetupApplicationArea();
    end;

    local procedure ValidateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        VendorInvoiceNo: Code[35];
    begin
        VendorInvoiceNo := CopyStr(LibraryUTUtility.GetNewCode + LibraryUTUtility.GetNewCode, 1, MaxStrLen(VendorInvoiceNo));
        with PurchaseHeader do begin
            Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            Validate("Vendor Invoice No.", VendorInvoiceNo);
            Modify(true);
        end;
    end;

    local procedure VerifyLogInteraction(DocumentNo: Code[20]; ActualLogInteraction: Boolean)
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        ExpLogInteraction: Boolean;
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        ExpLogInteraction := InteractionLogEntry.IsEmpty;
        Assert.AreEqual(ExpLogInteraction, ActualLogInteraction, ValueMustMatch)
    end;

    local procedure VerifyReportTopVendorList(ColHeadValue: Text[50]; VendorNo: Code[20]; VendorNo2: Code[20]; Amount: Decimal; Amount2: Decimal)
    var
        TotalAmount: Decimal;
    begin
        TotalAmount := Amount + Amount2;
        LibraryReportDataset.AssertElementWithValueExists(MainTitleCap, Format(Top2VendorsCap));
        LibraryReportDataset.AssertElementWithValueExists(ColHeadCap, Format(ColHeadValue));
        VerifyValuesOnTopVendorList(VendorNo, Amount, Round(Amount * 100 / TotalAmount), TotalAmount, 1);  // Using 1 for Rank 1.
        VerifyValuesOnTopVendorList(VendorNo2, Amount2, Round(Amount2 * 100 / TotalAmount), TotalAmount, 2);  // Using 2 for Rank 2.
    end;

    local procedure VerifySalesReport(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; CompanyInformationName: Text[100]; DocumentNoCap: Text[50]; ItemNoCap: Text[50]; QuantityCap: Text[50]; ActualLogInteraction: Boolean)
    begin
        LibraryReportDataset.LoadDataSetFile;
        if SalesLine."Document Type" <> SalesLine."Document Type"::Quote then
            VerifyValuesOnReport(DocumentNo, DocumentNoCap, CompanyAddress, CompanyInformationName);
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, ItemNoCap, SalesLine."No.");
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, QuantityCap, SalesLine.Quantity);
        VerifyValuesOnReport(DocumentNo, DocumentNoCap, TotalPrice, SalesLine.Amount);
        VerifyLogInteraction(DocumentNo, ActualLogInteraction);
    end;

    local procedure VerifySalesReportWithAssembly(TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        Assert.AreEqual(TotalAmount, LibraryReportDataset.Sum(TotalPrice), WrongTotalAmountErr);
    end;

    local procedure VerifySalesPurchaseReportTotals(DocumentNo: Code[20]; DocumentNoCaption: Text[50]; CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            CurrencyCode := GetLCYCode;
        LibraryReportDataset.LoadDataSetFile;
        VerifyValuesOnReport(DocumentNo, DocumentNoCaption, TotalCaptionCapTxt, StrSubstNo(TotalCaptionTxt, CurrencyCode));
    end;

    local procedure VerifyTotalLineAmountOnReport(Amount: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('TotalLineAmount', Amount);
    end;

    local procedure VerifyValuesOnTopVendorList(VendorNo: Code[20]; Amount: Decimal; Percentage: Decimal; TotalAmount: Decimal; Rank: Integer)
    begin
        VerifyValuesOnReport(Rank, ICaption, TopNoiCaption, VendorNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(TopAmountiCaption, Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(TopCap, Percentage);
        LibraryReportDataset.AssertCurrentRowValueEquals(GrandTotalCap, TotalAmount);
    end;

    local procedure VerifyValuesOnReport(RowValue: Variant; RowCaption: Text[50]; ValueCaption: Text[50]; Value: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals(ValueCaption, Value);
    end;

    local procedure VerifyReportValues(RowCaption: Text[50]; RowValue: Code[20]; RowValue1: Code[20])
    begin
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue);
        LibraryReportDataset.AssertElementWithValueExists(RowCaption, RowValue1);
    end;

    local procedure VerifyBalanceDueValuesOnReport(Amount: array[4] of Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(BalanceDue1Cap, -Amount[1]);
        LibraryReportDataset.AssertElementWithValueExists(BalanceDue2Cap, -Amount[2]);
        LibraryReportDataset.AssertElementWithValueExists(BalanceDue3Cap, -Amount[3]);
        LibraryReportDataset.AssertElementWithValueExists(BalanceDue4Cap, -Amount[4]);
    end;

    local procedure VerifyTotalValuesOnReport(Amount: array[4] of Decimal; Amount2: array[4] of Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue1Cap, -(Amount[1] + Amount2[1]));
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue2Cap, -(Amount[2] + Amount2[2]));
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue3Cap, -(Amount[3] + Amount2[3]));
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue4Cap, -(Amount[4] + Amount2[4]));
    end;

    local procedure VerifyTotalAndPercentageValuesOnReport(GrandTotal: Decimal; Amount: array[4] of Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(GrandTotalBalanceDueCap, GrandTotal);
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue1Cap, -Amount[1]);
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue2Cap, -Amount[2]);
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue3Cap, -Amount[3]);
        LibraryReportDataset.AssertElementWithValueExists(GrandBalanceDue4Cap, -Amount[4]);
        LibraryReportDataset.AssertElementWithValueExists(
          PercentString1Cap, Format(Round(-Amount[1] / GrandTotal * 100), 0, FormatString) + '%');
        LibraryReportDataset.AssertElementWithValueExists(
          PercentString2Cap, Format(Round(-Amount[2] / GrandTotal * 100), 0, FormatString) + '%');
        LibraryReportDataset.AssertElementWithValueExists(
          PercentString3Cap, Format(Round(-Amount[3] / GrandTotal * 100), 0, FormatString) + '%');
        LibraryReportDataset.AssertElementWithValueExists(
          PercentString4Cap, Format(Round(-Amount[4] / GrandTotal * 100), 0, FormatString) + '%');
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GSTHSTInternetFileTransferRequestPageHandler(var GSTHSTInternetFileTransfer: TestRequestPage "GST/HST Internet File Transfer")
    var
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        GSTHSTInternetFileTransfer.StartDate.SetValue(StartDate);
        GSTHSTInternetFileTransfer.EndDate.SetValue(EndDate);
        GSTHSTInternetFileTransfer.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalTestRequestPageHandler(var PaymentJournalTest: TestRequestPage "Payment Journal - Test")
    var
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        PaymentJournalTest.ShowDimensions.SetValue(true);
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        PaymentJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        PaymentJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintStubStubCheckReqPageHandler(var Check: TestRequestPage "Check (Stub/Stub/Check)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintStubCheckStubReqPageHandler(var Check: TestRequestPage "Check (Stub/Check/Stub)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintCheckStubStubReqPageHandler(var Check: TestRequestPage "Check (Check/Stub/Stub)")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrintThreeChecksPerPageReqPageHandler(var Check: TestRequestPage "Three Checks per Page")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        Check.BankAccount.SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        Check.OneCheckPerVendorPerDocumentNo.SetValue(Value);

        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
        LibraryVariableStorage.Dequeue(LogInteraction);
        SalesInvoice.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        SalesInvoice.LogInteraction.SetValue(LogInteraction);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceAssemblyRequestPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    var
        No: Variant;
        ShowAssemblyComponents: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAssemblyComponents);
        SalesInvoice.DisplayAsmInfo.SetValue(ShowAssemblyComponents);
        SalesInvoice."Sales Invoice Header".SetFilter("No.", No);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvReqPageHandler(var SalesInvoice: TestRequestPage "Sales Invoice NA")
    begin
        SalesInvoice."Sales Invoice Header".SetFilter("No.", LibraryVariableStorage.DequeueText);
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales Shipment NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesShipment.PrintCompanyAddress.SetValue(true);
        SalesShipment.LogInteraction.SetValue(true);
        SalesShipment."Sales Shipment Header".SetFilter("No.", No);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Sales Quote NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesQuote.PrintCompanyAddress.SetValue(true);
        SalesQuote.LogInteraction.SetValue(true);
        SalesQuote."Sales Header".SetFilter("No.", No);
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesOrder.PrintCompanyAddress.SetValue(true);
        SalesOrder.LogInteraction.SetValue(true);
        SalesOrder."Sales Header".SetFilter("No.", No);
        SalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales Credit Memo NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesCreditMemo.PrintCompanyAddress.SetValue(true);
        SalesCreditMemo.LogInteraction.SetValue(true);
        SalesCreditMemo."Sales Cr.Memo Header".SetFilter("No.", No);
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Caption);
        PurchaseBlanketOrder.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderWithErrorRequestPageHandler(var PurchaseBlanketOrder: TestRequestPage "Purchase Blanket Order")
    begin
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(PurchaseBlanketOrder.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        PurchaseBlanketOrder.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderRequestPageHandler(var PurchaseOrder: TestRequestPage "Purchase Order")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrder.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrder.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrder.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.ArchiveDocument.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrder.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrder.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrder.LogInteraction.Caption);
        PurchaseOrder.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrePrintedRequestPageHandler(var PurchaseOrderPrePrinted: TestRequestPage "Purchase Order (Pre-Printed)")
    begin
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.ArchiveDocument.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(PurchaseOrderPrePrinted.LogInteraction.Caption);
        PurchaseOrderPrePrinted.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    begin
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Visible);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Caption);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Caption);
        ReturnOrderConfirm.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmWithErrorRequestPageHandler(var ReturnOrderConfirm: TestRequestPage "Return Order Confirm")
    begin
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.ArchiveDocument.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ReturnOrderConfirm.LogInteraction.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ReturnOrderConfirm.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSalesTaxRequestPageHandler(var ServiceCreditMemoSalesTax: TestRequestPage "Service Credit Memo-Sales Tax")
    begin
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Caption);
        ServiceCreditMemoSalesTax.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoSalesTaxWithErrorRequestPageHandler(var ServiceCreditMemoSalesTax: TestRequestPage "Service Credit Memo-Sales Tax")
    begin
        asserterror LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceCreditMemoSalesTax.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ServiceCreditMemoSalesTax.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxRequestPageHandler(var ServiceInvoiceSalesTax: TestRequestPage "Service Invoice-Sales Tax")
    begin
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Caption);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Caption);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Visible);
        LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Caption);
        ServiceInvoiceSalesTax.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceSalesTaxWithErrorRequestPageHandler(var ServiceInvoiceSalesTax: TestRequestPage "Service Invoice-Sales Tax")
    begin
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.NumberOfCopies.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.PrintCompanyAddress.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        asserterror LibraryVariableStorage.Enqueue(ServiceInvoiceSalesTax.DisplayAdditionalFeeNote.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        ServiceInvoiceSalesTax.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TopVendorListRequestPageHandler(var TopVendorList: TestRequestPage "Top __ Vendor List")
    var
        VendorNo: Variant;
        Show: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(Show);
        TopVendorList.Show.SetValue(Show);
        TopVendorList.Vendor.SetFilter("No.", VendorNo);
        TopVendorList.Vendor.SetFilter("Date Filter", Format(WorkDate));
        TopVendorList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTurnoverReqPageHandler(var ItemTurnover: TestRequestPage "Item Turnover")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemTurnover.Item.SetFilter("Date Filter", Format(WorkDate));
        ItemTurnover.Item.SetFilter("No.", ItemNo);
        ItemTurnover.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceReqPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseAdvice.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseAdvice.Item.SetFilter("No.", ItemNo);
        PurchaseAdvice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceSKUVisibilityRequestPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Visible);
        LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Caption);
        PurchaseAdvice.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceWithErrorRequestPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        asserterror LibraryVariableStorage.Enqueue(PurchaseAdvice.UseSKU.Visible);
        LibraryVariableStorage.Enqueue(GetLastErrorCode);
        PurchaseAdvice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatusReqPageHandler(var PurchaseOrderStatus: TestRequestPage "Purchase Order Status")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseOrderStatus.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseOrderStatus.Item.SetFilter("No.", ItemNo);
        PurchaseOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DepositRequestPageHandler(var Deposit: TestRequestPage Deposit)
    var
        DepositNo: Variant;
        FileName: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepositNo);
        LibraryVariableStorage.Dequeue(FileName);
        Deposit."Posted Deposit Header".SetFilter("No.", DepositNo);
        Deposit.SaveAsExcel(FileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAdviceSaveAsPDFReqPageHandler(var PurchaseAdvice: TestRequestPage "Purchase Advice")
    var
        PostingDate: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(ItemNo);
        PurchaseAdvice.Item.SetFilter("Date Filter", Format(PostingDate));
        PurchaseAdvice.Item.SetFilter("No.", ItemNo);
        PurchaseAdvice.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

