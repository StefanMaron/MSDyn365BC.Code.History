codeunit 143016 "Library RU Reports"
{

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LocalReportMgt: Codeunit "Local Report Management";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;

    [Scope('OnPrem')]
    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 0),
          LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Option; SalesLineQty: Integer)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibraryInventory.CreateItem(Item);

        for I := 1 to SalesLineQty do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
            SalesLine.Modify(true);
        end;
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure GetSalesLinesAmountIncVAT(SalesHeader: Record "Sales Header"): Decimal
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        exit(SalesHeader."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceLinesAmountIncVAT(DocumentNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 0),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; LineQty: Integer)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(Vendor));

        for i := 1 to LineQty do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              CreateItem(Vendor."VAT Bus. Posting Group"), LibraryRandom.RandDecInRange(5, 10, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 1000, 2));
            PurchaseLine.Modify(true);
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateReleaseSalesInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchDocument(DocumentType: Option; LineQty: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDocument(PurchaseHeader, DocumentType, LineQty);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoiceAddSheet(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        UpdateSalesHeaderWithAddSheetInfo(SalesHeader, '<1M>');
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoiceMultiLines(var CustomerNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATRate: array[3] of Decimal;
        i: Integer;
    begin
        VATRate[1] := NormalVATRate;
        VATRate[2] := 10;
        VATRate[3] := 0;

        LibraryERM.CreateVATPostingSetupWithAccounts(
          TempVATPostingSetup, TempVATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATRate) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            VATPostingSetup[i] := TempVATPostingSetup;
            VATPostingSetup[i]."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
            VATPostingSetup[i]."VAT %" := VATRate[i];
            VATPostingSetup[i]."VAT Identifier" := VATProdPostingGroup.Code;
            VATPostingSetup[i].Insert();
        end;

        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);

        for i := 1 to ArrayLen(VATRate) do
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup[i]);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoiceAddSheet(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CurrencyCode);
        UpdatePurchaseHeaderWithAddSheetInfo(PurchaseHeader, '<1M>');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreatePostPurchaseInvoiceMultiLines(var VendorNo: Code[20]; CurrencyCode: Code[10]; NormalVATRate: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATRate: array[3] of Decimal;
        i: Integer;
    begin
        VATRate[1] := NormalVATRate;
        VATRate[2] := 10;
        VATRate[3] := 0;

        LibraryERM.CreateVATPostingSetupWithAccounts(
          TempVATPostingSetup, TempVATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATRate) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            VATPostingSetup[i] := TempVATPostingSetup;
            VATPostingSetup[i]."VAT Prod. Posting Group" := VATProdPostingGroup.Code;
            VATPostingSetup[i]."VAT %" := VATRate[i];
            VATPostingSetup[i]."VAT Identifier" := VATProdPostingGroup.Code;
            VATPostingSetup[i].Insert();
        end;

        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group");
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, CurrencyCode);

        for i := 1 to ArrayLen(VATRate) do
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup[i]);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    [Scope('OnPrem')]
    procedure CreateItem(VATBusPostGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItem(Item);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostGroup);
        VATPostingSetup.FindFirst;

        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor): Code[20]
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        CompanyInformation.Get();
        CreatePostCode(PostCode);
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name), 0));
            Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Name 2"), 0));
            Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Full Name"), 0));
            "VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
            Validate("KPP Code", LibraryUtility.GenerateGUID);
            Validate("Post Code", PostCode.Code);
            Validate(Address, LibraryUtility.GenerateGUID);
            Validate("Address 2", LibraryUtility.GenerateGUID);
            Modify(true);
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var Customer: Record Customer): Code[20]
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
    begin
        CompanyInformation.Get();
        CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name), 0));
            Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Name 2"), 0));
            Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Full Name"), 0));
            "VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
            Validate("KPP Code", LibraryUtility.GenerateGUID);
            Validate("Post Code", PostCode.Code);
            Validate(Address, LibraryUtility.GenerateGUID);
            Validate("Address 2", LibraryUtility.GenerateGUID);
            Modify(true);
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostCode(var PostCode: Record "Post Code")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryERM.CreatePostCode(PostCode);
        with PostCode do begin
            Validate("Country/Region Code", CompanyInformation."Country/Region Code");
            Validate(County, LibraryUtility.GenerateGUID);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATSettlementTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := LibraryUtility.GenerateRandomCode(GenJournalTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
        GenJournalTemplate.Type := GenJournalTemplate.Type::"VAT Settlement";
        GenJournalTemplate.Insert();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure SuggestPostManualVATSettlement(VendorNo: Code[20])
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATSettlementType: Option ,Purchase,Sale,"Fixed Asset","Future Expense";
    begin
        TempVATDocEntryBuffer.SetRange("CV No.", VendorNo);
        TempVATDocEntryBuffer.SetRange("Date Filter", 0D, WorkDate);
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, VATSettlementType::Purchase);
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);

        GetVATAgentPostingSetup(VATPostingSetup, VendorNo);
        PostVATSettlement(VATPostingSetup."VAT Settlement Template", VATPostingSetup."VAT Settlement Batch");
    end;

    [Scope('OnPrem')]
    procedure PostVATSettlement(VATSettlementTemplate: Code[10]; VATSettlementBatch: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJournalLine."Journal Template Name" := VATSettlementTemplate;
        GenJournalLine."Journal Batch Name" := VATSettlementBatch;
        Clear(GenJnlPostBatch);
        GenJnlPostBatch.VATSettlement(GenJournalLine);
    end;

    [Scope('OnPrem')]
    procedure MockDepreciationCode(): Code[10]
    var
        DepreciationCode: Record "Depreciation Code";
    begin
        with DepreciationCode do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockDepreciationGroup(): Code[10]
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        with DepreciationGroup do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockFADepreciationBook(var FADeprBook: Record "FA Depreciation Book")
    begin
        with FADeprBook do begin
            "Depreciation Starting Date" := GetRandomDate;
            "Disposal Date" := GetRandomDate;
            "Acquisition Date" := GetRandomDate;
            "G/L Acquisition Date" := GetRandomDate;
            "No. of Depreciation Months" := LibraryRandom.RandIntInRange(5, 7);
            "No. of Depreciation Years" := LibraryRandom.RandIntInRange(3, 5);
            "FA Posting Group" := MockFAPostingGroup;
            "Depreciation Method" := "Depreciation Method"::"Straight-Line";
            Validate("Book Value", LibraryRandom.RandDec(100, 2));
            Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
            Validate("Initial Acquisition Cost", LibraryRandom.RandDec(100, 2));
            Validate("Acquisition Cost", LibraryRandom.RandDec(100, 2));
            Validate(Depreciation, LibraryRandom.RandDec(100, 2));
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockFALocation(): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        with FALocation do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockFAPostingGroup(): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        with FAPostingGroup do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            "Acquisition Cost Account" := MockGLAccount;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        with GLAccount do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockMainAssetComponent(FANo: Code[20])
    var
        MainAssetComponent: Record "Main Asset Component";
    begin
        with MainAssetComponent do begin
            Init;
            "Main Asset No." := FANo;
            "FA No." := LibraryUtility.GenerateGUID;
            Description := "FA No.";
            Quantity := LibraryRandom.RandInt(100);
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockItemFAPreciousMetal(FANo: Code[20])
    var
        ItemFAPreciousMetal: Record "Item/FA Precious Metal";
    begin
        with ItemFAPreciousMetal do begin
            Init;
            "Item Type" := "Item Type"::FA;
            "No." := FANo;
            "Precious Metals Code" := MockPreciousMetal;
            Quantity := LibraryRandom.RandInt(100);
            Mass := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure MockPreciousMetal(): Code[10]
    var
        PreciousMetal: Record "Precious Metal";
    begin
        with PreciousMetal do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Name := Code;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPurchaseTotalAmount(DocumentType: Option; OrderNo: Code[20]): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do begin
            Get(DocumentType, OrderNo);
            CalcFields(Amount);
            exit(FormatAmount(Amount));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPurchaseTotalAmountIncVAT(DocumentType: Option; OrderNo: Code[20]): Text
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do begin
            Get(DocumentType, OrderNo);
            CalcFields("Amount Including VAT");
            exit(FormatAmount("Amount Including VAT"));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPostedPurchaseTotalAmount(DocumentNo: Code[20]): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        with PurchInvHeader do begin
            Get(DocumentNo);
            CalcFields(Amount);
            exit(FormatAmount(Amount));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPostedPurchaseTotalAmountIncVAT(DocumentNo: Code[20]): Text
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        with PurchInvHeader do begin
            Get(DocumentNo);
            CalcFields("Amount Including VAT");
            exit(FormatAmount("Amount Including VAT"));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit;

        GLSetup.Get();
        if GLSetup."LCY Code" = CurrencyCode then
            exit;

        if LocalReportMgt.IsConventionalCurrency(CurrencyCode) then
            exit;

        if Currency.Get(CurrencyCode) then begin
            if Currency."RU Bank Digital Code" <> '' then
                exit(Currency."RU Bank Digital Code");
            exit(Currency.Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCustomerFullAddress(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        with Customer do begin
            Get(CustomerNo);
            exit(LocalReportMgt.GetFullAddr("Post Code", City, Address, "Address 2", '', County));
        end;
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        StdRepMgt: Codeunit "Local Report Management";
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;

    [Scope('OnPrem')]
    procedure FormatAmountXML(DecValue: Decimal): Text
    begin
        exit(Format(DecValue, 0, '<Precision,2:2><Sign><Integer><Decimals><comma,.>'));
    end;

    local procedure GetRandomDate(): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate));
    end;

    [Scope('OnPrem')]
    procedure GetFirstFADeprBook(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        with FADepreciationBook do begin
            SetRange("FA No.", FANo);
            FindFirst;
            exit("Depreciation Book Code");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATAgentPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", Vendor."VAT Agent Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure GetRandomVATRegNoForCVType(CVType: Option Person,Company): Text[12]
    begin
        case CVType of
            CVType::Person:
                exit(CopyStr(LibraryUtility.GenerateRandomXMLText(12), 1, 12));  // individual\person
            CVType::Company:
                exit(CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 10));  // company\organization
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithCost(): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            LibraryInventory.CreateItem(Item);
            Validate("Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
            Modify(true);
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateLocation(UseAsTransit: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        with Location do begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            Validate("Use As In-Transit", UseAsTransit);
            Modify(true);
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure InitItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; Type: Option; ClearJnl: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, Type, ItemJournalTemplate.Name);
        if ClearJnl then
            LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        ItemJnlLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJournalBatch.Name;
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; ClearJnl: Boolean)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        InitItemJournalLine(ItemJnlLine, ItemJournalTemplate.Type::Item, ClearJnl);

        with ItemJnlLine do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJnlLine, "Journal Template Name", "Journal Batch Name", "Entry Type"::"Positive Adjmt.", ItemNo, 0);
            Validate("Location Code", LocationCode);
            Validate(Quantity, Qty);
            Modify(true);
        end;

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure CreateStatutoryReport(var StatutoryReport: Record "Statutory Report")
    begin
        with StatutoryReport do begin
            Init;
            Code :=
              LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Statutory Report");
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Name), 0));
            Validate("Name 2", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Name 2"), 0));
            Validate("Full Name", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen("Full Name"), 0));
            "VAT Registration No." := LibraryERM.GenerateVATRegistrationNo("Country/Region Code");
            Validate("KPP Code", LibraryUtility.GenerateGUID);
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyTypeInfo(Type: Option)
    var
        CompanyInfo: Record "Company Information";
        CompanyType: Option Person,Organization;
    begin
        with CompanyInfo do begin
            Get;
            case Type of
                CompanyType::Organization:
                    Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
                CompanyType::Person:
                    Validate("KPP Code", '');
            end;
            "VAT Registration No." := GetRandomVATRegNoForCVType(Type);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVATPostingSetupWithManualVATSettlement(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateVATSettlementTemplateAndBatch(GenJournalBatch);
        VATPostingSetup.Validate("Manual VAT Settlement", true);
        VATPostingSetup.Validate("VAT Settlement Template", GenJournalBatch."Journal Template Name");
        VATPostingSetup.Validate("VAT Settlement Batch", GenJournalBatch.Name);
        VATPostingSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyAddress()
    var
        CompanyAddress: Record "Company Address";
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode);
        with CompanyAddress do begin
            FindFirst;
            Validate("Post Code", PostCode.Code);
            Validate("Region Name", LibraryUtility.GenerateGUID);
            Validate(Address, LibraryUtility.GenerateGUID);
            Validate("Address 2", LibraryUtility.GenerateGUID);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomerPrepmtAccountVATRate(CustomerNo: Code[20]; VATRate: Decimal)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // Copy paste existing setup and insert a new one with given VAT Rate
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup."Prepayment Account");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        VATPostingSetup.Validate("VAT %", VATRate);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Insert(true);

        GLAccount.Validate("No.", LibraryUtility.GenerateGUID);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Insert(true);

        CustomerPostingGroup.Validate(Code, LibraryUtility.GenerateGUID);
        CustomerPostingGroup.Validate("Prepayment Account", GLAccount."No.");
        CustomerPostingGroup.Insert(true);

        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesHeaderWithAddSheetInfo(var SalesHeader: Record "Sales Header"; PostingDateCalcFormula: Code[10])
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, PostingDateCalcFormula);
        with SalesHeader do begin
            Validate("Posting Date", CalcDate(DateFormula, WorkDate));
            Validate("Additional VAT Ledger Sheet", true);
            Validate("Corrected Document Date", WorkDate);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchaseHeaderWithAddSheetInfo(var PurchaseHeader: Record "Purchase Header"; PostingDateCalcFormula: Code[10])
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, PostingDateCalcFormula);
        with PurchaseHeader do begin
            Validate("Posting Date", CalcDate(DateFormula, WorkDate));
            Validate("Additional VAT Ledger Sheet", true);
            Validate("Corrected Document Date", WorkDate);
            Modify(true);
            UpdatePurchaseHeaderWithVendorVATInvoiceInfo(PurchaseHeader, '', WorkDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchaseHeaderWithVendorVATInvoiceInfo(var PurchaseHeader: Record "Purchase Header"; VendVATInvNo: Code[30]; VendorVATInvDate: Date)
    begin
        with PurchaseHeader do begin
            Validate("Vendor VAT Invoice No.", VendVATInvNo);
            Validate("Vendor VAT Invoice Date", VendorVATInvDate);
            Validate("Vendor VAT Invoice Rcvd Date", VendorVATInvDate);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustomerType(CustomerNo: Code[20]; CustomerType: Option Person,Company)
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            Get(CustomerNo);
            Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
            "VAT Registration No." := GetRandomVATRegNoForCVType(CustomerType);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVendorType(VendorNo: Code[20]; VendorType: Option Person,Company)
    var
        Vendor: Record Vendor;
    begin
        with Vendor do begin
            Get(VendorNo);
            Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
            "VAT Registration No." := GetRandomVATRegNoForCVType(VendorType);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; LedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20])
    begin
        with VATLedgerLine do begin
            SetRange(Type, LedgerType);
            SetRange(Code, VATLedgerCode);
            SetRange("C/V No.", CVNo);
            FindFirst;
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCustomerDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; CustomerNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        with VATLedgerLine do begin
            FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, CustomerNo);
            Assert.AreEqual(LocalReportMgt.GetCustName(CustomerNo), "C/V Name", FieldCaption("C/V Name"));
            Assert.AreEqual(Customer."VAT Registration No.", "C/V VAT Reg. No.", FieldCaption("C/V VAT Reg. No."));
            Assert.AreEqual(Customer."KPP Code", "Reg. Reason Code", FieldCaption("Reg. Reason Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineVendorDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; VendorNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        with VATLedgerLine do begin
            FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, VendorNo);
            Assert.AreEqual(LocalReportMgt.GetVendorName(VendorNo), "C/V Name", FieldCaption("C/V Name"));
            Assert.AreEqual(Vendor."VAT Registration No.", "C/V VAT Reg. No.", FieldCaption("C/V VAT Reg. No."));
            Assert.AreEqual(Vendor."KPP Code", "Reg. Reason Code", FieldCaption("Reg. Reason Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCompanyDetails(VATLedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        with VATLedgerLine do begin
            FindVATLedgerLine(VATLedgerLine, VATLedgerType, VATLedgerCode, CVNo);
            Assert.AreEqual(LocalReportMgt.GetCompanyName, "C/V Name", FieldCaption("C/V Name"));
            Assert.AreEqual(CompanyInformation."VAT Registration No.", "C/V VAT Reg. No.", FieldCaption("C/V VAT Reg. No."));
            Assert.AreEqual(CompanyInformation."KPP Code", "Reg. Reason Code", FieldCaption("Reg. Reason Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyVATLedgerLineCount(VATLedgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedVATLedgerLineCount: Integer)
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
    begin
        DummyVATLedgerLine.SetRange(Type, VATLedgerType);
        DummyVATLedgerLine.SetRange(Code, VATLedgerCode);
        DummyVATLedgerLine.SetRange("C/V No.", CVNo);
        Assert.RecordCount(DummyVATLedgerLine, ExpectedVATLedgerLineCount);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_DocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'BO', 2, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'N', 7, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'J', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_SellerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'W', 9, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_ConsigneeAndAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AH', 11, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'O', 13, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'J', 14, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_BuyerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AA', 15, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_ItemNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'A', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_TariffNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'W', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Unit(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AD', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_UnitName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AK', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Qty(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AV', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Price(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BE', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_Amount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BQ', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_VATPct(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'CQ', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_VATAmount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'CY', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_AmountInclVAT(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DK', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_CountryCode(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'EA', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_CountryName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'EH', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyFactura_GTD(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'EV', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CorrDocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AA', 6, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_DocNo(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AA', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CorrDocDate(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AI', 6, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_DocDate(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'AI', 8, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'M', 10, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'I', 11, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CompanyINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'X', 12, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'O', 13, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerAddress(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'I', 14, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_BuyerINN(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Y', 15, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CurrencyName(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'Y', 16, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_CurrencyCode(FileName: Text; ExpectedValue: Text)
    begin
        VerifyExcelReportValue(FileName, 'BV', 16, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_ItemNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'A', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_TariffNo(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'Z', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_UOMCode(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AB', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_UOMName(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AI', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Qty(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'AU', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Price(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BE', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_Amount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'BQ', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_VATPct(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'CS', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_VATAmount(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DC', 23 + RowOffset, ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure VerifyCorrFactura_AmountInclVAT(FileName: Text; ExpectedValue: Text; RowOffset: Integer)
    begin
        VerifyExcelReportValue(FileName, 'DN', 23 + RowOffset, ExpectedValue);
    end;

    local procedure VerifyExcelReportValue(FileName: Text; ColumnName: Text; RowNo: Integer; ExpectedValue: Text)
    begin
        if LibraryReportValidation.GetFileName <> FileName then
            LibraryReportValidation.SetFullFileName(FileName);
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, ExpectedValue);
    end;
}

