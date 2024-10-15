codeunit 137209 "SCM Get Item Entries"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Get Item Ledger Entries] [Intrastat]
        IsInitialized := false;
    end;

    var
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LineType: Option Shipment,Receipt;
        IsInitialized: Boolean;

    local procedure ItemEntries(Type: Option; StartDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempCompanyInformation: Record "Company Information" temporary;
        DocumentType: Option;
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        NoOfLines: Integer;
    begin
        // Setup: Add country info and additional currency.
        Initialize;
        CompanyInformation.Get;
        TempCompanyInformation := CompanyInformation;
        TempCompanyInformation.Insert(true);
        UpdateCompanyInfo;
        CurrencyCode := UpdateAddnlReportingCurrency;

        // Setup intrastat journal.
        CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate, CurrencyCode, true);
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch);

        // Create sales document.
        CreateAndPostDocument(DocumentType, DocumentNo, Type);

        // Exercise: Get Item Ledger Entries for the specified dates.
        RunGetItemEntries(IntrastatJnlLine, StartDate, CalcDate('<+1D>', StartDate));

        // Verify: Intrastat lines correctly reflect Item Ledger entries.
        NoOfLines := VerifyIntrastatLines(IntrastatJnlLine, DocumentType, DocumentNo);

        // Prevent false negatives when some lines are retrieved for an invalid interval.
        Assert.IsFalse((WorkDate < StartDate) and (NoOfLines <> 0), 'Some lines were retrieved for ' + DocumentNo);

        // Tear Down: Restore company information.
        RestoreCompanyInfo(TempCompanyInformation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaleInsideInterval()
    begin
        ItemEntries(LineType::Shipment, CalcDate('<-1D>', WorkDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaleOutsideInterval()
    begin
        ItemEntries(LineType::Shipment, CalcDate('<+1D>', WorkDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInsideInterval()
    begin
        ItemEntries(LineType::Receipt, CalcDate('<-1D>', WorkDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOutsideInterval()
    begin
        ItemEntries(LineType::Receipt, CalcDate('<+1D>', WorkDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncludeItemChargeInIntrastat()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemCharge: Record "Item Charge";
        Item: Record Item;
        PostedSalesDocNo: Code[20];
        PostedPurchDocNo: Code[20];
    begin
        // [SCENARIO 378851] If Item Charge has "Freight/Insurance" = TRUE then entries having this Item Charge should be included in "Statistical Value" in Intrastat.

        Initialize;

        // [GIVEN] Item Charge having "Freight/Insurance" = TRUE
        CreateItemCharge(ItemCharge, true);

        // [GIVEN] Item with foreign "Country/Region of Origin Code"
        CreateForeignItem(Item);

        // [GIVEN] Posted Purchase Order with two line for foreign Vendor
        // [GIVEN] Purchase Line with Item with Price 100
        // [GIVEN] Purchase Line with Item (Charge) with Price 100
        PostedPurchDocNo := CreatePurchOrderWithItemCharge(Item, ItemCharge, 100);

        // [GIVEN] Posted Sales Order with two lines for foreign Customer
        // [GIVEN] Sales Line with Item with Price 200
        // [GIVEN] Sales Line with Item (Charge) with Price 200
        PostedSalesDocNo := CreateSalesOrderWithItemCharge(Item, ItemCharge, 200);

        // [WHEN] Getting Intrastat Lines
        CreateIntrastatJnlLineWithTemplateAndBatch(IntrastatJnlLine);
        RunGetItemEntries(IntrastatJnlLine, WorkDate, WorkDate + 1);

        // [THEN] "Statistical Value" of Intrastat Line for Purchase Document is 200 (includes Item Charge)
        VerifyStatisticalValueInIntrastatLine(PostedPurchDocNo, 200);

        // [THEN] "Statistical Value" of Intrastat Line for Sales Document is 400 (includes Item Charge)
        VerifyStatisticalValueInIntrastatLine(PostedSalesDocNo, 400);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExcludeItemChargeFromIntrastat()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ItemCharge: Record "Item Charge";
        Item: Record Item;
        PostedSalesDocNo: Code[20];
        PostedPurchDocNo: Code[20];
    begin
        // [SCENARIO 378851] If Item Charge has "Freight/Insurance" = FALSE then entries having this Item Charge should not be included in "Statistical Value" in Intrastat.

        Initialize;

        // [GIVEN] Item Charge having "Freight/Insurance" = FALSE
        CreateItemCharge(ItemCharge, false);

        // [GIVEN] Item with foreign "Country/Region of Origin Code"
        CreateForeignItem(Item);

        // [GIVEN] Posted Purchase Order with two line for foreign Vendor
        // [GIVEN] Purchase Line with Item with Price 100
        // [GIVEN] Purchase Line with Item (Charge) with Price 100
        PostedPurchDocNo := CreatePurchOrderWithItemCharge(Item, ItemCharge, 100);

        // [GIVEN] Posted Sales Order with two lines for foreign Customer
        // [GIVEN] Sales Line with Item with Price 200
        // [GIVEN] Sales Line with Item (Charge) with Price 200
        PostedSalesDocNo := CreateSalesOrderWithItemCharge(Item, ItemCharge, 200);

        // [WHEN] Getting Intrastat Lines
        CreateIntrastatJnlLineWithTemplateAndBatch(IntrastatJnlLine);
        RunGetItemEntries(IntrastatJnlLine, WorkDate, WorkDate + 1);

        // [THEN] "Statistical Value" of Intrastat Line for Purchase Document is 100 (not includes Item Charge)
        VerifyStatisticalValueInIntrastatLine(PostedPurchDocNo, 100);

        // [THEN] "Statistical Value" of Intrastat Line for Sales Document is 200 (not includes Item Charge)
        VerifyStatisticalValueInIntrastatLine(PostedSalesDocNo, 200);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Get Item Entries");
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Get Item Entries");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        IsInitialized := true;
        Commit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Get Item Entries");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        // Add required accounts for the currency setup.
        LibraryERM.FindGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        LibraryERM.FindGLAccount(GLAccount);
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate);

        // Using RANDOM Exchange Rate Amount and Adjustment Exchange Rate, between 100 and 400 (Standard Value).
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        TariffNumber: Record "Tariff Number";
    begin
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        // Add a tariff to all items to insure all eligible lines are retrieved in the intrastat journal.
        TariffNumber.FindFirst;
        Item.SetRange("Tariff No.", '');
        if Item.FindSet then
            repeat
                Item.Validate("Tariff No.", TariffNumber."No.");
                Item.Modify(true);
            until Item.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateForeignItem(var Item: Record Item)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        Item.Get(CreateItem);
        CompanyInformation.FindFirst;
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.FindFirst;
        Item."Country/Region of Origin Code" := CountryRegion.Code;
        Item.GTIN := LibraryUtility.GenerateRandomCode(Item.FieldNo(GTIN), DATABASE::Item);
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; FreightInsurance: Boolean)
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("Freight/Insurance", FreightInsurance);
        ItemCharge.Modify(true);
    end;

    local procedure UpdateAddnlReportingCurrency(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Set additional currency reporting in the GL setup.
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyAndExchangeRate;
        GeneralLedgerSetup.Modify(true);
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure CreateIntrastatJnlTemplate(var IntrastatJnlTemplate: Record "Intrastat Jnl. Template")
    begin
        IntrastatJnlTemplate.Init;
        IntrastatJnlTemplate.Validate(Name, LibraryUtility.GenerateRandomCode(IntrastatJnlTemplate.FieldNo(Name),
            DATABASE::"Intrastat Jnl. Template"));
        IntrastatJnlTemplate.Validate(Description, LibraryUtility.GenerateRandomCode(IntrastatJnlTemplate.FieldNo(Description),
            DATABASE::"Intrastat Jnl. Template"));
        IntrastatJnlTemplate.Validate("Checklist Report ID", 502);
        IntrastatJnlTemplate.Validate("Page ID", 311);
        IntrastatJnlTemplate.Insert(true);
    end;

    local procedure CreateIntrastatJnlBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; IntrastatJnlTemplate: Record "Intrastat Jnl. Template"; CurrencyID: Code[10]; AmountInAddCurr: Boolean)
    begin
        IntrastatJnlBatch.Init;
        IntrastatJnlBatch.Validate("Journal Template Name", IntrastatJnlTemplate.Name);
        IntrastatJnlBatch.Validate(Name, LibraryUtility.GenerateRandomCode(IntrastatJnlBatch.FieldNo(Name),
            DATABASE::"Intrastat Jnl. Batch"));
        IntrastatJnlBatch.Validate(Description, LibraryUtility.GenerateRandomCode(IntrastatJnlBatch.FieldNo(Description),
            DATABASE::"Intrastat Jnl. Batch"));
        IntrastatJnlBatch.Validate("Statistics Period", Format(Today, 0, '<Month,2><Year>'));
        IntrastatJnlBatch.Validate("Amounts in Add. Currency", AmountInAddCurr);
        IntrastatJnlBatch.Validate("Currency Identifier", CurrencyID);
        IntrastatJnlBatch.Insert(true);
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlLine.Init;
        IntrastatJnlLine.Validate("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.Validate("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateIntrastatJnlLineWithTemplateAndBatch(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name);
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        for Counter := 1 to 2 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, LibraryRandom.RandInt(10));
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrderWithItemCharge(Item: Record Item; ItemCharge: Record "Item Charge"; Amount: Decimal): Code[20]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CompanyInformation.FindFirst;
        CountryRegion.SetFilter(Code, '<>%1&<>%2', CompanyInformation."Country/Region Code", Item."Country/Region of Origin Code");
        CountryRegion.FindFirst;
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemCharge, SalesHeader."Document Type"::Order, SalesHeader."No.", 10000, Item."No.", 1, Amount);
        ItemChargeAssignmentSales.Insert;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Last Shipping No.");
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        for Counter := 1 to 2 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem,
              LibraryRandom.RandInt(10));
    end;

    [Scope('OnPrem')]
    procedure CreatePurchOrderWithItemCharge(Item: Record Item; ItemCharge: Record "Item Charge"; Amount: Decimal): Code[20]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CompanyInformation.FindFirst;
        CountryRegion.SetFilter(Code, '<>%1&<>%2', CompanyInformation."Country/Region Code", Item."Country/Region of Origin Code");
        CountryRegion.FindFirst;
        Vendor.Validate("Country/Region Code", 'FR');
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, PurchaseLine, ItemCharge, PurchaseHeader."Document Type"::Order, PurchaseHeader."No.",
          10000, Item."No.", 1, Amount);
        ItemChargeAssignmentPurch.Insert;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."Last Receiving No.");
    end;

    local procedure CreateAndPostDocument(var DocumentType: Option; var DocumentNo: Code[20]; Type: Option)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case Type of
            LineType::Shipment:
                begin
                    LibrarySales.CreateCustomer(Customer);
                    // Customize the customer to be from within EU, from a different country than the one defined in the company information.
                    Customer.Validate("Country/Region Code", CreateEUCountryRegion);
                    Customer.Modify(true);

                    // Create and post Sales Order.
                    CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
                    LibrarySales.PostSalesDocument(SalesHeader, true, false);

                    // Output shipment information.
                    SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                    SalesShipmentHeader.FindFirst;
                    DocumentType := ItemLedgerEntry."Document Type"::"Sales Shipment";
                    DocumentNo := SalesShipmentHeader."No.";
                end;
            LineType::Receipt:
                begin
                    LibraryPurchase.CreateVendor(Vendor);
                    // Customize the vendor to be from within EU, from a different country than the one defined in the company information.
                    Vendor.Validate("Country/Region Code", CreateEUCountryRegion);
                    Vendor.Modify(true);

                    // Create and post Purchase Order.
                    CreatePurchOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
                    LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

                    // Output receipt information.
                    PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
                    PurchRcptHeader.FindFirst;
                    DocumentType := ItemLedgerEntry."Document Type"::"Purchase Receipt";
                    DocumentNo := PurchRcptHeader."No.";
                end;
        end;
    end;

    local procedure CreateEUCountryRegion() CountryCode: Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init;
        CountryCode := CopyStr(
            LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region"), 1, 10);
        CountryRegion.Validate(Code, CountryCode);
        CountryRegion.Validate(Name, CountryCode);
        CountryRegion.Validate("EU Country/Region Code", CountryCode);
        CountryRegion.Validate("Intrastat Code", CountryCode);
        CountryRegion.Insert(true);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateEUCountryRegion;
        CompanyInformation.Get;
        CompanyInformation.Validate("Country/Region Code", CountryRegionCode);
        CompanyInformation.Validate("Ship-to Country/Region Code", CountryRegionCode);
        CompanyInformation.Modify(true);
    end;

    local procedure RestoreCompanyInfo(BaseCompanyInformation: Record "Company Information")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        CompanyInformation.Validate("Country/Region Code", BaseCompanyInformation."Country/Region Code");
        CompanyInformation.Validate("Ship-to Country/Region Code", BaseCompanyInformation."Ship-to Country/Region Code");
        CompanyInformation.Modify(true);
    end;

    local procedure RunGetItemEntries(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; StartDate: Date; EndDate: Date)
    var
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        GetItemLedgerEntries.InitializeRequest(StartDate, EndDate, 0);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        GetItemLedgerEntries.UseRequestPage(false);
        GetItemLedgerEntries.RunModal;
    end;

    local procedure VerifyIntrastatLines(IntrastatJnlLine: Record "Intrastat Jnl. Line"; DocumentType: Option; DocumentNo: Code[20]) RetrievedLines: Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
    begin
        RetrievedLines := 0;
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindSet;
        repeat
            IntrastatJnlLine.SetRange(Type, ItemLedgerEntry."Document Type");
            IntrastatJnlLine.SetRange(Date, ItemLedgerEntry."Posting Date");
            IntrastatJnlLine.SetRange("Source Type", IntrastatJnlLine."Source Type"::"Item Entry");
            IntrastatJnlLine.SetRange("Source Entry No.", ItemLedgerEntry."Entry No.");
            IntrastatJnlLine.SetRange("Document No.", DocumentNo);
            IntrastatJnlLine.SetRange("Item No.", ItemLedgerEntry."Item No.");
            RetrievedLines += IntrastatJnlLine.Count;
            if IntrastatJnlLine.FindFirst then begin
                Assert.AreEqual(1, IntrastatJnlLine.Count, 'Too many intrastat entries for ' + Format(ItemLedgerEntry."Entry No."));
                Item.Get(ItemLedgerEntry."Item No.");
                IntrastatJnlLine.TestField("Tariff No.", Item."Tariff No.");
                IntrastatJnlLine.TestField("Country/Region of Origin Code", Item."Country/Region of Origin Code");

                case DocumentType of
                    ItemLedgerEntry."Document Type"::"Sales Shipment":
                        begin
                            IntrastatJnlLine.TestField(Type, IntrastatJnlLine.Type::Shipment);
                            IntrastatJnlLine.TestField(Quantity, -ItemLedgerEntry.Quantity);
                        end;
                    ItemLedgerEntry."Document Type"::"Purchase Receipt":
                        begin
                            IntrastatJnlLine.TestField(Type, IntrastatJnlLine.Type::Receipt);
                            IntrastatJnlLine.TestField(Quantity, ItemLedgerEntry.Quantity);
                        end;
                end;
            end;
        until ItemLedgerEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure VerifyStatisticalValueInIntrastatLine(DocNo: Code[20]; Amount: Decimal)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.SetFilter("Document No.", DocNo);
        IntrastatJnlLine.FindFirst;
        IntrastatJnlLine.TestField("Statistical Value", Amount);
    end;
}

