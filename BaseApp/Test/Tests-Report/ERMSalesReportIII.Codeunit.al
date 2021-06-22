codeunit 134984 "ERM Sales Report III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report][Sales]
    end;

    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryDimension: Codeunit "Library - Dimension";
        FileManagement: Codeunit "File Management";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RecordErr: Label '%1 must exist.', Comment = '%1 = Table Name';
        HeaderDimensionTxt: Label '%1%2%3', Locked = true;
        TotalLCYTxt: Label 'Total (LCY)';
        TotalCapTxt: Label 'Total';
        PrepaymentPostErr: Label '%1 must be completely preinvoiced before you can ship or invoice the line.', Comment = '%1=Field Caption';
        CustBalanceCustLedgEntryTxt: Label 'CustBalance_CustLedgEntryHdrFooter';
        DocEntryTableNameTxt: Label 'DocEntryTableName';
        DocEntryNoofRecordsTxt: Label 'DocEntryNoofRecords';
        CrMemoPostingDtTxt: Label 'PostDt_SalesCrMemoHeader';
        CrMemoAmtTxt: Label 'Amt_SalesCrMemoHeader';
        InvPostingDtTxt: Label 'PostDate_SalesInvHeader';
        InvAmtTxt: Label 'Amt_SalesInvHeader';
        WarningTxt: Label 'Warning!';
        EntriesExistTxt: Label 'true';
        TotalTxt: Label 'total';
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        isInitialized: Boolean;
        ReportStandardSalesCreditMemoErr: Label 'File of report Standard Sales - Credit Memo not found.';
        SalesCrMemoNoTxt: Label 'No_SalesCrMemoHeader';
        TotalAmtSalesCrMemoTxt: Label 'NNCTotalAmtInclVat';
        WrongExchRateErr: Label 'Wrong exchange rate.';
        VALExchRateTok: Label 'VALExchRate';
        VATIdentifierTok: Label 'VATAmountLine__VAT_Identifier__Control241';
        EnterDateFormulaErr: Label 'Enter a date formula in the Period Length field.';
        RowVisibilityErr: Label 'Analysis row must only be visible in Sales Analysis Matrix when Show <> No.';
        ColumnVisibilityErr: Label 'Analysis column must only be visible in Sales Analysis Matrix when Show <> Never.';
        ColumnDoesNotExistErr: Label 'Analysis column does not exist in Analysis Column Template and therefore must not be visible.';
        RowPrintedMultiplyErr: Label 'Analysis row must be printed only once.';
        RunReportNotSupportedErr: Label 'The method RunReport is not supported for TestPages';
        Rep1302DatasetErr: Label 'Wrong REP1302 "Standard Sales - Pro Forma Inv" dataset.';

    [Test]
    [HandlerFunctions('RHSalesCreditMemo')]
    [Scope('OnPrem')]
    procedure SalesCreditMemo()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Credit Memo Report without any option.

        // Create Sales Credit Memo and Post it and Save Sales Credit Memo Report.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        PostAndSaveSalesCreditMemo(SalesLine, Customer."No.", false, false);

        // Verify: Verify Saved Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesCrMemoLine', SalesLine."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmt_SalesCrMemoLine', SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('RHSalesCreditMemo')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoInternalInfo()
    var
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Credit Memo Report with Internal Information.

        // Create Sales Credit Memo and Post it and Save Sales Credit Memo Report.
        Initialize;
        PostAndSaveSalesCreditMemo(SalesLine, CreateCustomerWithDimension(DimensionValue), true, false);
        LibraryReportDataset.LoadDataSetFile;

        // Verify: Verify Report Data with Dimension.
        VerifyInternalInformation(DimensionValue, ' ');
    end;

    [Test]
    [HandlerFunctions('RHSalesCreditMemo')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoLogEntry()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Check Sales Credit Memo Report with Log Entry.

        // Create Blanket Sales Order.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        DocumentNo := PostAndSaveSalesCreditMemo(SalesLine, Customer."No.", false, true);
        LibraryReportDataset.LoadDataSetFile;

        // Verify: Verify Interaction Log Entry Record.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Cr. Memo", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrder()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Check Blanket Sales Order Report without any Option.

        // Setup: Create Blanket Sales Order.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", Customer."No.", '');

        // Exercise: Save Blanket Sales Order Report.
        SaveBlanketSalesOrder(SalesLine."Document No.", false);
        LibraryReportDataset.LoadDataSetFile;

        // Verify: Verify Saved Report.
        LibraryReportDataset.SetRange('No_SalesLine', SalesLine."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalSalesLineAmount', SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('RHBlanketSalesOrder')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderInternalInfo()
    var
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
    begin
        // Check Blanket Sales Order Report with Dimension.

        // Setup: Create Sales Blanket Order with Dimension.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", CreateCustomerWithDimension(DimensionValue), '');

        // Exercise.
        SaveBlanketSalesOrder(SalesLine."Document No.", true);

        // Verify: Verify Report Data with Dimension.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInternalInformation(DimensionValue, ' ');
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithReceive()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Ship Option.
        Initialize;
        SetupSalesDocumentTest(SalesLine, true, false);
        VerifySalesDocumentTestSalesLine(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithInvoice()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Ship and Invoice Option.
        Initialize;
        SetupSalesDocumentTest(SalesLine, true, true);
        VerifySalesDocumentTestSalesLine(SalesLine);

        // Verify: Verify Report Data.
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Qty__to_Invoice_', SalesLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithDimension()
    var
        DimensionValue: Record "Dimension Value";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report with Show Dimension Option.

        // Setup: Crate Sales Order with Dimension.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomerWithDimension(DimensionValue), '');

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, true, false);

        // Verify: Verify Report Data with Dimension.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInternalInformation(DimensionValue, ' - ');
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestItemCharge()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemCharge: Record "Item Charge";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Check Sales Document Test Report with Item Charge Option.

        // Setup: Crate Sales Order and Item Charge Sales Line.
        Initialize;
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '');

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.");

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, true);

        // Verify: Verify Report Data.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Item_Charge_Assignment__Sales___Item_No__', ItemCharge."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_Charge_Assignment__Sales___Qty__to_Assign_', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestForCreditMemo()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Document Test Report for Invoice Discount on Credit Memo.

        // Setup: Update New No. Series in Sales and Receivables Setup.
        Initialize;
        SetupSalesAndReceivablesSetup(LibraryUtility.GetGlobalNoSeriesCode);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", SetupInvoiceDiscount, '');
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesLine."Document No.", SalesLine."Line No.");

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, false);

        // Verify: Verify Report Data for Invoice Discount and other column values.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInvoiceDiscountInReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocTestForCreditMemoInvDiscAmt()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Document - Test]
        // [SCENARIO 363729] When printing the Sales Document - Test Report the invoice discount is displayed
        Initialize;

        // [GIVEN] Sales & Receivables Setup option "Calc. Inv. Discount" is set to YES
        UpdateSalesReceivablesSetupCalcInvDisc(true);

        // [GIVEN] Sales Credit Memo with Invoice Discount Amount = "X"
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", CreateCustomer, '');

        // [WHEN] Run Sales Document - Test Report
        RunSalesCreditMemoTestReport(SalesLine."Document No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Invoice Discount Amount "X" is shown on the report
        VerifyInvoiceDiscountInReport(SalesLine);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Sales Document Test Report with VAT on Credit Memo.

        // Setup: Update Sales Receivables Setup and Create Sales Credit Memo. Calculate VAT Amount Lines.
        Initialize;
        SetupSalesAndReceivablesSetup(LibraryUtility.GetGlobalNoSeriesCode);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", CreateCustomer, '');
        SalesHeader.Get(SalesLine."Document Type"::"Credit Memo", SalesLine."Document No.");
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", false, false, false, false);

        // Verify.
        LibraryReportDataset.LoadDataSetFile;
        VerifyVATEntries('VATAmountLine__VAT_Identifier_', 'VATAmountLine__VAT___', 'VATAmountLine__VAT_Base_',
          'VATAmountLine__Line_Amount_', 'VATAmountLine__Inv__Disc__Base_Amount_');
    end;

    [Test]
    [HandlerFunctions('RHCustomerPaymentReceipt')]
    [Scope('OnPrem')]
    procedure CustomerPaymentReceipt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPaymentReceipt: Report "Customer - Payment Receipt";
        PmtDiscAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Customer - Payment Receipt]
        // Check Customer Payment Receipt Report.

        // Setup: Post Invoice and Payment Entries for a Customer. Take Random Values for Invoice and Payment Amount.
        Initialize;
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtDiscAmount := CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount, CreateCustomer, '');

        // Exercise: Save Customer Payment Receipt Report.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        Clear(CustomerPaymentReceipt);
        CustomerPaymentReceipt.SetTableView(CustLedgerEntry);
        CustomerPaymentReceipt.Run;

        // Verify: Verify values on Customer Payment Receipt Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyCustomerPaymentReceipt(GenJournalLine."Document No.", -PmtDiscAmount, InvoiceAmount, Round(GenJournalLine.Amount));
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipment()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Check Sales Shipment Report without any option.

        // Setup.
        Initialize;
        Quantity := CreateAndPostSalesShipment(DocumentNo, CreateCustomer);

        // Exercise: Save Sales Shipment Report with no options checked.
        SaveSalesShipmentReport(DocumentNo, false, false, false);

        // Verify: Verify Shipped Quantity in Report.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst;

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesShptLine', SalesShipmentLine."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', Quantity);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentInternalInfo()
    var
        DimensionValue: Record "Dimension Value";
        DocumentNo: Code[20];
    begin
        // Check Internal Information on Sales Shipment Report.

        // Setup: Create and Post Sales Shipment with Customer having Dimensions attached.
        Initialize;
        CreateAndPostSalesShipment(DocumentNo, CreateCustomerWithDimension(DimensionValue));

        // Exercise: Save Sales Shipment Report with Show Internal Information option checked.
        SaveSalesShipmentReport(DocumentNo, true, false, false);

        // Verify: Verify Internal Information in saved Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInternalInformation(DimensionValue, ' - ');
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentLogInteraction()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentNo: Code[20];
    begin
        // Check Interaction Log Entries created after running Sales Shipment Report.

        // Setup.
        Initialize;
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer);

        // Exercise: Save Sales Shipment Report with Log Interaction option checked.
        SaveSalesShipmentReport(DocumentNo, false, true, false);

        // Verify: Verify Interaction Log Entry Record.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Shpt. Note", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment,UndoShipmentConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentCorrectionLines()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // Check Correction Entry on Sales Shipment Report.

        // Setup: Create and Post Sales Shipment and then undo the Shipment.
        Initialize;
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer);

        // Undo the Shipment.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst;
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // Exercise: Save Sales Shipment Report.
        SaveSalesShipmentReport(DocumentNo, false, false, true);

        // Verify: Verify Undone entry in Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyUndoneQuantityInReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHSalesShipment')]
    [Scope('OnPrem')]
    procedure SalesShipmentOrderNoAndExternalDocumentNoArePrinted()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [UI] [Shipment]
        // [SCENARIO 225799] "Order No." and "External Document No." are shown with their captions when report "Sales - Shipment" is printed for Shipment
        Initialize;

        // [GIVEN] Shipment Header with "External Document No." = "XXX" and "Order No." = "YYY"
        SalesShipmentHeader."No." := LibraryUtility.GenerateGUID;
        SalesShipmentHeader."External Document No." := LibraryUtility.GenerateGUID;
        SalesShipmentHeader."Order No." := LibraryUtility.GenerateGUID;
        SalesShipmentHeader.Insert;

        // [WHEN] Export report "Sales - Shipment" to XML file
        SaveSalesShipmentReport(SalesShipmentHeader."No.", false, false, false);
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "Purchase Order No." is displayed under Tag <ExternalDocumentNoCaption_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ExternalDocumentNoCaption_SalesShptHeader', 'Purchase Order No.');

        // [THEN] Value "XXX" is displayed under Tag <ExternalDocumentNo_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ExternalDocumentNo_SalesShptHeader', SalesShipmentHeader."External Document No.");

        // [THEN] Value "Our Document No." is displayed under Tag <OrderNoCaption_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('OrderNoCaption_SalesShptHeader', 'Our Document No.');

        // [THEN] Value "YYY" is displayed under tag <OrderNo_SalesShptHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('OrderNo_SalesShptHeader', SalesShipmentHeader."Order No.");
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecDueDate()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATAmount: Decimal;
        PeriodLength: DateFormula;
        NoOfDays: Text[30];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Due Date.

        // Setup: Create and Post Sales Order with Modify Due Date on Sales Header and Calculate VAT Amount with Random Values.
        Initialize;
        NoOfDays := Format(LibraryRandom.RandInt(5));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Due Date", CalcDate('<' + NoOfDays + 'D>', SalesHeader."Posting Date"));
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));
        Evaluate(PeriodLength, '<' + NoOfDays + 'M>');

        // Exercise: Save Aged Account Receivable Report with Aging By Due Date.
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount
          , VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecPostingDate()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Posting Date.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Posting Date.
        Initialize;
        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Posting Date",
            HeadingType::"Date Interval", false, false, '');

        // Verify: Verify Saved Report Data with Aging by Posting Date. 1D is Required by Increasing Date with 1 Day.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecDocumentDate()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PeriodLength: DateFormula;
        NoOfDays: Text[30];
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Aging By Document Date.

        // Setup: Create and Post Sales Order with Modify Document Date on Sales Header and Calculate VAT Amount with Random Values.
        Initialize;
        NoOfDays := Format(LibraryRandom.RandInt(5));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, CreateCustomer, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Document Date", CalcDate('<' + NoOfDays + 'D>', SalesHeader."Posting Date"));
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));
        Evaluate(PeriodLength, '<' + NoOfDays + 'M>');

        // Exercise: Save Aged Account Receivable Report with Aging By Document Date.
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Document Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data with Balance Amount and Heading Type with Date Interval.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, 0,
          VATAmount, 0);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecFalsePrintAmtLCY()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        VATAmount2: Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Amount LCY False.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Print Amount LCY.
        Initialize;
        GeneralLedgerSetup.Get;
        CreateAndPostSalesDocument(SalesLine, CreateCustomer, SalesLine."Document Type"::Order, '', true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));

        CreateAndPostSalesDocument(SalesLine2, CreateCustomer, SalesLine."Document Type"::Order, '', true);
        VATAmount2 := Round(SalesLine2."Line Amount" + (SalesLine2."Line Amount" * SalesLine2."VAT %" / 100));

        // Exercise: Take Period Length with Random Values.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetFilter("No.", '%1|%2', SalesLine."Sell-to Customer No.", SalesLine2."Sell-to Customer No.");
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify Saved Report Data with Print Amount LCY FALSE.
        LibraryReportDataset.LoadDataSetFile;

        LibraryReportDataset.SetRange('No_Cust', SalesLine."Sell-to Customer No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('CurrrencyCode', GeneralLedgerSetup."LCY Code");

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('CurrSpecificationCptn', 'Currency Specification');
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE6RemAmt', VATAmount + VATAmount2);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('TotalLCYCptn', TotalLCYTxt);
        LibraryReportDataset.SetRange('No_Cust', SalesLine2."Sell-to Customer No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('GrandTotalCLEAmtLCY', VATAmount + VATAmount2);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecTruePrintAmtLCY()
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        VATAmountLCY: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Amount LCY TRUE.

        // Create and Post Sales Order and Save Aged Account Receivable Report with Print Amount LCY.
        Initialize;
        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date", HeadingType::"Date Interval",
            true, false, CreateCurrencyAndExchangeRate);
        Currency.Get(SalesLine."Currency Code");
        VATAmount := Round(VATAmount, Currency."Invoice Rounding Precision");
        VATAmountLCY := LibraryERM.ConvertCurrency(Round(VATAmount, Currency."Invoice Rounding Precision"), Currency.Code, '', WorkDate);

        // Verify: Verify Saved Report Data with Print Amount LCY FALSE.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmountLCY, VATAmountLCY);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecNoOfDays()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        PostedDocNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Heading Type No. of Days.

        // Create and Post Sales Order, Save Aged Account Receivable Report with Heading Type No. of Days.
        Initialize;

        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date",
            HeadingType::"Number of Days", false, false, '');

        // Verify: Verify Saved Report Data with Heading Type No. of Days.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecPrintDetails()
    var
        SalesLine: Record "Sales Line";
        PeriodLength: DateFormula;
        VATAmount: Decimal;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Check Aged Account Receivable Report with Print Details.

        // Create and Post Sales Order, Save Aged Account Receivable Report with Print Details.
        Initialize;

        VATAmount := SetupAgedAccountsReceivable(SalesLine, PostedDocNo, PeriodLength, AgingBy::"Due Date",
            HeadingType::"Date Interval", false, true, '');

        // Verify: Verify Saved Report Data with Print Details TRUE.
        VerifyAgedAccountsRecReport(PostedDocNo, SalesLine."Sell-to Customer No.", VATAmount, VATAmount,
          VATAmount, VATAmount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateAllFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PmtDiscAmount: Decimal;
        InvoiceAmount: Decimal;
    begin
        // Check Customer Balance To Date Report without any Option Selected.

        // Setup: Create and Post Invoice and Payment Entries for Customer. Take Random Values for Invoice and Payment Amount.
        Initialize;
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        PmtDiscAmount := CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount, CreateCustomer, '');

        // Exercise: Save Customer Balance To Date Report without any Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", false, false);
        LibraryReportDataset.LoadDataSetFile;

        // Verify: Verify Values on Report.
        VerifyCustomerBalanceToDate(GenJournalLine, InvoiceAmount, PmtDiscAmount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateAmountLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceAmount: Decimal;
        InvAmountLCY: Decimal;
        PmtAmountLCY: Decimal;
    begin
        // Check Customer Balance To Date Report with Show Amount in LCY Option Selected.

        // Setup: Create and Post Invoice and Payment Entries for Customer with Currency Code. Take Random Invoice Amount and Make sure that
        // Payment Amount is Lesser than Invoice Amount to Post Partial Payment.
        Initialize;
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount / 2, CreateCustomerWithCurrency, '');
        InvAmountLCY := LibraryERM.ConvertCurrency(InvoiceAmount, GenJournalLine."Currency Code", '', WorkDate);
        PmtAmountLCY := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");

        // Exercise: Save Customer Balance To Date Report with Show Amount in LCY Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", true, false);

        // Verify: Verify Values on Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyCustBalanceToDateWithLCY(CustLedgerEntry, InvAmountLCY, PmtAmountLCY);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateUnapplied()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        InvoiceAmount: Decimal;
    begin
        // Check Customer Balance To Date Report with Include Unapplied Entries Option Selected.

        // Setup: Create and Post Invoice and Payment Entry for Customer. Unapply Payment Entry. Take Random Invoice Amount.
        // Divide Invoice Amount by Two to make Payment Amount partial.
        Initialize;
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJournalLines(GenJournalLine, InvoiceAmount, -InvoiceAmount / 2, CreateCustomer, '');
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERMUnapply.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // Exercise: Save Customer Balance To Date Report with Include Unapplied Entries Option Checked.
        SaveCustomerBalanceToDate(GenJournalLine."Account No.", false, true);

        // Verify: Verify Unapplied Values on Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyUnappliedEntries(GenJournalLine, InvoiceAmount, CustLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Return Order Confirmation Report for VAT Amount.

        // Setup: Create Sales Return Order and Calculate VAT Amount.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomer, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Save Report with default value.
        SaveReturnOrderReport(SalesLine."Document No.", false, false);

        // Verify: Verify Report Data for VAT.
        LibraryReportDataset.LoadDataSetFile;
        VerifyVATEntries('VATAmtLineVATIdentifier', 'VATAmtLineVATPercentage',
          'VATAmtLineVATBase', 'VATAmtLineLineAmt', 'VATAmtLineInvDiscBaseAmt');
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrderWithInternalInfo()
    var
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // Check Return Order Confirmation Report with Dimension.

        // Setup: Create Sales Return Order with Dimension.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomerWithDimension(DimensionValue), '');

        // Exercise: Save Report using TRUE to show Internal Info.
        SaveReturnOrderReport(SalesLine."Document No.", true, false);

        // Verify: Verify Report Data for Dimension.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInternalInformation(DimensionValue, ' ');
    end;

    [Test]
    [HandlerFunctions('RHReturnOrderConfirmation')]
    [Scope('OnPrem')]
    procedure ReturnOrderWithLogInfo()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SalesLine: Record "Sales Line";
    begin
        // Check Return Order Confirmation Report for Log Interaction Entry.

        // Setup: Create Sales Return Order and Calculate VAT Amount.
        Initialize;
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", CreateCustomer, '');

        // Exercise: Save Report using TRUE to make Log Interaction Enry.
        SaveReturnOrderReport(SalesLine."Document No.", false, true);

        // Verify: Verify Interaction Log Entry Record.
        LibraryReportDataset.LoadDataSetFile;
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Sales Return Order", SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PostAndApplyCustPageHandler,PostApplicationPageHandler,MessageHandler,RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReport()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify that program filter data correctly by date in Aged Accounts Receivable report.

        // Setup: Create Customer,Post Invoice and Payment and apply it.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2)); // Take Random Amount.

        // In Bug 215283,Invoice should be made before the Payment is posted.Hence, taking Random Date before the workdate.
        GenJournalLine.Validate("Posting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Make Payment by dividing Invoice amount from Random no.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -(GenJournalLine.Amount / LibraryRandom.RandIntInRange(2, 5)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Account No.");
        Customer.Get(Customer."No.");
        Customer.CalcFields(Balance);

        // Exercise: Save Aged Accounts Receivables Report.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>'); // Take Random value for Period length.
        Customer.SetRecFilter;
        Commit;
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify the Balance in the report.
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', Customer.Balance);
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithoutPrepaymentInvoicePost()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Warnings on Sales Document Test Report of Sales Order before posting Prepayment Invoice.

        // Setup: Create Sales Order with Prepayment % and enter different values for 'Type' in Sales Line.
        Initialize;
        CreateSalesOrderWithDifferentLineType(SalesHeader);

        // Exercise: Run and Save Sales Document Test Report.
        SaveSalesDocumentTest(SalesHeader."No.", true, true, false, false);

        // Verify: Verify Warning message on Sales Document Test Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifySalesDocumentTestReport;
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestWithPrepaymentInvoicePost()
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        VATAmount: Decimal;
        VATPercent: Decimal;
        PrepaymentTotalAmount: Decimal;
    begin
        // Verify data on Sales Document Test Report of Sales Order after posting Prepayment Invoice.

        // Setup: Create Sales Order with Prepayment % and enter different values for 'Type' in Sales Line.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateGLAccount(GLAccount, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPercent := CreateSalesOrderWithDifferentLineType(SalesHeader);

        // Perform summation of Prepayment Line Amount for further validation and post Prepayment Invoice.
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            PrepaymentTotalAmount += SalesLine."Prepmt. Line Amount";
        until SalesLine.Next = 0;

        VATAmount := PrepaymentTotalAmount * VATPercent / 100;
        SalesPostPrepayments.Invoice(SalesHeader);

        // Exercise: Run and Save Sales Document Test Report.
        SaveSalesDocumentTest(SalesHeader."No.", true, true, false, false);

        // Verify: Verify data on Sales Document Test Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyDataOnSalesDocumentTestReport(VATAmount, VATPercent, PrepaymentTotalAmount);
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReportWithGenLines()
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
        InvoiceAmount: Decimal;
    begin
        // Check Customer Statement Report with Posted General Line.

        // Setup: Create Invoice and Payment General Line for Customer and Random Values.
        Initialize;
        CreateCustomerAndPostGenJnlLines(Customer, InvoiceAmount);

        // Exercise: Save Statement Report with Random Period Length.
        Clear(Statement);

        Customer.SetRange("No.", Customer."No.");
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          false, false, true, false, false, false, '<' + Format(LibraryRandom.RandInt(5)) + 'M>',
          DateChoice::"Due Date", true, WorkDate, WorkDate);
        Commit;
        Statement.Run;

        // Verify: Verify Saved Data in Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Amt_DtldCustLedgEntries', -InvoiceAmount * 2);
        LibraryReportDataset.AssertElementWithValueExists('RemainAmt_DtldCustLedgEntries', -InvoiceAmount * 2);
        LibraryReportDataset.AssertElementWithValueExists('CustBalance', -InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCustomerStatementReportTotalLine()
    var
        Customer: Record Customer;
        InvoiceAmount: Decimal;
    begin
        // Check Customer Statement Report Total value
        Initialize;

        // Setup: Create Invoice and Payment General Line for Customer and Random Values.
        CreateCustomerAndPostGenJnlLines(Customer, InvoiceAmount);

        // Exercise: Save Customer Statement Report as XML
        RunStatementReport(Customer."No.");

        VerifyStatementEntriesTotal(-InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        PostedSalesShipmentPage: Page "Posted Sales Shipment";
        DocumentNo: Code[20];
    begin
        // Verify Document Entries for Sales Shipment with Tables and No of Records as per Navigate.

        // Setup: Create and Post Sales Shipment.
        Initialize;
        CreateAndPostSalesShipment(DocumentNo, CreateCustomer);
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesShipment.OpenView;
        PostedSalesShipment.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesShipment."&Navigate".Invoke;  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate.
        LibraryReportDataset.LoadDataSetFile;
        SalesShipmentHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesShipmentPage.Caption, SalesShipmentHeader.Count);
        VerifyItemLedgerWithValueEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesInvoiceWithLCY()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Verify Document Entries report for Sales Invoice with Tables and No of Records as per Navigate and option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesInvoice(SalesInvoiceHeader, true);

        // Verify: Verify Amount in LCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          InvPostingDtTxt, Format(
            SalesInvoiceHeader."Posting Date"), InvAmtTxt, SalesInvoiceHeader.Amount / SalesInvoiceHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesInvoiceWithFCY()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Verify Document Entries report for Sales Invoice Tables and No of Records as per Navigate and without option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesInvoice(SalesInvoiceHeader, false);

        // Verify: Verify Amount in FCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          InvPostingDtTxt, Format(SalesInvoiceHeader."Posting Date"), InvAmtTxt, SalesInvoiceHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesRetReceipt()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
        PostedReturnReceiptPage: Page "Posted Return Receipt";
        DocumentNo: Code[20];
    begin
        // Verify Document Entries for Sales Return Order with Tables and No of Records as per Navigate.

        // Setup: Create and Post Sales Return Order.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(SalesLine, CreateCustomer, SalesLine."Document Type"::"Return Order", '', false);  // Blank is used for Currency Code.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedReturnReceipt.OpenView;
        PostedReturnReceipt.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedReturnReceipt."&Navigate".Invoke;  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate.
        LibraryReportDataset.LoadDataSetFile;
        ReturnReceiptHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedReturnReceiptPage.Caption, ReturnReceiptHeader.Count);
        VerifyItemLedgerWithValueEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesCrMemoWithLCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Verify Document Entries report for Sales Cr. Memo with Tables and No of Records as per Navigate and option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesCrMemo(SalesCrMemoHeader, true);

        // Verify: Verify Amount in LCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(CrMemoPostingDtTxt, Format(SalesCrMemoHeader."Posting Date"),
          CrMemoAmtTxt, SalesCrMemoHeader.Amount / SalesCrMemoHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesReqPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForSalesCrMemoWithFCY()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Verify Document Entries report for Sales Cr. Memo Tables and No of Records as per Navigate and without option 'Show Amount in LCY'.

        // Setup and Excercise.
        DocumentEntriesForSalesCrMemo(SalesCrMemoHeader, false);

        // Verify: Verify Amount in FCY on Document Entries Report.
        VerifyAmtOnDocumentEntriesReport(
          CrMemoPostingDtTxt, Format(SalesCrMemoHeader."Posting Date"), CrMemoAmtTxt, SalesCrMemoHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecWithCurrencyCodeMatchesBlankAndLCY()
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify Aged Accounts Receivable report should consider the Amount when Currency Code is Blank and LCY with Print Amount LCY False.
        AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(true); // 1st currency code is blank, 2nd currency is LCY.
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountRecWithCurrencyCodeMatchesLCYAndBlank()
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // Verify Aged Accounts Receivable report should consider the Amount when Currency Code is LCY and Blank with Print Amount LCY False.
        AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(false); // 1st currency code is LCY, 2nd currency is blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCreditMemoWithEmptyShiptoInformation()
    var
        PostedCreditMemoDocNo: Code[20];
        FileName: Text[1024];
    begin
        // [SCENARIO 371670] "Standard Sales - Credit Memo" report prints document without ship-to informantion

        Initialize;
        // [GIVEN] Posted Credit Memo without ship-to information
        PostedCreditMemoDocNo := CreatePostCreditMemoWithoutShiptoInfo;

        // [WHEN] Run "Standard Sales - Credit Memo" report
        FileName := RunStandardSalesCreditMemo(PostedCreditMemoDocNo);

        // [THEN] File of report exists
        Assert.IsTrue(FileManagement.ServerFileExists(FileName), ReportStandardSalesCreditMemoErr);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UI_OpenReportWhenPressPrintOnPostedSalesCreditMemo()
    var
        ReportSelections: Record "Report Selections";
        SalesLine: Record "Sales Line";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        DocNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales Credit Memo] [Print]
        // [SCENARIO 376444] "Sales - Credit Memo" report should be opened when press "Print" on "Posted Sales Credit Memo" page

        // [GIVEN] Posted Sales Credit memo with "Document No." = "1000" opened on "Posted Sales Credit Memo Page"
        Initialize;
        DocNo :=
          CreateAndPostSalesDocument(SalesLine, CreateCustomer, SalesLine."Document Type"::"Credit Memo", '', true);
        UpdateReportSelection(ReportSelections.Usage::"S.Cr.Memo", REPORT::"Sales - Credit Memo");
        Commit;
        PostedSalesCreditMemo.OpenView;
        PostedSalesCreditMemo.FILTER.SetFilter("No.", DocNo);

        // [WHEN] Press "Print" on "Posted Sales Credit Memo" page
        PostedSalesCreditMemo.Print.Invoke;

        // [THEN] "Sales - Credit Memo" report is opened with "Document No." = 1000
        // If SalesCreditMemoRequestPageHandler called then test case is passed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange(SalesCrMemoNoTxt, DocNo);
        LibraryReportDataset.MoveToRow(2);
        LibraryReportDataset.AssertCurrentRowValueEquals(TotalAmtSalesCrMemoTxt, SalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('RHSalesDocumentTest,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportExchangeRate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ActualResult: Variant;
        SalesHeaderNo: Code[20];
        ExpectedResult: Decimal;
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [Sales Document - Test]
        // [SCENARIO 378473] Sales Document - Test report should show Exchange Rate from Sales header in section "VAT Amount Specification ..."
        Initialize;

        // [GIVEN] "General Ledger Setup"."Print VAT specification in LCY" = TRUE
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup."Print VAT specification in LCY" := true;
        GeneralLedgerSetup.Modify;

        // [GIVEN] Currency "C" with Exchange Rate = "X"
        CreateCurrencyWithExchRate(CurrencyExchangeRate);

        // [GIVEN] Sales Invoice with "Currency Code" = "C" and Exchange Rate = "Y"
        CreateSalesInvoiceWithCurrFactor(SalesHeaderNo, ExpectedResult, VATIdentifier, CurrencyExchangeRate);

        // [WHEN] Run "Sales Document - Test"
        SaveSalesDocumentTest(SalesHeaderNo, true, true, false, false);

        // [THEN] Exchange Rate = "Y"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange(VATIdentifierTok, VATIdentifier);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.GetElementValueInCurrentRow(VALExchRateTok, ActualResult);
        Assert.AreNotEqual(0, StrPos(ActualResult, Format(ExpectedResult)), WrongExchRateErr);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithGLobalDimension1Filter()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Global Dimension 1 Filter"
        Initialize;

        // [GIVEN] Posted Sales Invoice with Global Dimension 1 = "D1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Global Dimension 1 = "D2" where Amount = "A2"
        GLSetup.Get;
        CustomerNo := CreateCustomer;
        Customer.Get(CustomerNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GLSetup."Global Dimension 1 Code", DimensionNo[1]);
        Customer.Validate("Global Dimension 1 Code", DimensionNo[1]);
        Customer.Modify;
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, DimensionNo[1], '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, DimensionNo[2], '', '');

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Global Dimension 1 = "D2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, DimensionNo[2], '', '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, DimensionNo[2], '', '');
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithGLobalDimension2Filter()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        CustomerNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Global Dimension 2 Filter"
        Initialize;

        // [GIVEN] Posted Sales Invoice with Global Dimension 2 = "D1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Global Dimension 2 = "D2" where Amount = "A2"
        GLSetup.Get;
        CustomerNo := CreateCustomer;
        Customer.Get(CustomerNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GLSetup."Global Dimension 2 Code", DimensionNo[1]);
        Customer.Validate("Global Dimension 2 Code", DimensionNo[1]);
        Customer.Modify;
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', DimensionNo[1], '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', DimensionNo[2], '');

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Global Dimension 2 = "D2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, '', DimensionNo[2], '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, '', DimensionNo[2], '');
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckCustomerBalanceToDateWithCurrencyFilter()
    var
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 163061] Check Customer Balance To Date report with filter on Customer."Currency Filter"

        // [GIVEN] Posted Sales Invoice with Currency Code = "C1" where Amount = "A1"
        // [GIVEN] Posted Sales Invoice with Currency Code = "C2" where Amount = "A2"
        Initialize;
        CustomerNo := CreateCustomerWithCurrency;
        CurrencyCode := CreateCurrencyAndExchangeRate;
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo, '', '', CurrencyCode);

        // [WHEN] Save Customer - Balance To Date report with Limit Totals on Currency Code = "C2"
        RunCustomerBalanceToDateWithLimitTotal(CustomerNo, '', '', CurrencyCode);

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo, '', '', CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Customer Balance To Date for Entry where unapplication and then application are out of Ending Date
        Initialize;

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo, -LibraryRandom.RandDec(100, 2), WorkDate);

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate, WorkDate + 1, WorkDate + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate);

        // [THEN] Payment Entry of -150 is printed, 100 is not printed, Total Amount = -150
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateDoesNotExist(CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriodIncludeUnapplied()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Customer Balance To Date for closed Entry with zero balance inside period and application after Ending Date
        Initialize;

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo, -LibraryRandom.RandDec(100, 2), WorkDate);

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate, WorkDate + 1, WorkDate + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = Yes
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", true, WorkDate);

        // [THEN] Payment Entry of -150 is printed, 100 is printed with 0 balance, Total Amount = -150
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateTwoEntriesExist(
          CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount, CustLedgerEntry.Amount);
        // [THEN] Applied Entry (31.12.15) is printed. Initial TFSID 231621
        LibraryReportDataset.AssertElementWithValueExists('postDt_DtldCustLedgEntry', Format(WorkDate));
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryAppliedInPeriodUnappliedAppliedOutOfPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378848] Customer Balance To Date for unapplied entry inside period and application after Ending Date
        Initialize;

        // [GIVEN] Customer with payment of Amount = -150
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo, -LibraryRandom.RandDec(100, 2), WorkDate);

        // [GIVEN] Closed Customer Ledger Entry on 31.12.15 with Amount = 100
        // [GIVEN] Application dtld. cust. ledger entries of Amount = -100 applied on 31.12.15 and unapplied on 31.12.15
        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 01.01.16
        Amount := MockApplyUnapplyScenario(CustLedgerEntry."Customer No.", WorkDate, WorkDate, WorkDate + 1);

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate);

        // [THEN] Payment Entry of -150 is printed, 100 is printed, Total Amount = -50
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 231621
        VerifyCustomerBalanceToDateTwoEntriesExist(
          CustLedgerEntry."Customer No.", CustLedgerEntry.Amount, Amount, CustLedgerEntry.Amount + Amount);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateClosedEntryWithinPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PmtAmount: Decimal;
    begin
        // [SCENARIO 211599] Customer Balance To Date for closed Entry inside period
        Initialize;

        // [GIVEN] Customer with payment of Amount = -150
        PmtAmount := -LibraryRandom.RandDec(100, 2);
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo, PmtAmount, WorkDate);

        // [GIVEN] Closed Customer Ledger Entry on 30.12.15 with Amount = 100
        MockCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Customer No.", LibraryRandom.RandDec(100, 2), WorkDate - 1);

        // [GIVEN] Application dtld. cust. ledger entry with Amount = -100 on 31.12.15
        MockDtldCustLedgEntry(CustLedgerEntry."Customer No.", CustLedgerEntry."Entry No.", -CustLedgerEntry.Amount, false, WorkDate);
        UpdateOpenOnCustLedgerEntry(CustLedgerEntry."Entry No.");

        // [WHEN] Save Customer Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunCustomerBalanceToDateWithCustomer(CustLedgerEntry."Customer No.", false, WorkDate);

        // [THEN] Payment Entry of -150 is printed, 100 is not printed, Total Amount = -150
        VerifyCustomerBalanceToDateDoesNotExist(CustLedgerEntry."Customer No.", PmtAmount, CustLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInReminder()
    var
        Reminder: TestPage Reminder;
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When running the report "Customer Statement", the report specified in Report Selection should be opened
        Initialize;
        Commit;
        REPORT.Run(REPORT::"Customer Statement"); // Calls StatementCancelRequestPageHandler
        Reminder.OpenEdit;
        asserterror Reminder."Report Statement".Invoke; // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInSalesInvoiceList()
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When using "Statement" action on Sales Invoice List, the report specified in Report Selection should be opened
        Initialize;
        Commit;
        REPORT.Run(REPORT::"Customer Statement");
        SalesInvoiceList.OpenEdit;
        asserterror SalesInvoiceList."Report Statement".Invoke; // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('StatementCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReportSelectionForCustomerStatementInSalesCreditMemos()
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [UT] [Report Selection]
        // [SCENARIO 381714] When using "Statement" action on Sales Credit Memos, the report specified in Report Selection should be opened
        Initialize;
        Commit;
        REPORT.Run(REPORT::"Customer Statement");
        SalesCreditMemos.OpenEdit;
        asserterror SalesCreditMemos."Report Statement".Invoke; // Calls StatementCancelRequestPageHandler
        Assert.ExpectedError(RunReportNotSupportedErr);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableEmptyPeriodLength')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivablePeriodLengthError()
    var
        Customer: Record Customer;
        PeriodLength: DateFormula;
    begin
        // [FEATURE] [UT] [Aged Accounts Receivable]
        // [SCENARIO 202767] Aged Accounts Receivable report gives 'Enter a date formula in the Period Length field.' error when "Period Length" is empty
        Initialize;

        LibrarySales.CreateCustomer(Customer);
        Commit;
        asserterror SaveAgedAccountsReceivable(
            Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);
        Assert.ExpectedError(EnterDateFormulaErr);
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivableDefaultPeriodLength')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableDefaultPeriodLength()
    var
        Customer: Record Customer;
        PeriodLength: DateFormula;
        ExpectedPeriodLength: DateFormula;
    begin
        // [FEATURE] [UT] [Aged Accounts Receivable]
        // [SCENARIO 232335] Aged Accounts Receivable report has '<1M>' as default Period Length
        Initialize;

        Clear(PeriodLength);
        LibrarySales.CreateCustomer(Customer);
        Commit;
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);
        Evaluate(PeriodLength, LibraryVariableStorage.DequeueText);
        Evaluate(ExpectedPeriodLength, '<1M>');
        Assert.AreEqual(ExpectedPeriodLength, PeriodLength, 'Incorrect Period Length');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSalesListReportWithFilteredPostingDateWithNoData()
    var
        DummyVATEntry: Record "VAT Entry";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [EC Sales List]
        Initialize;
        CompanyInformation.Get;

        // [GIVEN] Report 130 "EC Sales List" request page
        // [GIVEN] Type filter for VAT Entry "Posting Date"  = "01-01-2120" (on a date with no data)
        // [WHEN] Run the report
        DummyVATEntry.SetRange("Posting Date", DMY2Date(1, 1, Date2DMY(WorkDate, 3) + 10), DMY2Date(31, 1, Date2DMY(WorkDate, 3) + 10));
        REPORT.SaveAsExcel(REPORT::"EC Sales List", LibraryReportValidation.GetFileName, DummyVATEntry);

        // [THEN] The report has been printed
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValueOnWorksheet(5, 5, CompanyInformation.Name, '1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPmtReceiptReportWithExternalDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ExternalDocNo: Code[35];
        Amount: Decimal;
    begin
        // [FEATURE] [Customer - Payment Receipt] [External Document No.]
        // [SCENARIO 210727] REP 211 "Customer - Payment Receipt" prints "External Document No." payment line with positive amount
        Initialize;

        // [GIVEN] Posted customer payment with "External Document No." = "X", Amount = "A"
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ExternalDocNo := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ExternalDocNo)), 1, MaxStrLen(ExternalDocNo));
        CreateAndPostGenJournalLines(GenJournalLine, Amount, -Amount, LibrarySales.CreateCustomerNo, ExternalDocNo);

        // [WHEN] Run REP 211 "Customer - Payment Receipt"
        DummyCustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        REPORT.SaveAsExcel(REPORT::"Customer - Payment Receipt", LibraryReportValidation.GetFileName, DummyCustLedgerEntry);

        // [THEN] Payment line has been printed with Description = "X", Amount = "A"
        LibraryReportValidation.OpenFile;
        LibraryReportValidation.VerifyCellValueByRef('K', 63, 1, ExternalDocNo);
        LibraryReportValidation.VerifyCellValueByRef('O', 63, 1, LibraryReportValidation.FormatDecimalValue(Amount));
    end;

    [Test]
    [HandlerFunctions('StatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatementBlanked()
    begin
        // [FEATURE] [Statement]
        // [SCENARIO 218263] REP 116 "Statement" doesn't show any error in case of empty output
        Initialize;

        // [GIVEN] Customer without any business data
        // [THEN] Run "Statement" report for the customer
        RunStatementReport(LibrarySales.CreateCustomerNo);

        // [WHEN] Report has been printed blanked
        // StatementRequestPageHandler
        LibraryReportDataset.LoadDataSetFile;
        Assert.AreEqual(0, LibraryReportDataset.RowCount, '');
    end;

    [Test]
    [HandlerFunctions('StandardStatementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardStatementBlanked()
    begin
        // [FEATURE] [Standard Statement]
        // [SCENARIO 218263] REP 1316 "Standard Statement" doesn't show any error in case of empty output
        Initialize;

        // [GIVEN] Customer without any business data
        // [THEN] Run "Standard Statement" report for the customer
        RunStandardStatementReport(LibrarySales.CreateCustomerNo);

        // [WHEN] Report has been printed blanked
        // StatementRequestPageHandler
        LibraryReportDataset.LoadDataSetFile;
        Assert.AreEqual(0, LibraryReportDataset.RowCount, '');
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableTimestampAndCompanyDisplayNameCalledOnce()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PeriodLength: DateFormula;
        I: Integer;
    begin
        // [FEATURE] [Performance] [Aged Accounts Receivable] [Date-Time] [Time Zone]
        // [SCENARIO 235531] TypeHelper.GetFormattedCurrentDateTimeInUserTimeZone and COMPANYPROPERTY.DISPLAYNAME are called once for Aged Accounts Receivable report when multiple entries are processed
        Initialize;

        // [GIVEN] Post 2 Sales Invoices
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        for I := 1 to 2 do
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNo, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Aged Accounts Receivable
        Customer.SetRecFilter;
        Evaluate(PeriodLength, '<1M>');
        CodeCoverageMgt.StartApplicationCoverage;
        SaveAgedAccountsReceivable(Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);
        CodeCoverageMgt.StopApplicationCoverage;

        // [THEN] COMPANYPROPERTY.DISPLAYNAME is called once
        VerifyAgedAccountsReceivableNoOfHitsCodeCoverage('COMPANYPROPERTY.DISPLAYNAME', 1);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateShowEntriesWithZeroBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer - Balance to Date]
        // [SCENARIO 275908] Report Customer - Balance to Date shows entries with zero balance when "Show Entries with Zero Balance" was enabled on request page
        Initialize;

        // [GIVEN] Posted Invoice Gen. Journal Line with Customer Account and Amount = -1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo, GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo,
          LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo Gen. Journal Line with Customer Account and Amount = 1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Account No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo,
          -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Stan ran report "Customer - Balance to Date" and enabled "Show Entries with Zero Balance" on request page
        RunCustomerBalanceToDateWithLimitTotal(GenJournalLine."Account No.", '', '', '');

        // [WHEN] Stan pushes OK on request page
        // Done in RHVendorBalanceToDateEnableShowEntriesWithZeroBalance

        // [THEN] Report shows formatted Invoice and Credit Memo entries for Customer
        // [THEN] Report shows formatted balance value = 0 for Customer
        VerifyCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine, 0);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportSaleRequestPageHandler,SaleAnalysisMatrixExcludeByShowReportPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportExcludesNoShowLinesAndColumns()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: array[2] of Record "Analysis Line";
        AnalysisColumn: array[2] of Record "Analysis Column";
    begin
        // [FEATURE] [Sales Analysis Report]
        // [SCENARIO 359346] Sales analysis matrix does not show lines with Show = "No" and columns with Show = "Never".
        Initialize;

        // [GIVEN] Sales analysis report.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);

        // [GIVEN] Analysis line "L1" is set up for Show = "No".
        CreateSalesAnalysisLineWithShowSetting(AnalysisLine[1], AnalysisLineTemplate.Name, AnalysisLine[1].Show::No);
        LibraryVariableStorage.Enqueue(AnalysisLine[1]);

        // [GIVEN] Analysis line "L2" is set up for Show = "Yes".
        CreateSalesAnalysisLineWithShowSetting(AnalysisLine[2], AnalysisLineTemplate.Name, AnalysisLine[2].Show::Yes);
        LibraryVariableStorage.Enqueue(AnalysisLine[2]);

        // [GIVEN] Analysis column "C1" is set up for Show = "Never".
        CreateSalesAnalysisColumnWithShowSetting(AnalysisColumn[1], AnalysisColumnTemplate.Name, AnalysisColumn[1].Show::Never);
        LibraryVariableStorage.Enqueue(AnalysisColumn[1]);

        // [GIVEN] Analysis column "C2" is set up for Show = "Always".
        CreateSalesAnalysisColumnWithShowSetting(AnalysisColumn[2], AnalysisColumnTemplate.Name, AnalysisColumn[2].Show::Always);
        LibraryVariableStorage.Enqueue(AnalysisColumn[2]);

        // [WHEN] Open Sales Analysis Matrix to view the report.
        OpenAnalysisReportSales(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Line "L1" is not shown, Line "L2" is visible.
        // [THEN] Column "C1" is not shown, Column "C2" is visible.
        // [THEN] The matrix has maximum of 32 columns, but only one column ("C2") is now visible.
        // The verification is done in SaleAnalysisMatrixExcludeByShowReportPageHandler handler.
    end;

    [Test]
    [HandlerFunctions('AnalysisReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportPrintoutFormattingCheck()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: array[5] of Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReport: Report "Analysis Report";
    begin
        // [FEATURE] [Analysis Report]
        // [SCENARIO 359346] Analysis report printout should respect analysis line format settings.
        Initialize;

        // [GIVEN] Sales analysis report with one column.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Sales, AnalysisColumnTemplate.Name);

        // [GIVEN] The report has five analysis lines with various formatting.
        // [GIVEN] Line 1 - normal font style, Line 2 - bold, Line 3 - italic, Line 4 - bold italic, Line 5 - bold and underlined.
        CreateAnalysisLine(AnalysisLine[1], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo, false, false, false);
        CreateAnalysisLine(AnalysisLine[2], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo, true, false, false);
        CreateAnalysisLine(AnalysisLine[3], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo, false, true, false);
        CreateAnalysisLine(AnalysisLine[4], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo, true, true, false);
        CreateAnalysisLine(AnalysisLine[5], AnalysisLineTemplate.Name, LibrarySales.CreateCustomerNo, true, false, true);

        // [WHEN] Run "Analysis Report".
        Commit;
        AnalysisReport.SetParams(
          AnalysisLine[1]."Analysis Area"::Sales, AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);
        AnalysisReport.SetFilters(Format(WorkDate), '', '', '', '', '', 0, '');
        AnalysisReport.Run;

        // [THEN] Each line is printed only once and has its own format.
        LibraryReportDataset.LoadDataSetFile;
        VerifyRowFormatInAnalysisReport(AnalysisLine[1], true, false, false, false, false); // normal
        VerifyRowFormatInAnalysisReport(AnalysisLine[2], false, true, false, false, false); // bold
        VerifyRowFormatInAnalysisReport(AnalysisLine[3], false, false, true, false, false); // italic
        VerifyRowFormatInAnalysisReport(AnalysisLine[4], false, false, false, true, false); // bold italic
        VerifyRowFormatInAnalysisReport(AnalysisLine[5], false, true, false, false, true); // bold + underlined
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFilterAsTextInAnalysisReportToExcel()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ExportAnalysisRepToExcel: Report "Export Analysis Rep. to Excel";
        DateFilter: Text;
    begin
        // [FEATURE] [Analysis Report]
        // [SCENARIO 359346] When "Date Filter" set on analysis line is not a single date, but a date period, it should be printed as text on the filter section in "Analysis Report to Excel" worksheet.
        Initialize;

        // [GIVEN] Sales analysis report with one line and one column.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Sales, AnalysisColumnTemplate.Name);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Sales, AnalysisLineTemplate.Name);

        // [GIVEN] Set "Date Filter" = '01/01/20..31/12/20' on the analysis line.
        DateFilter := StrSubstNo('%1..%2', CalcDate('<-CY>', WorkDate), CalcDate('<CY>', WorkDate));
        AnalysisLine.SetFilter("Date Filter", DateFilter);

        // [WHEN] Export the analysis report to Excel.
        ExportAnalysisRepToExcel.SetOptions(AnalysisLine, AnalysisColumnTemplate.Name, AnalysisLineTemplate.Name);
        ExportAnalysisRepToExcel.SetFileNameSilent(LibraryReportValidation.GetFileName);
        ExportAnalysisRepToExcel.SetTestMode(true);
        ExportAnalysisRepToExcel.Run;

        // [THEN] Date Filter = '01/01/20..31/12/20' is printed on the filter section on Excel worksheet.
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValueOnWorksheet(2, 2, DateFilter, '1');
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReportConsidersGlobalDimensionFiltersWhenReportOpenLedgEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        PeriodLength: DateFormula;
        i: Integer;
    begin
        // [FEATURE] [Aged Accounts Receivable] [Dimension]
        // [SCENARIO 284398] Aged Account Receivable Report considers global dimension filters

        Initialize;

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Two posted invoices
        // [GIVEN] Invoice "A" with Amount = 100, "Global Dimension 1 Code" = "X1", "Global Dimension 2 Code" = "X2"
        // [GIVEN] Invoice "B" with Amount = 200, "Global Dimension 1 Code" = "X2", "Global Dimension 2 Code" = "Y2"
        for i := 1 to 2 do
            PostInvoiceWithDimensions(GenJournalLine, Customer."No.");
        PrepareAgedAccReceivableReportForDimRun(
          Customer, PeriodLength, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

        // [WHEN] Run Aged Account Receivable Report with "Global Dimension 1 Filter" = "X2" and "Global Dimension 2 Filter" = "Y2"
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Total amount in exported XML file of report is 200
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('PostAndApplyCustPageHandler,PostApplicationPageHandler,MessageHandler,RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure AgedAccReceivableReportConsidersGlobalDimensionFiltersWhenReportClosedLedgEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        AgingBy: Option "Due Date","Posting Date","Document Date";
        PeriodLength: DateFormula;
        i: Integer;
    begin
        // [FEATURE] [Aged Accounts Receivable] [Dimension]
        // [SCENARIO 284398] Aged Account Receivable Report considers global dimension filters

        Initialize;

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Two posted invoices fully applied by payments
        // [GIVEN] Invoice "A" with Amount = 100, "Global Dimension 1 Code" = "X1", "Global Dimension 2 Code" = "X2"
        // [GIVEN] Invoice "B" with Amount = 200, "Global Dimension 1 Code" = "X2", "Global Dimension 2 Code" = "Y2"
        for i := 1 to 2 do begin
            PostInvoiceWithDimensions(GenJournalLine, Customer."No.");
            PostApplyPaymentWithDimensions(
              GenJournalLine, Customer."No.", GenJournalLine."Posting Date" + 1, -GenJournalLine.Amount,
              GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
        end;
        PrepareAgedAccReceivableReportForDimRun(
          Customer, PeriodLength, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
        Commit;

        // [WHEN] Run Aged Account Receivable Report with "Global Dimension 1 Filter" = "X2" and "Global Dimension 2 Filter" = "Y2"
        SaveAgedAccountsReceivable(
          Customer, AgingBy::"Posting Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // [THEN] Total amount in exported XML file of report is 200
        VerifyXMLReport('No_Cust', Customer."No.", 'TotalCLE1Amt', -GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateRemainingAmount()
    var
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        // [FEATURE] [Customer - Balance to Date]
        // [SCENARIO 288122] Remaining Amount in "Customer - Balance to Date" report shows sum of invoice that is closed at a later date.
        Initialize;

        // [GIVEN] Invoice Gen. Jnl. Line with Amount 'X', Payment Gen. Jnl. Line with Amount 'Y', Payment Gen. Jnl. Line with Amount -'X'-'Y'
        LibrarySales.CreateCustomer(Customer);
        with GenJournalLine[1] do begin
            CreateGenJournalLine(
              GenJournalLine[1], WorkDate, Customer."No.",
              "Document Type"::Invoice, "Document Type"::" ", '', LibraryRandom.RandIntInRange(500, 1000));
            LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

            CreateGenJournalLine(
              GenJournalLine[2], WorkDate + 1, Customer."No.",
              "Document Type"::Payment, "Document Type"::Invoice, "Document No.", LibraryRandom.RandIntInRange(-499, -1));
            LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

            CreateGenJournalLine(
              GenJournalLine[3], WorkDate + 2, Customer."No.",
              "Document Type"::Payment, "Document Type"::Invoice, "Document No.", -Amount - GenJournalLine[2].Amount);
            LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);
        end;

        // [WHEN] "Customer - Balance to Date" report is run
        Customer.SetRecFilter;
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, false, WorkDate + 1);
        Commit;
        CustomerBalanceToDate.Run;

        // [THEN] RemainingAmt is equal to 'X' + 'Y'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('RemainingAmt', GenJournalLine[1].Amount + GenJournalLine[2].Amount);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure PrintProFormaInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Pro Forma Invoive] [UI] [Order]
        // [SCENARIO 201636] Print REP 1302 "Standard Sales - Pro Forma Inv" from Sales Order page
        Initialize;
        UpdateGLSetupDefaultUnitAmountRounding;
        UpdateCompanyInfo;
        LibraryERM.SetLCYCode(LibraryUtility.GenerateGUID);

        // [GIVEN] Sales Order card
        CreateSalesOrderWithSevItemsForProForma(SalesHeader);

        // [WHEN] Invoke "Proforma Invoice" action
        RunStandardSalesProformaInvFromOrderPage(SalesHeader);

        // [THEN] REP 1302 "Standard Sales - Pro Forma Inv" has been printed
        // [THEN] Document line with zero Quantity has been printed (TFS 225721)
        VerifyProformaInvoiceBaseValues(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure ProFormaCurrencyAmountDecimals2Digits()
    var
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Pro Forma Invoive]
        // [SCENARIO 290824] REP 1302 "Standard Sales - Pro Forma Inv" in case of currency
        // [SCENARIO 290824] with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 2:5,
        // [SCENARIO 290824] "Amount Rounding Precision" = 0.01, "Amount Decimal Places" = 2:2

        // [GIVEN] Currency with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 2:5, "Amount Rounding Precision" = 0.01, "Amount Decimal Places" = 2:2
        CurrencyCode := CreateCurrencyWithDecimalPlaces(0.01, '2:5', 0.00001, '5:5');

        // [GIVEN] FCY Sales Invoice with "Unit Price" = 1000.11111, "Quantity" = 5, "VAT %" = 12 (vat amount = 600.06667)
        PrepareCustomFCYSalesInvoiceForProForma(SalesLine, CurrencyCode);

        // [WHEN] Print "Pro Forma Invoice" report
        RunStandardSalesProFormaInv(SalesLine."Document No.");

        // [THEN] Printed line values: "Quantity" = 5, "Unit Price" = 1000.112, "VAT Amount" = 600.07, "Amount" = 5000.56
        // [THEN] Printed total values: "TotalValue" = 5000.56, "TotalVATAmount" = 600.07, "TotalAmountInclVAT" = 5600.63
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', 5);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(1000.112, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(5000.56, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(600.07, 2));
        Assert.IsTrue(LibraryReportDataset.GetNextRow, Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(5000.56, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(600.07, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(5600.63, 2));
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure ProFormaCurrencyAmountDecimals5Digits()
    var
        SalesLine: Record "Sales Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Pro Forma Invoive]
        // [SCENARIO 290824] REP 1302 "Standard Sales - Pro Forma Inv" in case of currency
        // [SCENARIO 290824] with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 5:5,
        // [SCENARIO 290824] "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5:5

        // [GIVEN] Currency with "Unit-Amount Rounding Precision" = 0.00001,  Unit-Amount Decimal Places = 5:5, "Amount Rounding Precision" = 0.00001, "Amount Decimal Places" = 5:5
        CurrencyCode := CreateCurrencyWithDecimalPlaces(0.00001, '5:5', 0.00001, '5:5');

        // [GIVEN] FCY Sales Invoice with "Unit Price" = 1000.11111, "Quantity" = 5, "VAT %" = 12 (vat amount = 600.06667)
        PrepareCustomFCYSalesInvoiceForProForma(SalesLine, CurrencyCode);

        // [WHEN] Print "Pro Forma Invoice" report
        RunStandardSalesProFormaInv(SalesLine."Document No.");

        // [THEN] Printed line values: "Quantity" = 5, "Unit Price" = 1000.11111, "VAT Amount" = 600.06667, "Amount" = 5000.55555
        // [THEN] Printed total values: "TotalValue" = 5000.55555, "TotalVATAmount" = 600.06667, "TotalAmountInclVAT" = 5600.62222
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', SalesLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', 5);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(1000.11111, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(5000.55555, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(600.06667, 5));
        Assert.IsTrue(LibraryReportDataset.GetNextRow, Rep1302DatasetErr);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(5000.55555, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(600.06667, 5));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(5600.62222, 5));
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableReportRequestPageHandler')]
    procedure AgedAccReceivableCustomerPhoneNoAndContact()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Aged Accounts Receivable]
        // [SCENARIO 290824] Aged Accounts Receivable report prints customer phone number and contact when Print Details = "Yes"
        Initialize;

        // [GIVEN] Customer "CUST" with Phone No. = "12345", Contact = "CONT"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Phone No.",
          CopyStr(
            LibraryUtility.GenerateRandomNumericText(MaxStrLen(Customer."Phone No.")),
            1,
            MaxStrLen(Customer."Phone No.")));
        Customer.Validate(Contact,
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Contact),0),
            1,
            MaxStrLen(Customer.Contact)));
        Customer.Modify;

        // [GIVEN] Create and post invoice for Customer "CUST", "Posting Date" = "01.01.2019" and "Due Date" = "01.02.2019"
        CreatePostSalesInvoiceWithDueDateCalc(Customer."No.",CalcDate('<1M>',WorkDate));

        // [WHEN] Run report Aged Accounts Receivable with "Print Details" = "Yes"
        RunAgedAccountsReceivableWithParameters(Customer,CalcDate('<2M>',WorkDate));

        // [THEN] Customer "CUST" is printed with Phone No. = "12345", Contact = "CONT"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Name1_Cust',Customer."No.");
        LibraryReportDataset.AssertElementWithValueExists('CustomerPhoneNo',Customer."Phone No.");
        LibraryReportDataset.AssertElementWithValueExists('CustomerContactName',Customer.Contact);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Report III");
        Clear(LibraryReportDataset);
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Report III");

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdatePrepaymentAccounts;
        LibraryERMCountryData.UpdateFAPostingGroup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Report III");
    end;

    local procedure AgedAccountRecFalsePrintAmtLCYAndCurrencyCodeMatchesLCY(FirstBlank: Boolean)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
        PeriodLength: DateFormula;
    begin
        // Setup: Create Currency and update LCY Code in GL Setup.
        Initialize;
        CreateLCYAndUpdateGeneralLedgerSetup(CurrencyCode);

        // Create and Post 2 Sales Orders.
        CustomerNo := CreateCustomer;
        if FirstBlank then begin
            CurrencyCode1 := '';
            CurrencyCode2 := CurrencyCode;
        end else begin
            CurrencyCode1 := CurrencyCode;
            CurrencyCode2 := '';
        end;
        CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::Order, CurrencyCode1, true);
        CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::Order, CurrencyCode2, true);

        // Exercise: Run and save Aged Account Receivable Report with Print Amount LCY = False.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.Get(CustomerNo);
        Customer.SetRecFilter;
        SaveAgedAccountsReceivable(Customer, AgingBy::"Due Date", HeadingType::"Date Interval", PeriodLength, false, false);

        // Verify: Verify the Balance in the report.
        Customer.CalcFields(Balance);
        VerifyXMLReport('No_Cust', CustomerNo, 'TotalCLE1Amt', Customer.Balance);
    end;

    local procedure SetupAgedAccountsReceivable(var SalesLine: Record "Sales Line"; var PostedDocNo: Code[20]; var PeriodLength: DateFormula; AgingBy: Integer; HeadingType: Option; PrintAmountLCY: Boolean; PrintDetails: Boolean; CurrencyCode: Code[10]) VATAmount: Decimal
    var
        Customer: Record Customer;
    begin
        // Setup: Create and Post Sales Order and Find Customer Ledger Entry Amount.
        PostedDocNo := CreateAndPostSalesDocument(SalesLine, CreateCustomer, SalesLine."Document Type"::Order, CurrencyCode, true);
        VATAmount := Round(SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100));

        // Exercise: Take Period Length with Random Values.
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetRange("No.", SalesLine."Sell-to Customer No.");
        SaveAgedAccountsReceivable(Customer, AgingBy, HeadingType, PeriodLength, PrintAmountLCY, PrintDetails);
    end;

    local procedure PrepareCustomFCYSalesInvoiceForProForma(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    begin
        CreateFCYSalesInvoiceWithVATSetup(SalesLine, CurrencyCode, 12, 5, 1000.11111);
        Assert.IsTrue(SalesLine.Amount mod 10000 <> 0, '');
        Assert.IsTrue(SalesLine."Amount Including VAT" mod 10000 <> 0, '');
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; PaymentAmount: Decimal; AccountNo: Code[20]; ExtDocNoForPmtLine: Code[35]) PmtDiscAmount: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, AccountNo, InvoiceAmount);
        PmtDiscAmount := -GenJournalLine.Amount * GenJournalLine."Payment Discount %" / 100;  // Calculate Payment Discount Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", PaymentAmount + PmtDiscAmount);
        if ExtDocNoForPmtLine <> '' then begin
            GenJournalLine.Validate("External Document No.", ExtDocNoForPmtLine);
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesShipment(var PostedShipmentNo: Code[20]; CustomerNo: Code[20]) Quantity: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, CustomerNo, '');
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Quantity := SalesLine.Quantity;
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesOrderWithSevItemsForProForma(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: array[3] of Record Item;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithDetails);

        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID);
        SalesHeader.Modify(true);

        for i := 1 to ArrayLen(Item) do begin
            CreateItemWithDetails(Item[i]);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, Item[i]."No.", LibraryRandom.RandDecInRange(10, 20, 2));
            SalesLine.Validate("Qty. to Invoice", Round(SalesLine.Quantity / 3));
            SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 30));
            SalesLine.Modify(true);
        end;

        // Leave last line with zero quantity (TFS 225721)
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
    end;

    local procedure CreateFCYSalesInvoiceWithVATSetup(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; VATRate: Decimal; Quantity: Decimal; UnitPrice: Decimal)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), Quantity, '', 0D, CurrencyCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify;
    end;

    local procedure PostAndSaveSalesCreditMemo(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; InternalInfo: Boolean; LogEntry: Boolean) DocumentNo: Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: Report "Sales - Credit Memo";
    begin
        // Setup.
        DocumentNo := CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::"Credit Memo", '', true);

        // Exercise: Save Blanket Sales Order Report.
        Clear(SalesCreditMemo);
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        SalesCreditMemo.SetTableView(SalesCrMemoHeader);
        SalesCreditMemo.InitializeRequest(0, InternalInfo, LogEntry);
        Commit;
        SalesCreditMemo.Run;
    end;

    local procedure SetupSalesDocumentTest(var SalesLine: Record "Sales Line"; Ship: Boolean; Invoice: Boolean)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '');
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);

        // Exercise.
        SaveSalesDocumentTest(SalesLine."Document No.", Ship, Invoice, false, false);
    end;

    local procedure CreateGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Integer; AccountType: Integer; AccountNo: Code[20]; BalAccountType: Integer; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Create Customer with Application Method Apply to Oldest and attach Payment Terms to it.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer);
        Customer.Validate("Currency Code", CreateCurrencyAndExchangeRate);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerAndPostGenJnlLines(var Customer: Record Customer; var InvoiceAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -(InvoiceAmount * 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Option; CurrencyCode: Code[10]; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, CustomerNo, CurrencyCode);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    [Scope('OnPrem')]
    procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; CustomerNo: Code[20]; DocumentType: Option; AppliesToDocType: Option; AppliesToDocNo: Code[20]; Amount: Integer)
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCustomerWithDimension(var DimensionValue: Record "Dimension Value") CustomerNo: Code[20]
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        CustomerNo := CreateCustomer;
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateCustomerWithDetails(): Code[20]
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        with Customer do begin
            "VAT Registration No." := LibraryUtility.GenerateGUID;
            Validate("Shipment Method Code", CreateShipmentMethod);
            Validate("Country/Region Code", CreateCountryRegion);
            Validate("Salesperson Code", SalespersonPurchaser.Code);
            Validate("Post Code", LibraryUtility.GenerateGUID);
            Validate(City, LibraryUtility.GenerateGUID);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Take Random Values for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostSalesInvoiceWithDueDateCalc(CustomerNo: Code[20];DueDate: Date): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,CustomerNo);
        SalesHeader.Validate("Due Date",DueDate);
        SalesHeader.Modify;
        LibrarySales.CreateSalesLine(
          SalesLine,SalesHeader,SalesLine.Type::Item,LibraryInventory.CreateItemNo,LibraryRandom.RandDec(10,2));
        SalesLine.Validate("Unit Price",LibraryRandom.RandDec(100,2));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader,true,true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
    end;

    local procedure CreateLCYAndUpdateGeneralLedgerSetup(var CurrencyCode: Code[10])
    begin
        CurrencyCode := CreateCurrencyAndExchangeRate;
        UpdateCurrencyExchangeRate(CurrencyCode, 1, 1); // Update Exchange Rate to 1:1 since this is a Local Currency.
        UpdateGeneralLedgerSetupForLCYCode(CurrencyCode);
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
    end;

    local procedure CreateAndModifySalesLine(SalesHeader: Record "Sales Header"; Type: Option; AccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, AccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithCurrFactor(var SalesHeaderNo: Code[20]; var ExpectedResult: Decimal; var VATIdentifier: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesHeader.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        SalesHeader.Validate("Currency Factor",
          CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" +
          LibraryRandom.RandDec(100, 2));
        SalesHeader.Modify(true);
        SalesHeaderNo := SalesHeader."No.";
        ExpectedResult := Round(CurrencyExchangeRate."Exchange Rate Amount" / SalesHeader."Currency Factor", 0.000001);
        VATIdentifier := SalesLine."VAT Identifier";
    end;

    local procedure CreateResource(var Resource: Record Resource; VATBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResource(Resource, VATBusPostingGroup);
        Resource.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Resource.Modify(true);
    end;

    local procedure CreateSalesOrderWithDifferentLineType(var SalesHeader: Record "Sales Header"): Decimal
    var
        ItemCharge: Record "Item Charge";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // Find VAT Posting setup, G/L Account, Resource and Charge Item.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateGLAccount(GLAccount, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateResource(
          Resource, VATPostingSetup."VAT Bus. Posting Group",
          GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateItemCharge(ItemCharge, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // Create Sales Order with Prepayment % with different line type.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::Item, Item."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::Resource, Resource."No.");
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"Fixed Asset", FindFixedAsset);
        CreateAndModifySalesLine(SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.");
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreatePostCreditMemoWithoutShiptoInfo(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo",
          LibrarySales.CreateCustomerNo, CreateCurrencyAndExchangeRate);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        ClearShiptoInfoForSalesHeader(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrencyWithExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates;
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst;
    end;

    local procedure CreateCurrencyWithDecimalPlaces(AmountRoundingPrecision: Decimal; AmountDecimalPlaces: Text[5]; UnitAmountRoundingPrecision: Decimal; UnitAmountDecimalPlaces: Text[5]): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        with Currency do begin
            "Amount Rounding Precision" := AmountRoundingPrecision;
            "Amount Decimal Places" := AmountDecimalPlaces;
            "Unit-Amount Rounding Precision" := UnitAmountRoundingPrecision;
            "Unit-Amount Decimal Places" := UnitAmountDecimalPlaces;
            Modify;
            exit(Code);
        end;
    end;

    local procedure CreateAnalysisLine(var AnalysisLine: Record "Analysis Line"; AnalysisLineTemplateName: Code[10]; CustomerNo: Code[20]; IsBold: Boolean; IsItalic: Boolean; IsUnderlined: Boolean)
    begin
        with AnalysisLine do begin
            LibraryInventory.CreateAnalysisLine(AnalysisLine, "Analysis Area"::Sales, AnalysisLineTemplateName);
            Validate("Row Ref. No.", LibraryUtility.GenerateGUID);
            Validate(Type, Type::Customer);
            Validate(Range, CustomerNo);
            Validate(Bold, IsBold);
            Validate(Italic, IsItalic);
            Validate(Underline, IsUnderlined);
            Modify(true);
        end;
    end;

    local procedure CreateSalesAnalysisLineWithShowSetting(var AnalysisLine: Record "Analysis Line"; AnalysisLineTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Sales, AnalysisLineTemplateName);
        AnalysisLine.Validate(Show, ShowSetting);
        AnalysisLine.Modify(true);
    end;

    local procedure CreateSalesAnalysisColumnWithShowSetting(var AnalysisColumn: Record "Analysis Column"; AnalysisColumnTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Sales, AnalysisColumnTemplateName);
        AnalysisColumn.Validate("Column Header", LibraryUtility.GenerateGUID);
        AnalysisColumn.Validate(Show, ShowSetting);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateItemWithDetails(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Country/Region of Origin Code", CreateCountryRegion);
            Validate("Net Weight", LibraryRandom.RandDecInRange(1000, 2000, 2));
            Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
            Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
            Modify(true);
        end;
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        with ShipmentMethod do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Shipment Method");
            Description := LibraryUtility.GenerateGUID;
            Insert(true);
            exit(Code);
        end;
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure ClearShiptoInfoForSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            Validate("Ship-to Name", '');
            Validate("Ship-to Address", '');
            Validate("Ship-to Address 2", '');
            Validate("Ship-to City", '');
            Validate("Ship-to Contact", '');
            Validate("Location Code", '');
            Validate("Shipment Date", 0D);
            Validate("Ship-to Post Code", '');
            Validate("Ship-to Country/Region Code", '');
            Modify(true);
        end;
    end;

    local procedure DocumentEntriesForSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; ShowInLCY: Boolean)
    var
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedSalesInvoicePage: Page "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Order.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, CreateCustomer, SalesLine."Document Type"::Order, CreateCurrencyAndExchangeRate, true);
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesInvoice.OpenView;
        PostedSalesInvoice.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesInvoice."&Navigate".Invoke;  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate and Amount with and without LCY.
        LibraryReportDataset.LoadDataSetFile;
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesInvoicePage.Caption, SalesInvoiceHeader.Count);
        VerifyLedgerOnDocumentEntries(DocumentNo);
        SalesInvoiceHeader.FindFirst;
        SalesInvoiceHeader.CalcFields(Amount);
    end;

    local procedure DocumentEntriesForSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowInLCY: Boolean)
    var
        SalesLine: Record "Sales Line";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        PostedSalesCreditMemoPage: Page "Posted Sales Credit Memo";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Credit Memo.
        Initialize;
        DocumentNo := CreateAndPostSalesDocument(
            SalesLine, CreateCustomer, SalesLine."Document Type"::"Credit Memo", CreateCurrencyAndExchangeRate, true);
        LibraryVariableStorage.Enqueue(ShowInLCY);  // Enqueue for DocumentEntriesReqPageHandler.
        PostedSalesCreditMemo.OpenView;
        PostedSalesCreditMemo.FILTER.SetFilter("No.", DocumentNo);

        // Exercise.
        PostedSalesCreditMemo."&Navigate".Invoke;  // Navigate.

        // Verify: Verify Tables and No of Records as per Navigate and Amount with and without LCY.
        LibraryReportDataset.LoadDataSetFile;
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntries(PostedSalesCreditMemoPage.Caption, SalesCrMemoHeader.Count);
        VerifyLedgerOnDocumentEntries(DocumentNo);
        SalesCrMemoHeader.FindFirst;
        SalesCrMemoHeader.CalcFields(Amount);
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.FindFirst;
        exit(FixedAsset."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindSet;
        end;
    end;

    local procedure ApplyCustLedgerEntry(DocumentType: Option; CustomerNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView;
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries."Apply Entries".Invoke;
    end;

    local procedure MockApplyUnapplyScenario(CustomerNo: Code[20]; ApplnDate1: Date; UnapplDate: Date; ApplnDate2: Date) Amount: Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        MockCustLedgerEntry(CustLedgerEntry, CustomerNo, Amount, WorkDate);
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", -Amount, true, ApplnDate1);
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", Amount, true, UnapplDate);
        MockDtldCustLedgEntry(CustomerNo, CustLedgerEntry."Entry No.", -Amount, false, ApplnDate2);
        UpdateOpenOnCustLedgerEntry(CustLedgerEntry."Entry No.");
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    begin
        with CustLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            "Customer No." := CustomerNo;
            "Posting Date" := PostingDate;
            Amount := EntryAmount;
            Open := true;
            Insert;
            MockInitialDtldCustLedgEntry(CustomerNo, "Entry No.", EntryAmount, PostingDate);
        end;
    end;

    local procedure MockInitialDtldCustLedgEntry(CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDtldCLE(
          DetailedCustLedgEntry,
          CustomerNo, CustLedgEntryNo, DetailedCustLedgEntry."Entry Type"::"Initial Entry", EntryAmount, false, PostingDate);
    end;

    local procedure MockDtldCustLedgEntry(CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockDtldCLE(
          DetailedCustLedgEntry,
          CustomerNo, CustLedgEntryNo, DetailedCustLedgEntry."Entry Type"::Application, EntryAmount, UnappliedEntry, PostingDate);
    end;

    local procedure MockDtldCLE(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; CustLedgEntryNo: Integer; EntryType: Option; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    begin
        with DetailedCustLedgEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Customer No." := CustomerNo;
            "Entry Type" := EntryType;
            "Posting Date" := PostingDate;
            "Cust. Ledger Entry No." := CustLedgEntryNo;
            Amount := EntryAmount;
            Unapplied := UnappliedEntry;
            Insert;
        end;
    end;

    local procedure OpenAnalysisReportSales(AnalysisReportName: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportSale: TestPage "Analysis Report Sale";
    begin
        AnalysisReportSale.OpenEdit;
        AnalysisReportSale.FILTER.SetFilter(Name, AnalysisReportName);
        AnalysisReportSale."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportSale."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportSale.EditAnalysisReport.Invoke;
    end;

    local procedure SaveAgedAccountsReceivable(var Customer: Record Customer; AgingBy: Option; HeadingType: Option; PeriodLength: DateFormula; AmountLCY: Boolean; PrintDetails: Boolean)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
    begin
        Clear(AgedAccountsReceivable);
        AgedAccountsReceivable.SetTableView(Customer);
        AgedAccountsReceivable.InitializeRequest(WorkDate, AgingBy, PeriodLength, AmountLCY, PrintDetails, HeadingType, false);
        AgedAccountsReceivable.Run;
    end;

    local procedure SaveBlanketSalesOrder(No: Code[20]; InternalInfo: Boolean)
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: Report "Blanket Sales Order";
    begin
        Clear(BlanketSalesOrder);
        SalesHeader.SetRange("No.", No);
        BlanketSalesOrder.SetTableView(SalesHeader);
        BlanketSalesOrder.InitializeRequest(0, InternalInfo, false, false);
        Commit;
        BlanketSalesOrder.Run;
    end;

    local procedure SaveCustomerBalanceToDate(No: Code[20]; AmountInLCY: Boolean; UnappliedEntries: Boolean)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", No);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(AmountInLCY, false, UnappliedEntries, WorkDate);  // Setting False for New Page Per Customer Option.
        Commit;
        CustomerBalanceToDate.Run;
    end;

    local procedure SaveSalesDocumentTest(No: Code[20]; Ship: Boolean; Invoice: Boolean; ShowDimension: Boolean; ShowItemCharge: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesDocumentTest: Report "Sales Document - Test";
    begin
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("No.", No);
        SalesDocumentTest.SetTableView(SalesHeader);
        SalesDocumentTest.InitializeRequest(Ship, Invoice, ShowDimension, ShowItemCharge);
        Commit;
        SalesDocumentTest.Run;
    end;

    local procedure RunAgedAccountsReceivableWithParameters(Customer: Record Customer;AgedAsOfDate: Date)
    var
        AgedAccountsReceivable: Report "Aged Accounts Receivable";
    begin
        Clear(AgedAccountsReceivable);
        LibraryVariableStorage.Enqueue(AgedAsOfDate);

        Customer.SetRecFilter;
        AgedAccountsReceivable.SetTableView(Customer);
        AgedAccountsReceivable.Run;
    end;

    local procedure RunSalesCreditMemoTestReport(DocNo: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit;
        SalesCreditMemo.FILTER.SetFilter("No.", DocNo);
        SalesCreditMemo.TestReport.Invoke;
    end;

    local procedure RunStandardSalesCreditMemo(CreditMemoDocNo: Code[20]) FileName: Text[1024]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        StandardSalesCreditMemo: Report "Standard Sales - Credit Memo";
    begin
        SalesCrMemoHeader.Get(CreditMemoDocNo);
        SalesCrMemoHeader.SetFilter("No.", '%1', CreditMemoDocNo);
        StandardSalesCreditMemo.SetTableView(SalesCrMemoHeader);
        StandardSalesCreditMemo.InitializeRequest(true, true);
        FileName := LibraryReportDataset.GetFileName;
        StandardSalesCreditMemo.SaveAsPdf(FileName);
    end;

    local procedure RunStatementReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Commit;
        REPORT.Run(REPORT::Statement, true, false, Customer);
    end;

    local procedure RunStandardStatementReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Commit;
        REPORT.Run(REPORT::"Standard Statement", true, false, Customer);
    end;

    local procedure SaveSalesShipmentReport(No: Code[20]; ShowInternalInformation: Boolean; LogInteraction: Boolean; ShowCorrectionLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipment: Report "Sales - Shipment";
    begin
        Clear(SalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        SalesShipment.SetTableView(SalesShipmentHeader);

        // Passing 0 for No. of Copies and TRUE for Show Serial/ Lot No. Appendix option as these options can not be checked.
        SalesShipment.InitializeRequest(0, ShowInternalInformation, LogInteraction, ShowCorrectionLines, true, false);
        Commit;
        SalesShipment.Run;
    end;

    local procedure SaveReturnOrderReport(No: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReturnOrderConfirmation: Report "Return Order Confirmation";
    begin
        Clear(ReturnOrderConfirmation);
        SalesHeader.SetRange("No.", No);
        ReturnOrderConfirmation.SetTableView(SalesHeader);
        ReturnOrderConfirmation.InitializeRequest(ShowInternalInfo, LogInteraction);
        Commit;
        ReturnOrderConfirmation.Run;
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupInvoiceDiscount(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Required Random Value for "Discount %" fields and 0 for Minimum Amount.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer, '', 0);
        CustInvoiceDisc.Validate("Discount %", 1 + LibraryRandom.RandDec(10, 1)); // Minimum Discount %1 should be 1.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure SetupSalesAndReceivablesSetup(CreditMemoNos: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Credit Memo Nos.", CreditMemoNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetupCalcInvDisc(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCurrencyExchangeRate(CurrencyCode: Code[10]; ExchangeRateAmt: Decimal; AdjmtExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        with CurrencyExchangeRate do begin
            SetRange("Currency Code", CurrencyCode);
            FindFirst;
            Validate("Exchange Rate Amount", ExchangeRateAmt);
            Validate("Relational Exch. Rate Amount", AdjmtExchRateAmt);
            Validate("Adjustment Exch. Rate Amount", ExchangeRateAmt);
            Validate("Relational Adjmt Exch Rate Amt", AdjmtExchRateAmt);
            Modify(true);
        end;
    end;

    local procedure UpdateGeneralLedgerSetupForLCYCode(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            Validate("LCY Code", CurrencyCode);
            Modify(true);
        end;
    end;

    local procedure UpdateReportSelection(Usage: Option; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, Usage);
        ReportSelections.DeleteAll;
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert;
    end;

    local procedure UpdateOpenOnCustLedgerEntry(EntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgerEntry do begin
            Get(EntryNo);
            CalcFields(Amount);
            Open := Amount <> 0;
            Modify;
        end;
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPrepaymentsAccount := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Validate(Name, LibraryUtility.GenerateGUID);
            Validate("Name 2", LibraryUtility.GenerateGUID);
            Validate(Address, LibraryUtility.GenerateGUID);
            Validate("Address 2", LibraryUtility.GenerateGUID);
            Validate("Post Code", LibraryUtility.GenerateGUID);
            Validate(City, LibraryUtility.GenerateGUID);
            Validate("E-Mail", LibraryUtility.GenerateGUID + '@' + LibraryUtility.GenerateGUID);
            Validate("Home Page", LibraryUtility.GenerateGUID);
            Validate("Phone No.", LibraryUtility.GenerateGUID);
            "VAT Registration No." := LibraryUtility.GenerateGUID;
            Modify(true);
        end;
    end;

    local procedure UpdateGLSetupDefaultUnitAmountRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            "Unit-Amount Rounding Precision" := 0.00001;
            "Unit-Amount Decimal Places" := '2:5';
            Modify;
        end;
    end;

    local procedure CreateCustomerAndPostGenJnlLinesWithFilters(CustomerNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDimension1Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", GlobalDimension2Code);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCustomerBalanceToDateWithLimitTotal(CustomerNo: Code[20]; GlobalDimension1Filter: Text; GlobalDimension2Filter: Text; CurrencyFilter: Text)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Global Dimension 1 Filter", GlobalDimension1Filter);
        Customer.SetRange("Global Dimension 2 Filter", GlobalDimension2Filter);
        Customer.SetRange("Currency Filter", CurrencyFilter);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, false, WorkDate);
        Commit;
        CustomerBalanceToDate.Run;
    end;

    local procedure RunCustomerBalanceToDateWithCustomer(CustomerNo: Code[20]; Unapplied: Boolean; ReportDate: Date)
    var
        Customer: Record Customer;
        CustomerBalanceToDate: Report "Customer - Balance to Date";
    begin
        Commit;
        Clear(CustomerBalanceToDate);
        Customer.SetRange("No.", CustomerNo);
        CustomerBalanceToDate.SetTableView(Customer);
        CustomerBalanceToDate.InitializeRequest(false, false, Unapplied, ReportDate);
        CustomerBalanceToDate.Run;
    end;

    local procedure RunStandardSalesProformaInvFromOrderPage(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Commit;
        SalesOrder.Trap;
        PAGE.Run(PAGE::"Sales Order", SalesHeader);
        SalesOrder.ProformaInvoice.Invoke;
        SalesOrder.Close;
    end;

    local procedure RunStandardSalesProFormaInv(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("No.", DocumentNo);
        Commit;
        REPORT.Run(REPORT::"Standard Sales - Pro Forma Inv", true, false, SalesHeader);
    end;

    local procedure PostInvoiceWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get;
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandIntInRange(1000, 2000));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostApplyPaymentWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustNo: Code[20]; PostingDate: Date; Amount: Decimal; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", ShortcutDimension2Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Account No.");
    end;

    local procedure PrepareAgedAccReceivableReportForDimRun(var Customer: Record Customer; var PeriodLength: DateFormula; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    begin
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Customer.SetFilter("Global Dimension 1 Filter", ShortcutDimension1Code);
        Customer.SetFilter("Global Dimension 2 Filter", ShortcutDimension2Code);
        Customer.SetRecFilter;
    end;

    local procedure FormatDecimal(Value: Decimal; Decimals: Integer): Text
    begin
        exit(
          Format(Value, 0, StrSubstNo('<Sign><Integer Thousand><1000Character,,><Decimals,%1><Comma,.><Filler Character,0>', Decimals + 1)));
    end;

    local procedure VerifyAgedAccountsRecReport(PostedDocNo: Code[20]; SellToCustNo: Code[20]; Total: Decimal; VATAmount: Decimal; TotalLCY: Decimal; VATAmountLCY: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Cust', SellToCustNo);
        LibraryReportDataset.SetRange('CLEEndDateDocNo', PostedDocNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('CLEEndDate', Total);
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE1TempRemAmt', VATAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CLEEndDateAmtLCY', TotalLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('AgedCLE1RemAmtLCY', VATAmountLCY);
    end;

    local procedure VerifyInternalInformation(DimensionValueRec: Record "Dimension Value"; Separator: Text[3])
    begin
        LibraryReportDataset.AssertElementWithValueExists('DimText',
          StrSubstNo(HeaderDimensionTxt, DimensionValueRec."Dimension Code", Separator, DimensionValueRec.Code));
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Option; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(InteractionLogEntry.IsEmpty, StrSubstNo(RecordErr, InteractionLogEntry.TableCaption));
    end;

    local procedure VerifyUndoneQuantityInReport(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange(Correction, true);
        SalesShipmentLine.FindLast;
        LibraryReportDataset.SetRange('LineNo_SalesShptLine', SalesShipmentLine."Line No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', SalesShipmentLine.Quantity);
    end;

    local procedure VerifyInvoiceDiscountInReport(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.SetRange('Sales_Line__Type', Format(SalesLine.Type));
        LibraryReportDataset.GetNextRow;

        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line__Quantity', SalesLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Qty__to_Invoice_', SalesLine."Qty. to Invoice");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Unit_Price_', SalesLine."Unit Price");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Line_Amount_', SalesLine."Line Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___No__', SalesLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Allow_Invoice_Disc__', SalesLine."Allow Invoice Disc.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___VAT_Identifier_', SalesLine."VAT Identifier");

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('Sales_Line___Line_Discount___', SalesLine."Line Discount %");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line___Inv__Discount_Amount_', SalesLine."Inv. Discount Amount");
    end;

    local procedure VerifyCustBalanceToDateWithLCY(CustLedgerEntry: Record "Cust. Ledger Entry"; InvAmountLCY: Decimal; PmtAmountLCY: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.SetRange('DocType_DtldCustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('EntryNo_CustLedgEntry', CustLedgerEntry."Entry No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', InvAmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', PmtAmountLCY);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);

        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff2', Round(InvAmountLCY + PmtAmountLCY));
    end;

    local procedure VerifyCustomerBalanceToDate(GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; PmtDiscAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.SetRange('EntType_DtldCustLedgEnt', Format(DetailedCustLedgEntry."Entry Type"::"Payment Discount"));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', Round(PmtDiscAmount));

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('EntType_DtldCustLedgEnt', Format(DetailedCustLedgEntry."Entry Type"::Application));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', InvoiceAmount);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'TtlAmtCurrencyTtlBuff2', Round(InvoiceAmount + PmtDiscAmount + GenJournalLine.Amount))
    end;

    local procedure VerifyCustomerPaymentReceipt(DocumentNo: Code[20]; PmtDiscAmount: Decimal; Amount: Decimal; PaymentAmount: Decimal)
    var
        ReportAmount: Decimal;
    begin
        // Convert Amount in two decimal places using FORMAT to verify it in Report.
        Evaluate(ReportAmount, Format(PmtDiscAmount, 0, '<Precision,2><Standard Format,1>'));
        LibraryReportDataset.SetRange('DocumentNo_CustLedgEntry', DocumentNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('ShowAmount', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PmtDiscInvCurr', ReportAmount);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('ExtDocNo_CustLedgEntry', DocumentNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt_CustLedgEntry', PaymentAmount);
    end;

    local procedure VerifyUnappliedEntries(GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal; EntryNo: Integer)
    begin
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', InvoiceAmount);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('EntryNo_CustLedgEntry', EntryNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', GenJournalLine.Amount);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('DocType_DtldCustLedgEntry', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', GenJournalLine.Amount);

        LibraryReportDataset.Reset;
        LibraryReportDataset.SetRange('TotalCaption', TotalCapTxt);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff2', Round(InvoiceAmount + GenJournalLine.Amount));
    end;

    local procedure VerifyVATEntries(VATIdentifierLabel: Text[50]; VATPercLabel: Text[50]; VATBaseLabel: Text[50]; LineAmountLabel: Text[50]; InvDiscBaseAmountLabel: Text[50])
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        VATAmountLine.SetFilter("VAT %", '>0');
        VATAmountLine.FindFirst;
        LibraryReportDataset.SetRange(VATIdentifierLabel, VATAmountLine."VAT Identifier");
        LibraryReportDataset.GetNextRow;

        LibraryReportDataset.AssertCurrentRowValueEquals(VATPercLabel, VATAmountLine."VAT %");
        LibraryReportDataset.AssertCurrentRowValueEquals(VATBaseLabel, VATAmountLine."VAT Base");
        LibraryReportDataset.AssertCurrentRowValueEquals(LineAmountLabel, VATAmountLine."Line Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals(InvDiscBaseAmountLabel, VATAmountLine."Inv. Disc. Base Amount");
    end;

    local procedure VerifyDocumentEntries(DocEntryTableName: Text[50]; RowValue: Decimal)
    begin
        LibraryReportDataset.SetRange(DocEntryTableNameTxt, DocEntryTableName);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals(DocEntryNoofRecordsTxt, RowValue)
    end;

    local procedure VerifySalesDocumentTestSalesLine(SalesLine: Record "Sales Line")
    begin
        // Verify: Verify Report Data.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Sales_Line___No__', SalesLine."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Line__Quantity', SalesLine.Quantity);
    end;

    local procedure VerifyItemLedgerWithValueEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(ItemLedgerEntry.TableCaption, ItemLedgerEntry.Count);
        VerifyValueEntry(DocumentNo);
    end;

    local procedure VerifyLedgerOnDocumentEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        VATEntry: Record "VAT Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(GLEntry.TableCaption, GLEntry.Count);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(CustLedgerEntry.TableCaption, CustLedgerEntry.Count);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(DetailedCustLedgEntry.TableCaption, DetailedCustLedgEntry.Count);
        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(VATEntry.TableCaption, VATEntry.Count);
        VerifyValueEntry(DocumentNo);
    end;

    local procedure VerifyAmtOnDocumentEntriesReport(PostingDateCaptionElement: Text[50]; PostingDateCaption: Text[50]; AmtCaptionElement: Text[50]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(PostingDateCaptionElement, PostingDateCaption);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals(AmtCaptionElement, Amount);
    end;

    local procedure VerifySalesDocumentTestReport()
    var
        SalesLine: Record "Sales Line";
    begin
        VerifyWarningOnReportCell(Format(SalesLine.Type::Item));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"G/L Account"));
        VerifyWarningOnReportCell(Format(SalesLine.Type::Resource));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"Fixed Asset"));
        VerifyWarningOnReportCell(Format(SalesLine.Type::"Charge (Item)"));
    end;

    local procedure VerifyWarningOnReportCell(SalesLineType: Text[30])
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryReportDataset.SetRange('Sales_Line__Type', SalesLineType);
        LibraryReportDataset.SetRange('ErrorText_Number__Control97Caption', WarningTxt);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('ErrorText_Number__Control97',
          StrSubstNo(PrepaymentPostErr, SalesLine.FieldCaption("Prepmt. Line Amount")));
    end;

    local procedure VerifyDataOnSalesDocumentTestReport(VATAmount: Decimal; VATPercent: Decimal; Amount: Decimal)
    begin
        // Validate Line Amount and VAT Amount in the report.
        LibraryReportDataset.SetRange('VATAmountLine__VAT___', Format(VATPercent));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__Line_Amount_', -Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__VAT_Amount_', Round(-VATAmount));
    end;

    local procedure VerifyStatementEntriesTotal(TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;

        // filter the Total row
        LibraryReportDataset.SetRange('EntriesExists', EntriesExistTxt);
        LibraryReportDataset.SetRange('Total_Caption', TotalTxt);

        if LibraryReportDataset.GetNextRow then
            LibraryReportDataset.AssertCurrentRowValueEquals(CustBalanceCustLedgEntryTxt, TotalAmount);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntries(ValueEntry.TableCaption, ValueEntry.Count);
    end;

    local procedure VerifyXMLReport(XmlElementCaption: Text; XmlValue: Text; ValidateCaption: Text; ValidateValue: Decimal)
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            SetRange(XmlElementCaption, XmlValue);
            GetLastRow;
            AssertCurrentRowValueEquals(ValidateCaption, ValidateValue);
        end;
    end;

    local procedure VerifyCustomerBalanceToDateWithLimitTotal(CustomerNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile;
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Global Dimension 1 Code", GlobalDimension1Code);
        CustLedgerEntry.SetRange("Global Dimension 2 Code", GlobalDimension2Code);
        CustLedgerEntry.SetRange("Currency Code", CurrencyCode);
        CustLedgerEntry.FindFirst;
        CustLedgerEntry.CalcFields(Amount);

        LibraryReportDataset.SetRange('PostingDt_CustLedgEntry', Format(WorkDate));
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', CustLedgerEntry.Amount);
    end;

    local procedure VerifyCustomerEntriesAndBalanceInCustomerBalanceToDate(GenJournalLine: Record "Gen. Journal Line"; Balance: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', -GenJournalLine.Amount);
        LibraryReportDataset.SetRange('DocType_CustLedgEntry', Format(GenJournalLine."Document Type"::"Credit Memo"));
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', GenJournalLine.Amount);
        LibraryReportDataset.SetRange('CustName', GenJournalLine."Account No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('TtlAmtCurrencyTtlBuff', Balance);
    end;

    local procedure VerifyCustomerBalanceToDateTwoEntriesExist(CustomerNo: Code[20]; PmtAmount: Decimal; Amount: Decimal; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', PmtAmount);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Amount);
        LibraryReportDataset.AssertElementWithValueExists('TtlAmtCurrencyTtlBuff', TotalAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('postDt_DtldCustLedgEntry', Format(WorkDate + 1));
    end;

    local procedure VerifyCustomerBalanceToDateDoesNotExist(CustomerNo: Code[20]; PmtAmount: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', PmtAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('OriginalAmt', Amount);
        LibraryReportDataset.AssertElementWithValueExists('TtlAmtCurrencyTtlBuff', PmtAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('postDt_DtldCustLedgEntry', Format(WorkDate + 1));
    end;

    local procedure VerifyRowFormatInAnalysisReport(AnalysisLine: Record "Analysis Line"; Normal: Boolean; Bold: Boolean; Italic: Boolean; BoldItalic: Boolean; Underlined: Boolean)
    begin
        LibraryReportDataset.SetRange('RowRefNo_AnlysLine', AnalysisLine."Row Ref. No.");
        Assert.AreEqual(1, LibraryReportDataset.RowCount, RowPrintedMultiplyErr);

        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Body4View_AnlysLine', Normal);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body5View_AnlysLine', Bold);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body6View_AnlysLine', Italic);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body7View_AnlysLine', BoldItalic);
        LibraryReportDataset.AssertCurrentRowValueEquals('Body8View_AnlysLine', Underlined);
    end;

    local procedure VerifyAgedAccountsReceivableNoOfHitsCodeCoverage(CodeLine: Text; NoOfHits: Integer)
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Assert.AreEqual(
          NoOfHits,
          CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Report, REPORT::"Aged Accounts Receivable", CodeLine),
          StrSubstNo('%1 must be called %2 times when Aged Accounts Receivable is run', CodeLine, NoOfHits));
    end;

    local procedure VerifyProformaInvoiceBaseValues(SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ShipmentMethod: Record "Shipment Method";
        SalesLine: Record "Sales Line";
        FormatDocument: Codeunit "Format Document";
        TotalWeight: Decimal;
        TotalAmount: Decimal;
        TotalVATAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLbl: Text[50];
        TotalAmountInclVATLbl: Text[50];
        TotalAmounExclVATLbl: Text[50];
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetNextRow;
        CompanyInformation.Get;

        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentTitleLbl', 'Pro Forma Invoice');

        // Header - Company Information
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentDate', Format(SalesHeader."Document Date", 0, 4));
        with CompanyInformation do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyEMail', "E-Mail");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyHomePage', "Home Page");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyPhoneNo', "Phone No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyVATRegNo', "VAT Registration No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress1', Name);
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress2', "Name 2");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress3', Address);
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress4', "Address 2");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress5', "Post Code" + ' ' + City);
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyAddress6', '');
        end;

        // Header - Customer Information
        Customer.Get(SalesHeader."Sell-to Customer No.");
        CountryRegion.Get(Customer."Country/Region Code");
        with Customer do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress1', "No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress2', Address);
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress3', "Address 2");
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress4', City + ', ' + "Post Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress5', CountryRegion.Name);
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress6', '');
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress7', '');
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerAddress8', '');
        end;

        // Header - Document Information
        ShipmentMethod.Get(Customer."Shipment Method Code");
        with SalesHeader do begin
            LibraryReportDataset.AssertCurrentRowValueEquals('YourReference', "Your Reference");
            LibraryReportDataset.AssertCurrentRowValueEquals('ExternalDocumentNo', "External Document No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('DocumentNo', "No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CompanyLegalOffice', CompanyInformation.GetLegalOffice);
            LibraryReportDataset.AssertCurrentRowValueEquals('SalesPersonName', "Salesperson Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('ShipmentMethodDescription', ShipmentMethod.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('Currency', LibraryERM.GetLCYCode);
            LibraryReportDataset.AssertCurrentRowValueEquals('CustomerVATRegNo', Customer."VAT Registration No.");
        end;

        // Labels
        FormatDocument.SetTotalLabels(LibraryERM.GetLCYCode, TotalAmountLbl, TotalAmountInclVATLbl, TotalAmounExclVATLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountLbl', TotalAmountLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVATLbl', TotalAmountInclVATLbl);
        LibraryReportDataset.AssertCurrentRowValueEquals('DeclartionLbl', 'For customs purposes only.');
        LibraryReportDataset.AssertCurrentRowValueEquals('SignatureLbl', 'For and on behalf of the above named company:');
        LibraryReportDataset.AssertCurrentRowValueEquals('SignatureNameLbl', 'Name (in print) Signature');

        // Lines: 1-2 with Quantity, 3 - zero quantity
        with SalesLine do begin
            SetRange("Document Type", "Document Type"::Order);
            SetRange("Document No.", SalesHeader."No.");
            FindSet;
            VerifyProformaInvoiceLineValues(SalesLine, TotalWeight, TotalAmount, TotalVATAmount, TotalAmountInclVAT);
            Next;
            VerifyProformaInvoiceLineValues(SalesLine, TotalWeight, TotalAmount, TotalVATAmount, TotalAmountInclVAT);
            Next;
            VerifyProformaInvoiceZeroQtyLineValues(SalesLine);
        end;

        // Totals
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalWeight', TotalWeight);
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalValue', FormatDecimal(TotalAmount, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalVATAmount', FormatDecimal(TotalVATAmount, 2));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmountInclVAT', FormatDecimal(TotalAmountInclVAT, 2));
    end;

    local procedure VerifyProformaInvoiceLineValues(SalesLine: Record "Sales Line"; var TotalWeight: Decimal; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var TotalAmountInclVAT: Decimal)
    var
        Item: Record Item;
        LineAmount: Decimal;
        VATAmount: Decimal;
    begin
        with SalesLine do begin
            Item.Get("No.");
            LineAmount := Round(Amount * "Qty. to Invoice" / Quantity);
            VATAmount := Round(("Amount Including VAT" - Amount) * "Qty. to Invoice" / Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', "No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CountryOfManufacturing', Item."Country/Region of Origin Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('Tariff', Item."Tariff No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', "Qty. to Invoice");
            LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal(Round(Amount / Quantity, 0.00001), 5));
            LibraryReportDataset.AssertCurrentRowValueEquals('NetWeight', Item."Net Weight");
            LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(LineAmount, 2));
            LibraryReportDataset.AssertCurrentRowValueEquals('VATPct', "VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(VATAmount, 2));

            TotalWeight += Round("Net Weight" * "Qty. to Invoice");
            TotalAmount += LineAmount;
            TotalVATAmount += VATAmount;
            TotalAmountInclVAT += Round("Amount Including VAT" * "Qty. to Invoice" / Quantity);

            Assert.IsTrue(LibraryReportDataset.GetNextRow, Rep1302DatasetErr);
        end;
    end;

    local procedure VerifyProformaInvoiceZeroQtyLineValues(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        with SalesLine do begin
            Item.Get("No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('ItemDescription', "No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('CountryOfManufacturing', Item."Country/Region of Origin Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('Tariff', Item."Tariff No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', "Qty. to Invoice");
            LibraryReportDataset.AssertCurrentRowValueEquals('Price', FormatDecimal("Unit Price", 2));
            LibraryReportDataset.AssertCurrentRowValueEquals('NetWeight', Item."Net Weight");
            LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount', FormatDecimal(0, 2));
            LibraryReportDataset.AssertCurrentRowValueEquals('VATPct', "VAT %");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATAmount', FormatDecimal(0, 2));

            Assert.IsTrue(LibraryReportDataset.GetNextRow, 'wrong rep 1302 Pro Forma Invoice dataset');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesReqPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        CurrecnyInLcy: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrecnyInLcy);
        DocumentEntries.PrintAmountsInLCY.SetValue(CurrecnyInLcy);  // Boolean Show Amount in LCY
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.Print.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndApplyCustPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries."Post Application".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: Page "Post Application"; var Response: Action)
    begin
        // Modal Page Handler.
        Response := ACTION::OK
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivable(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivableEmptyPeriodLength(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        AgedAccountsReceivable.PeriodLength.SetValue('');
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivableDefaultPeriodLength(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    begin
        LibraryVariableStorage.Enqueue(AgedAccountsReceivable.PeriodLength.Value);
        AgedAccountsReceivable.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBlanketSalesOrder(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerBalanceToDate(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalanceToDate.ShowEntriesWithZeroBalance.SetValue(false);
        CustomerBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerBalanceToDateEnableShowEntriesWithZeroBalance(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalanceToDate.ShowEntriesWithZeroBalance.SetValue(true);
        CustomerBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerPaymentReceipt(var CustomerPaymentReceipt: TestRequestPage "Customer - Payment Receipt")
    begin
        CustomerPaymentReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHReturnOrderConfirmation(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesCreditMemo(var SalesCreditMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesDocumentTest(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesShipment(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementRequestPageHandler(var StatementRequestPage: TestRequestPage Statement)
    begin
        StatementRequestPage."Start Date".SetValue(WorkDate);
        StatementRequestPage."End Date".SetValue(WorkDate);
        StatementRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UndoShipmentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm handler for Undo Shipment Confirmation Message. Send Reply YES.
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementCancelRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardStatementRequestPageHandler(var StandardStatement: TestRequestPage "Standard Statement")
    begin
        StandardStatement."Start Date".SetValue(WorkDate);
        StandardStatement."End Date".SetValue(WorkDate);
        StandardStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisReportRequestPageHandler(var AnalysisReport: TestRequestPage "Analysis Report")
    begin
        AnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportSaleRequestPageHandler(var SalesAnalysisReport: TestPage "Sales Analysis Report")
    var
        SalesPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        SalesAnalysisReport.PeriodType.SetValue(SalesPeriodType::Year);
        SalesAnalysisReport.ShowMatrix.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SaleAnalysisMatrixExcludeByShowReportPageHandler(var SalesAnalysisMatrix: TestPage "Sales Analysis Matrix")
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        RecordVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, SalesAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, SalesAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = SalesAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = SalesAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        Assert.IsFalse(SalesAnalysisMatrix.Field2.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field3.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field4.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field5.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field6.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field7.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field8.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field9.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field10.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field11.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field12.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field13.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field14.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field15.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field16.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field17.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field18.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field19.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field20.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field21.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field22.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field23.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field24.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field25.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field26.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field27.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field28.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field29.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field30.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field31.Visible, ColumnDoesNotExistErr);
        Assert.IsFalse(SalesAnalysisMatrix.Field32.Visible, ColumnDoesNotExistErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableReportRequestPageHandler(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        RefAgingBy: Option "Due Date","Posting Date","Document Date";
    begin
        AgedAccountsReceivable.Agingby.SetValue(RefAgingBy::"Due Date");
        AgedAccountsReceivable.AgedAsOf.SetValue(LibraryVariableStorage.DequeueDate);
        AgedAccountsReceivable.PrintDetails.SetValue(true);
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName,LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProFormaInvoiceXML_RPH(var ProFormaInvoice: TestRequestPage "Standard Sales - Pro Forma Inv")
    begin
        ProFormaInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

