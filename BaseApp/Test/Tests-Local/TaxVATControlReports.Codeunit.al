codeunit 144205 "Tax VAT Control Reports"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTax: Codeunit "Library - Tax";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVATCtrlRptStat: Codeunit "Library - VAT Ctrl. Rpt. Stat.";
        LibraryXMLRead: Codeunit "Library - XML Read";
        IsInitialized: Boolean;
        FileNotExistErr: Label 'Exported file does not exist.';
        VATRateCanNotBeEmptyErr: Label 'VAT Rate must not be   in VAT Posting Setup: VAT Bus. Posting Group=%1, VAT Prod. Posting Group=%2';

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportSales1()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Suggest a Posted Sales Invoice with VAT Posting Setup "21S" and amount above limit of 10 thousand to VAT Control Report Lines
        SuggestingVATControlReportSales(true, VATPostingSetup."VAT Rate"::Base, 21, 0, 'A4', 'A4');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportSales2()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Suggest a Posted Sales Invoice with VAT Posting Setup "15S" and amount below limit of 10 thousand to VAT Control Report Lines
        SuggestingVATControlReportSales(false, VATPostingSetup."VAT Rate"::Reduced, 15, 0, 'A4', 'A5');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportSales3()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Suggest a Posted Sales Invoice with VAT Posting Setup "P44" and amount above limit of 10 thousand to VAT Control Report Lines
        SuggestingVATControlReportSales(false, VATPostingSetup."VAT Rate"::Base, 21, 1, 'A4', 'A4');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportSales4()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Suggest a Posted Sales Invoice with VAT Posting Setup "15S" which does not have filled VAT Rate
        SuggestingVATControlReportSales(true, VATPostingSetup."VAT Rate"::" ", 15, 0, 'A4', 'A5');
    end;

    local procedure SuggestingVATControlReportSales(IsDocumentAboveLimit: Boolean; VATRate: Option; VATPct: Decimal; CorrectionsForBadReceivable: Option; VATControlRepSectionCode: Code[20]; ExpectedVATControlRepSectionCode: Code[20])
    var
        SalesHdr: Record "Sales Header";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        PostedDocumentNo: Code[20];
    begin
        Initialize;
        LibraryTax.SetUseVATDate(true);

        // [GIVEN] Create VAT Posting Setup
        // [GIVEN] Create VAT Statement Line
        CreateVATStatementWithVATPostingSetup(VATStatementLine, VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate, VATPct, CorrectionsForBadReceivable, 0, 2, VATControlRepSectionCode);

        // [GIVEN] Create and Post Sales Invoice with amount above or below limit 10 thousand
        if IsDocumentAboveLimit then
            CreateSalesInvoiceAboveLimit(SalesHdr, VATPostingSetup)
        else
            CreateSalesInvoiceBelowLimit(SalesHdr, VATPostingSetup);
        PostedDocumentNo := PostSalesDocument(SalesHdr);

        // [GIVEN] Create VAT Control Report Header at period of VAT Date from Sales Invoice
        CreateVATControlReport(
          VATCtrlRptHdr, Date2DMY(SalesHdr."VAT Date", 2), Date2DMY(SalesHdr."VAT Date", 3),
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        if VATRate = 0 then begin
            // [WHEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Sales Invoice
            // which does not have filled VAT Rate in the VAT Posting Setup
            asserterror SuggestVATControlReportLines(VATCtrlRptHdr);

            // [THEN] Error Occurs
            Assert.ExpectedError(
              StrSubstNo(
                VATRateCanNotBeEmptyErr, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        end else begin
            // [WHEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Sales Invoice
            SuggestVATControlReportLines(VATCtrlRptHdr);

            // [THEN] VAT Entry which are created from Posted Sales Invoice is suggested to VAT Control Report
            VerifyVATControlReportWithSalesInvoice(
              VATCtrlRptHdr."No.", PostedDocumentNo, ExpectedVATControlRepSectionCode, VATRate, CorrectionsForBadReceivable, '');
        end;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler,ExportVATControlReportHandler')]
    [Scope('OnPrem')]
    procedure ExportingVATControlReportSales()
    var
        SalesHdr: Record "Sales Header";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        ClientFilePath: Text;
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] VAT Control Report is exporting to file

        Initialize;
        LibraryTax.SetUseVATDate(true);

        // [GIVEN] Use VAT Control Report Section A5 "Domestic sales below 10 thousand" and A4 "Domestic sales above 10 thousand"
        // [GIVEN] Create VAT Posting Setup with VAT Prod. Posting Group "Various 21%"
        // [GIVEN] Create VAT Statement Line with VAT Prod. Posting Group "Various 21%" and VAT Control Report Section A4
        CreateVATStatementWithVATPostingSetup(VATStatementLine, VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Rate"::Base, 21, 0, 0, 2, 'A4');

        // [GIVEN] Create and Post Sales Invoice with amount above limit 10 000
        CreateSalesInvoiceAboveLimit(SalesHdr, VATPostingSetup);
        PostedDocumentNo := PostSalesDocument(SalesHdr);

        // [GIVEN] Create VAT Control Report Header at period of VAT Date from Sales Invoice
        CreateVATControlReport(
          VATCtrlRptHdr, Date2DMY(SalesHdr."VAT Date", 2), Date2DMY(SalesHdr."VAT Date", 3),
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        // [GIVEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Sales Invoice
        SuggestVATControlReportLines(VATCtrlRptHdr);

        // [GIVEN] Release VAT Control Report
        ReleaseVATControlReport(VATCtrlRptHdr);

        // [WHEN] Export VAT Control Report is execute
        ClientFilePath := ExportVATControlReport(VATCtrlRptHdr);

        // [THEN] Exported File is exists and contains the node "VetaA4" with Document No. of Posted Sales Invoice
        // Assert.IsTrue(ClientFileExists(ClientFilePath), FileNotExistErr);
        // LibraryXMLRead.Initialize(ClientFilePath);
        // LibraryXMLRead.VerifyAttributeValueInSubtree('DPHKH1', 'VetaA4', 'c_evid_dd', PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportPurchase1()
    var
        Commodity: Record Commodity;
        PurchHdr: Record "Purchase Header";
        TariffNumber: Record "Tariff Number";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Suggest a Posted Purchase Invoice with VAT Posting Setup "PDP21" to VAT Control Report Lines

        Initialize;
        LibraryTax.SetUseVATDate(true);

        // [GIVEN] Create VAT Posting Setup
        // [GIVEN] Create VAT Statement Line
        CreateVATStatementWithVATPostingSetup(VATStatementLine, VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", VATPostingSetup."VAT Rate"::Base, 21, 0,
          VATPostingSetup."Reverse Charge Check"::"Limit Check & Export", 1, 'B1');

        // [GIVEN] Create Commodity with Commodity Setup
        // [GIVEN] Create Tariff Number with Allow Empty Unit of Meas.Code
        CreateCommodityWithTariffNumber(Commodity, TariffNumber, 0);

        // [GIVEN] Create and Post Purchase Invoice with amount
        CreatePurchInvoiceBelowLimit(PurchHdr, VATPostingSetup, TariffNumber."No.");
        PostedDocumentNo := PostPurchDocument(PurchHdr);

        // [GIVEN] Create VAT Control Report Header at period of VAT Date from Purchase Invoice
        CreateVATControlReport(
          VATCtrlRptHdr, Date2DMY(PurchHdr."VAT Date", 2), Date2DMY(PurchHdr."VAT Date", 3),
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        // [WHEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Purchase Invoice
        SuggestVATControlReportLines(VATCtrlRptHdr);

        // [THEN] VAT Entry which are created from Posted Purchase Invoice is suggested to VAT Control Report
        VerifyVATControlReportWithPurchInvoice(
          VATCtrlRptHdr."No.", PostedDocumentNo, 'B1', VATCtrlRptLn."VAT Rate"::Base, 0, Commodity.Code);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportPurchase2()
    var
        PurchHdr: Record "Purchase Header";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Suggest a Posted Purchase Invoice with different Posting Date, VAT Date and
        // Original Document VAT Date" to VAT Control Report Lines

        Initialize;
        LibraryTax.SetUseVATDate(true);

        // [GIVEN] Create VAT Posting Setup
        // [GIVEN] Create VAT Statement Line
        CreateVATStatementWithVATPostingSetup(VATStatementLine, VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Rate"::Base, 21, 0,
          VATPostingSetup."Reverse Charge Check"::" ", 1, 'B2');

        // [GIVEN] Create and Post Purchase Invoice with amount
        CreatePurchInvoiceAboveLimit(PurchHdr, VATPostingSetup, '');
        PurchHdr.Validate("Posting Date", CalcDate('<CM-1M>', PurchHdr."VAT Date"));
        PurchHdr.Validate("VAT Date", WorkDate);
        PurchHdr.Validate("Original Document VAT Date", CalcDate('<-CM-2M>', PurchHdr."VAT Date"));
        PurchHdr.Modify(true);

        PostedDocumentNo := PostPurchDocument(PurchHdr);

        // [GIVEN] Create VAT Control Report Header at period of VAT Date from Purchase Invoice
        CreateVATControlReport(
          VATCtrlRptHdr, Date2DMY(PurchHdr."VAT Date", 2), Date2DMY(PurchHdr."VAT Date", 3),
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        // [WHEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Purchase Invoice
        SuggestVATControlReportLines(VATCtrlRptHdr);

        // [THEN] VAT Entries which are created from Posted Purchase Invoice are suggested to VAT Control Report
        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        VATCtrlRptLn.SetRange("Document No.", PostedDocumentNo);
        VATCtrlRptLn.SetRange("VAT Control Rep. Section Code", 'B2');
        VATCtrlRptLn.SetRange("VAT Rate", VATPostingSetup."VAT Rate"::Base);
        VATCtrlRptLn.SetRange("Corrections for Bad Receivable", VATCtrlRptLn."Corrections for Bad Receivable"::" ");
        VATCtrlRptLn.SetRange("Commodity Code", '');
        Assert.RecordIsNotEmpty(VATCtrlRptLn);

        VATCtrlRptLn.FindFirst;
        VATCtrlRptLn.TestField("VAT Date", PurchHdr."VAT Date");
        VATCtrlRptLn.TestField("Original Document VAT Date", CalcDate('<-CM-2M>', PurchHdr."VAT Date"));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler')]
    [Scope('OnPrem')]
    procedure SuggestingVATControlReportPurchase3()
    var
        Commodity: Record Commodity;
        PurchLn1: Record "Purchase Line";
        PurchLn2: Record "Purchase Line";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Suggest a Posted Purchase Invoice with VAT Posting Setup "PDP21" and "15S" to VAT Control Report Lines

        Initialize;
        LibraryTax.SetUseVATDate(true);

        PreparePurchaseTestCase(
          VATPostingSetup1, VATPostingSetup2, Commodity,
          VATCtrlRptHdr, PurchLn1, PurchLn2, PostedDocumentNo);

        // [THEN] VAT Entries which are created from Posted Purchase Invoice are suggested to VAT Control Report
        VerifyVATControlReport(
          VATCtrlRptHdr."No.", PostedDocumentNo, 'B1',
          PurchLn1."Direct Unit Cost",
          CalcVATAmount(
            VATPostingSetup1."VAT Bus. Posting Group",
            VATPostingSetup1."VAT Prod. Posting Group",
            PurchLn1."Direct Unit Cost"),
          VATCtrlRptLn."VAT Rate"::Base, 0, Commodity.Code);

        VerifyVATControlReport(
          VATCtrlRptHdr."No.", PostedDocumentNo, 'B3',
          PurchLn2."Direct Unit Cost",
          CalcVATAmount(
            VATPostingSetup2."VAT Bus. Posting Group",
            VATPostingSetup2."VAT Prod. Posting Group",
            PurchLn2."Direct Unit Cost"),
          VATCtrlRptLn."VAT Rate"::Reduced, 0, '');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler,VATControlReportStatisticsHandler')]
    [Scope('OnPrem')]
    procedure TestVATControlReportStatistics()
    var
        Commodity: Record Commodity;
        PurchLn1: Record "Purchase Line";
        PurchLn2: Record "Purchase Line";
        VATCtrlRptBuf: Record "VAT Control Report Buffer";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Suggest a Posted Purchase Invoice with VAT Posting Setup "PDP21" and "15S" to VAT Control Report Lines
        // and check statistics

        Initialize;
        LibraryTax.SetUseVATDate(true);

        PreparePurchaseTestCase(
          VATPostingSetup1, VATPostingSetup2, Commodity,
          VATCtrlRptHdr, PurchLn1, PurchLn2, PostedDocumentNo);

        // [WHEN] Open VAT Control Report Statistics
        LibraryVATCtrlRptStat.SetVATControlReportHeader(VATCtrlRptHdr);

        // [THEN] Amounts of VAT Entries are correctly displayed in the Statistics
        LibraryVATCtrlRptStat.GetLineWithSection('B1', VATCtrlRptBuf);
        VATCtrlRptBuf.TestField("Base 1", Round(PurchLn1."Direct Unit Cost", 0.01));
        VATCtrlRptBuf.TestField("Amount 1",
          Round(
            CalcVATAmount(
              VATPostingSetup1."VAT Bus. Posting Group",
              VATPostingSetup1."VAT Prod. Posting Group",
              PurchLn1."Direct Unit Cost"), 0.01));

        LibraryVATCtrlRptStat.GetLineWithSection('B3', VATCtrlRptBuf);
        VATCtrlRptBuf.TestField("Base 2", Round(PurchLn2."Direct Unit Cost", 0.01));
        VATCtrlRptBuf.TestField("Amount 2",
          Round(
            CalcVATAmount(
              VATPostingSetup2."VAT Bus. Posting Group",
              VATPostingSetup2."VAT Prod. Posting Group",
              PurchLn2."Direct Unit Cost"), 0.01));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler,VATControlReportTestHandler')]
    [Scope('OnPrem')]
    procedure PrintingVATControlReportTest()
    var
        Commodity: Record Commodity;
        PurchLn1: Record "Purchase Line";
        PurchLn2: Record "Purchase Line";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Suggest a Posted Purchase Invoice with VAT Posting Setup "PDP21" and "15S" to VAT Control Report Lines
        // and print test report

        Initialize;
        LibraryTax.SetUseVATDate(true);

        PreparePurchaseTestCase(
          VATPostingSetup1, VATPostingSetup2, Commodity,
          VATCtrlRptHdr, PurchLn1, PurchLn2, PostedDocumentNo);

        // [WHEN] Print VAT Control Report Header - Test
        PrintTestReport(VATCtrlRptHdr, 0, 0, 0, false);

        // [THEN] Amounts and other values are correctly printed in the VAT Control Report - Test
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VATControlReportHeader_No', VATCtrlRptHdr."No.");

        LibraryReportDataset.MoveToRow(
          LibraryReportDataset.FindRow('VATControlReportBuffer_VATControlRepSectionCode', 'B1') + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATControlReportBuffer_Base1',
          Round(PurchLn1."Direct Unit Cost", 0.01));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATControlReportBuffer_Amount1',
          Round(
            CalcVATAmount(
              VATPostingSetup1."VAT Bus. Posting Group",
              VATPostingSetup1."VAT Prod. Posting Group",
              PurchLn1."Direct Unit Cost"), 0.01));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATControlReportBuffer_CommodityCode', Commodity.Code);

        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(
          LibraryReportDataset.FindRow('VATControlReportBuffer_VATControlRepSectionCode', 'B3') + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATControlReportBuffer_Base2',
          Round(PurchLn2."Direct Unit Cost", 0.01));
        LibraryReportDataset.AssertCurrentRowValueEquals('VATControlReportBuffer_Amount2',
          Round(
            CalcVATAmount(
              VATPostingSetup2."VAT Bus. Posting Group",
              VATPostingSetup2."VAT Prod. Posting Group",
              PurchLn2."Direct Unit Cost"), 0.01));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,GetVATEntriesHandler,GetDocNoandDateHandler')]
    [Scope('OnPrem')]
    procedure ClosingVATControlReportLines()
    var
        Commodity: Record Commodity;
        PurchLn1: Record "Purchase Line";
        PurchLn2: Record "Purchase Line";
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        ClosedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Close lines of suggested VAT Control Report

        Initialize;
        LibraryTax.SetUseVATDate(true);

        PreparePurchaseTestCase(
          VATPostingSetup1, VATPostingSetup2, Commodity,
          VATCtrlRptHdr, PurchLn1, PurchLn2, PostedDocumentNo);

        // [GIVEN] Release VAT Control Report
        ReleaseVATControlReport(VATCtrlRptHdr);

        // [WHEN] Close lines is execute with "Document No." from VAT Control Report Header
        ClosedDocumentNo := CloseVATControlReportLines(VATCtrlRptHdr);

        // [THEN] All lines will have value of "Closed by Document No." same as the "Document No." from VAT Control Report Header
        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        if VATCtrlRptLn.FindSet then
            repeat
                VATCtrlRptLn.TestField("Closed by Document No.", ClosedDocumentNo);
            until VATCtrlRptLn.Next = 0;
    end;

    local procedure PreparePurchaseTestCase(var VATPostingSetup1: Record "VAT Posting Setup"; var VATPostingSetup2: Record "VAT Posting Setup"; var Commodity: Record Commodity; var VATCtrlRptHdr: Record "VAT Control Report Header"; var PurchLn1: Record "Purchase Line"; var PurchLn2: Record "Purchase Line"; var PostedDocumentNo: Code[20])
    var
        PurchHdr: Record "Purchase Header";
        TariffNumber: Record "Tariff Number";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [GIVEN] Create VAT Posting Setup PDP21
        CreateVATPostingSetup(VATPostingSetup1, VATPostingSetup1."VAT Calculation Type"::"Reverse Charge VAT",
          VATPostingSetup2."VAT Rate"::Base, 21, 0, VATPostingSetup2."Reverse Charge Check"::"Limit Check & Export");

        // [GIVEN] Create VAT Posting Setup 15S
        CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Normal VAT",
          VATPostingSetup2."VAT Rate"::Reduced, 15, 0, VATPostingSetup2."Reverse Charge Check"::" ");

        // [GIVEN] Create VAT Statement Lines with PDP21 and 15S
        CreateVATStatement(VATStatementName);
        CreateVATStatementLine(VATStatementLine, VATStatementName,
          1, VATPostingSetup1."VAT Bus. Posting Group", VATPostingSetup1."VAT Prod. Posting Group", 'B1');
        CreateVATStatementLine(VATStatementLine, VATStatementName,
          1, VATPostingSetup2."VAT Bus. Posting Group", VATPostingSetup2."VAT Prod. Posting Group", 'B2');

        // [GIVEN] Create Commodity with Commodity Setup
        // [GIVEN] Create Tariff Number with Allow Empty Unit of Meas.Code
        CreateCommodityWithTariffNumber(Commodity, TariffNumber, 0);

        // [GIVEN] Create and Post Purchase Invoice with amount
        CreatePurchHeader(PurchHdr, PurchHdr."Document Type"::Invoice, VATPostingSetup1);
        CreatePurchLine(PurchHdr, PurchLn1, VATPostingSetup1, LibraryRandom.RandDec(5000, 2), TariffNumber."No.");
        CreatePurchLine(PurchHdr, PurchLn2, VATPostingSetup2, LibraryRandom.RandDec(1000, 2), '');
        PostedDocumentNo := PostPurchDocument(PurchHdr);

        // [GIVEN] Create VAT Control Report Header at period of VAT Date from Purchase Invoice
        CreateVATControlReport(
          VATCtrlRptHdr, Date2DMY(PurchHdr."VAT Date", 2), Date2DMY(PurchHdr."VAT Date", 3),
          VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        // [WHEN] Suggest VAT Control Report Lines is execute with period of VAT Date from Purchase Invoice
        SuggestVATControlReportLines(VATCtrlRptHdr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibraryTax.CreateStatReportingSetup;
        LibraryTax.SetVATControlReportInformation;
        LibraryTax.SetCompanyType(2); // Corporate
        LibraryTax.CreateDefaultVATControlReportSections;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Stat. Reporting Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure CalcVATAmount(VATBusPstGroup: Code[20]; VATProdPstGroup: Code[20]; Amt: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPstGroup, VATProdPstGroup);
        exit(Amt * VATPostingSetup."VAT %" / 100);
    end;

    local procedure CalcVATAmountForPurchInvoice(PurchInvHdr: Record "Purch. Inv. Header") Amount: Decimal
    var
        PurchInvLn: Record "Purch. Inv. Line";
    begin
        PurchInvLn.SetRange("Document No.", PurchInvHdr."No.");
        if PurchInvLn.FindSet(false, false) then
            repeat
                Amount +=
                  CalcVATAmountLCY(
                    CalcVATAmount(
                      PurchInvLn."VAT Bus. Posting Group",
                      PurchInvLn."VAT Prod. Posting Group",
                      PurchInvLn.Amount),
                    PurchInvHdr."Currency Code",
                    PurchInvHdr."Currency Factor",
                    PurchInvHdr."Posting Date");
            until PurchInvLn.Next = 0;
    end;

    local procedure CalcVATAmountLCY(VATAmt: Decimal; CurrCode: Code[10]; CurrFactor: Decimal; PostingDate: Date) VATAmtLCY: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        VATAmtLCY := 0;

        if CurrCode = '' then
            VATAmtLCY := VATAmt
        else
            VATAmtLCY := CurrExchRate.ExchangeAmtFCYToLCY(PostingDate, CurrCode, VATAmt, CurrFactor);
    end;

    local procedure ClientFileExists(FilePath: Text): Boolean
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(FileMgt.ClientFileExists(FilePath));
    end;

    local procedure CloseVATControlReportLines(var VATCtrlRptHdr: Record "VAT Control Report Header"): Code[20]
    begin
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."No.");
        LibraryTax.CloseVATControlReportLines(VATCtrlRptHdr);
        exit(VATCtrlRptHdr."No.");
    end;

    local procedure CreateCommodity(var Commodity: Record Commodity; LimitAmount: Decimal)
    var
        CommoditySetup: Record "Commodity Setup";
    begin
        LibraryTax.CreateCommodity(Commodity);
        LibraryTax.CreateCommoditySetup(CommoditySetup, Commodity.Code, WorkDate, 0D, LimitAmount);
    end;

    local procedure CreateCommodityWithTariffNumber(var Commodity: Record Commodity; var TariffNumber: Record "Tariff Number"; LimitAmount: Decimal)
    begin
        CreateCommodity(Commodity, LimitAmount);
        CreateTariffNumber(TariffNumber, Commodity.Code, Commodity.Code);
    end;

    local procedure CreatePurchHeader(var PurchHdr: Record "Purchase Header"; DocumentType: Option; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchHeader(PurchHdr, DocumentType,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchHdr."Original Document VAT Date" := PurchHdr."VAT Date";
        PurchHdr.Modify();
    end;

    local procedure CreatePurchLine(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal; TariffNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLn, PurchHdr, PurchLn.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 1), 1);
        PurchLn.Validate("Direct Unit Cost", Amount);
        PurchLn.Validate("Tariff No.", TariffNo);
        PurchLn.Modify(true);
    end;

    local procedure CreatePurchLineAboveLimit(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; TariffNo: Code[20])
    begin
        CreatePurchLine(PurchHdr, PurchLn, VATPostingSetup, GetRandAmountAboveLimit, TariffNo);
    end;

    local procedure CreatePurchLineBelowLimit(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; TariffNo: Code[20])
    begin
        CreatePurchLine(PurchHdr, PurchLn, VATPostingSetup, GetRandAmountBelowLimit, TariffNo);
    end;

    local procedure CreatePurchInvoiceAboveLimit(var PurchHdr: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; TariffNo: Code[20])
    var
        PurchLn: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchHdr, PurchHdr."Document Type"::Invoice, VATPostingSetup);
        CreatePurchLineAboveLimit(PurchHdr, PurchLn, VATPostingSetup, TariffNo);
    end;

    local procedure CreatePurchInvoiceBelowLimit(var PurchHdr: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; TariffNo: Code[20])
    var
        PurchLn: Record "Purchase Line";
    begin
        CreatePurchHeader(PurchHdr, PurchHdr."Document Type"::Invoice, VATPostingSetup);
        CreatePurchLineBelowLimit(PurchHdr, PurchLn, VATPostingSetup, TariffNo);
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(SalesLn, SalesHdr, SalesLn.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 2), 1);
        SalesLn.Validate("Unit Price", Amount);
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesInvoiceAboveLimit(var SalesHdr: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLn: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice,
          VATPostingSetup, GetRandAmountAboveLimit);
    end;

    local procedure CreateSalesInvoiceBelowLimit(var SalesHdr: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLn: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice,
          VATPostingSetup, GetRandAmountBelowLimit);
    end;

    local procedure CreateTariffNumber(var TariffNumber: Record "Tariff Number"; StatementCode: Code[10]; StatementLimitCode: Code[10])
    begin
        LibraryTax.CreateTariffNumber(TariffNumber);
        TariffNumber.Validate("Statement Code", StatementCode);
        TariffNumber.Validate("Statement Limit Code", StatementLimitCode);
        TariffNumber.Validate("Allow Empty Unit of Meas.Code", true);
        TariffNumber.Modify(true);
    end;

    local procedure CreateVATControlReport(var VATCtrlRptHdr: Record "VAT Control Report Header"; PeriodNo: Integer; Year: Integer; VATStatementTemplateName: Code[10]; VATStatementName: Code[10])
    begin
        LibraryTax.CreateVATControlReportWithPeriod(VATCtrlRptHdr, PeriodNo, Year);
        VATCtrlRptHdr.Validate("VAT Statement Template Name", VATStatementTemplateName);
        VATCtrlRptHdr.Validate("VAT Statement Name", VATStatementName);
        VATCtrlRptHdr.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Option; VATRate: Option; VATPct: Decimal; CorrectionsForBadReceivable: Option; ReverseChargeCheck: Option)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("VAT Rate", VATRate);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo);
        VATPostingSetup.Validate("Corrections for Bad Receivable", CorrectionsForBadReceivable);
        VATPostingSetup.Validate("Reverse Charge Check", ReverseChargeCheck);
        VATPostingSetup.Modify();
    end;

    local procedure CreateVATStatement(var VATStatementName: Record "VAT Statement Name")
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementName: Record "VAT Statement Name"; GenPostingType: Option; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATControlRepSectionCode: Code[20])
    begin
        LibraryERM.CreateVATStatementLine(
          VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Validate("VAT Control Rep. Section Code", VATControlRepSectionCode);
        VATStatementLine.Modify();
    end;

    local procedure CreateVATStatementWithVATPostingSetup(var VATStatementLine: Record "VAT Statement Line"; var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Option; VATRate: Option; VATPct: Decimal; CorrectionsForBadReceivable: Option; ReverseChargeCheck: Option; GenPostingType: Integer; VATControlRepSectionCode: Code[20])
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        CreateVATPostingSetup(
          VATPostingSetup, VATCalculationType, VATRate, VATPct, CorrectionsForBadReceivable, ReverseChargeCheck);
        CreateVATStatement(VATStatementName);
        CreateVATStatementLine(VATStatementLine, VATStatementName, GenPostingType,
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATControlRepSectionCode);
    end;

    local procedure ExportVATControlReport(var VATCtrlRptHdr: Record "VAT Control Report Header"): Text
    begin
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."Start Date");
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."End Date");
        exit(LibraryTax.ExportVATControlReport(VATCtrlRptHdr));
    end;

    local procedure GetRandAmountAboveLimit(): Decimal
    begin
        exit(LibraryRandom.RandDecInRange(10000, 20000, 2));
    end;

    local procedure GetRandAmountBelowLimit(): Decimal
    begin
        exit(LibraryRandom.RandDec(999, 2));
    end;

    local procedure PostPurchDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure PrintTestReport(var VATCtrlRptHdr: Record "VAT Control Report Header"; ReportPrintType: Option; ReportPrintEntries: Option; Selection: Option; OnlyErrorLines: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ReportPrintType);
        LibraryVariableStorage.Enqueue(ReportPrintEntries);
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(OnlyErrorLines);
        LibraryTax.PrintTestVATControlReport(VATCtrlRptHdr);
    end;

    local procedure ReleaseVATControlReport(var VATCtrlRptHdr: Record "VAT Control Report Header")
    begin
        LibraryTax.ReleaseVATControlReport(VATCtrlRptHdr);
    end;

    local procedure SuggestVATControlReportLines(var VATCtrlRptHdr: Record "VAT Control Report Header")
    begin
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."Start Date");
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."End Date");
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."VAT Statement Template Name");
        LibraryVariableStorage.Enqueue(VATCtrlRptHdr."VAT Statement Name");
        LibraryVariableStorage.Enqueue(0); // Add
        Commit();
        LibraryTax.SuggestVATControlReportLines(VATCtrlRptHdr);
    end;

    local procedure VerifyVATControlReportWithSalesInvoice(ControlReportNo: Code[20]; DocumentNo: Code[20]; ExpectedVATControlRepSectionCode: Code[20]; ExpectedVATRate: Option; ExpectedCorrectionsForBadReceivable: Option; ExpectedCommodityCode: Code[10])
    var
        SalesInvHdr: Record "Sales Invoice Header";
        ExpectedBase: Decimal;
        ExpectedAmount: Decimal;
    begin
        SalesInvHdr.Get(DocumentNo);
        SalesInvHdr.CalcFields(Amount, "Amount Including VAT");
        ExpectedBase := -SalesInvHdr.Amount;
        ExpectedAmount := -(SalesInvHdr."Amount Including VAT" - SalesInvHdr.Amount);

        VerifyVATControlReport(ControlReportNo, DocumentNo, ExpectedVATControlRepSectionCode, ExpectedBase, ExpectedAmount,
          ExpectedVATRate, ExpectedCorrectionsForBadReceivable, ExpectedCommodityCode);
    end;

    local procedure VerifyVATControlReportWithPurchInvoice(ControlReportNo: Code[20]; DocumentNo: Code[20]; ExpectedVATControlRepSectionCode: Code[20]; ExpectedVATRate: Option; ExpectedCorrectionsForBadReceivable: Option; ExpectedCommodityCode: Code[10])
    var
        PurchInvHdr: Record "Purch. Inv. Header";
        ExpectedBase: Decimal;
        ExpectedAmount: Decimal;
    begin
        PurchInvHdr.Get(DocumentNo);
        PurchInvHdr.CalcFields(Amount, "Amount Including VAT");
        ExpectedBase := PurchInvHdr.Amount;
        ExpectedAmount := PurchInvHdr."Amount Including VAT" - PurchInvHdr.Amount;
        if ExpectedVATControlRepSectionCode = 'B1' then
            ExpectedAmount := CalcVATAmountForPurchInvoice(PurchInvHdr);

        VerifyVATControlReport(ControlReportNo, DocumentNo, ExpectedVATControlRepSectionCode, ExpectedBase, ExpectedAmount,
          ExpectedVATRate, ExpectedCorrectionsForBadReceivable, ExpectedCommodityCode);
    end;

    local procedure VerifyVATControlReport(ControlReportNo: Code[20]; DocumentNo: Code[20]; ExpectedVATControlRepSectionCode: Code[20]; ExpectedBase: Decimal; ExpectedAmount: Decimal; ExpectedVATRate: Option; ExpectedCorrectionsForBadReceivable: Option; ExpectedCommodityCode: Code[10])
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
    begin
        VATCtrlRptLn.SetRange("Control Report No.", ControlReportNo);
        VATCtrlRptLn.SetRange("Document No.", DocumentNo);
        VATCtrlRptLn.SetRange("VAT Control Rep. Section Code", ExpectedVATControlRepSectionCode);
        VATCtrlRptLn.SetRange("VAT Rate", ExpectedVATRate);
        VATCtrlRptLn.SetRange("Corrections for Bad Receivable", ExpectedCorrectionsForBadReceivable);
        VATCtrlRptLn.SetRange("Commodity Code", ExpectedCommodityCode);
        Assert.RecordIsNotEmpty(VATCtrlRptLn);

        VATCtrlRptLn.FindFirst;
        VATCtrlRptLn.TestField(Base, Round(ExpectedBase, 0.01));
        VATCtrlRptLn.TestField(Amount, Round(ExpectedAmount, 0.01));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetVATEntriesHandler(var GetVATEntries: TestRequestPage "Get VAT Entries")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        GetVATEntries.StartingDate.AssertEquals(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        GetVATEntries.EndingDate.AssertEquals(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        GetVATEntries.VATStatementTemplate.AssertEquals(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        GetVATEntries.VATStatementName.AssertEquals(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        GetVATEntries.ProcessEntryType.SetValue(VariantValue);
        GetVATEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExportVATControlReportHandler(var ExportVATControlReport: TestPage "Export VAT Control Report")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        ExportVATControlReport.StartDateName.AssertEquals(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        ExportVATControlReport.EndDateName.AssertEquals(VariantValue);
        ExportVATControlReport.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATControlReportStatisticsHandler(var VATControlReportStatistics: TestPage "VAT Control Report Statistics")
    begin
        LibraryVATCtrlRptStat.SetVATControlReportStatistics(VATControlReportStatistics);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATControlReportTestHandler(var VATControlReportTest: TestRequestPage "VAT Control Report - Test")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        VATControlReportTest.ReportPrintType.SetValue(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        VATControlReportTest.ReportPrintEntries.SetValue(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        VATControlReportTest.Selection.SetValue(VariantValue);
        LibraryVariableStorage.Dequeue(VariantValue);
        VATControlReportTest.OnlyErrorLines.SetValue(VariantValue);
        VATControlReportTest.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetDocNoandDateHandler(var GetDocNoandDate: TestPage "Get Doc.No and Date")
    var
        VariantValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariantValue);
        GetDocNoandDate.CloseDocNo.SetValue(VariantValue);
        GetDocNoandDate.OK.Invoke;
    end;
}

