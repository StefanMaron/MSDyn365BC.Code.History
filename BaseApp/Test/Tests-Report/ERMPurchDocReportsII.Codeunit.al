codeunit 134336 "ERM Purch. Doc. Reports - II"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('VendorLabelReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLabel36x70mm3Columns()
    var
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Check Vendor Label Report with Label Format 36 x 70 mm (3 columns).
        Initialize();
        VendorLabelReport(LabelFormat::"36 x 70 mm (3 columns)", 3);
    end;

    [Test]
    [HandlerFunctions('VendorLabelReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLabel37x70mm3Columns()
    var
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Check Vendor Label Report with Label Format 37 x 70 mm (3 columns).
        Initialize();
        VendorLabelReport(LabelFormat::"37 x 70 mm (3 columns)", 3);
    end;

    [Test]
    [HandlerFunctions('VendorLabelReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLabel36x105mm2Columns()
    var
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Check Vendor Label Report with Label Format 36 x 105 mm (2 columns).
        Initialize();
        VendorLabelReport(LabelFormat::"36 x 105 mm (2 columns)", 2);
    end;

    [Test]
    [HandlerFunctions('VendorLabelReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLabel37x105mm2Columns()
    var
        LabelFormat: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)";
    begin
        // Check Vendor Label Report with Label Format 37 x 105 mm (2 columns).
        Initialize();
        VendorLabelReport(LabelFormat::"37 x 105 mm (2 columns)", 2);
    end;

    local procedure VendorLabelReport(LabelFormat: Option; NumberOfColumns: Integer)
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        Vendor3: Record Vendor;
        VendorLabels: Report "Vendor - Labels";
    begin
        // Setup: Create Three Vendor with Complete Address.
        Initialize();
        CreateVendorWithAddress(Vendor);
        CreateVendorWithAddress(Vendor2);
        CreateVendorWithAddress(Vendor3);

        // Exercise.
        Commit();
        Clear(VendorLabels);
        Vendor.SetFilter("No.", '%1|%2|%3', Vendor."No.", Vendor2."No.", Vendor3."No.");
        VendorLabels.SetTableView(Vendor);
        VendorLabels.InitializeRequest(LabelFormat);
        VendorLabels.Run();

        // Verify: Verify All Vendor with Different Label Format.
        LibraryReportDataset.LoadDataSetFile();
        VerifyLabels(Vendor, 1, NumberOfColumns);
        VerifyLabels(Vendor2, 2, NumberOfColumns);
        VerifyLabels(Vendor3, 3, NumberOfColumns);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch. Doc. Reports - II");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch. Doc. Reports - II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch. Doc. Reports - II");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));   // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    begin
        // Create a Purchase Document Without Currency.
        CreatePurchaseDocument(PurchaseHeader, DocumentType, CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Value.
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithAddress(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreatePostCode(PostCode);  // Creation of Post Code is required to avoid special characters in existing ones.
        CountryRegion.FindFirst();
        Vendor.Get(CreateVendor());
        Vendor.Validate(
          Address, CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor), 1,
            LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo(Address))));
        Vendor.Validate(
          "Address 2", CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Address 2"), DATABASE::Vendor), 1,
            LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("Address 2"))));
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);
    end;

    local procedure UpdateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Take Posting Date Earlier than Workdate.
        CreatePurchaseDocument(PurchaseHeader, DocumentType, CreateItem(), '');
        PurchaseHeader.Validate(
          "Posting Date", CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'M>', PurchaseHeader."Posting Date"));
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifyLabels(Vendor: Record Vendor; Index: Integer; NumberOfColumns: Integer)
    var
        CountryRegion: Record "Country/Region";
        FormatAddress: Codeunit "Format Address";
        PostCodeCity: Text[90];
        County: Text[50];
        Column: Integer;
    begin
        Column := ((Index - 1) mod NumberOfColumns) + 1;
        LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('VendAddr_%1__1_', Column), Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('VendAddr_%1__2_', Column), Vendor.Address);
        LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('VendAddr_%1__3_', Column), Vendor."Address 2");

        CountryRegion.Get(Vendor."Country/Region Code");
        FormatAddress.FormatPostCodeCity(PostCodeCity, County, Vendor.City, Vendor."Post Code", Vendor.County, CountryRegion.Code);

        LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('VendAddr_%1__4_', Column), PostCodeCity);
        LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('VendAddr_%1__5_', Column), CountryRegion.Name);
    end;

    local procedure VerifyPurchaseInvoiceNosReport(No: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();

        PurchInvHeader.Get(No);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchInvHeader__Pay_to_Vendor_No__', PurchInvHeader."Pay-to Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchInvHeader__Source_Code_', PurchInvHeader."Source Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchInvHeader__Pay_to_Name_', PurchInvHeader."Pay-to Name");
    end;

    local procedure VerifyPurchCreditMemoNosReport(No: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();

        PurchCrMemoHdr.Get(No);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchCrMemoHeader__Pay_to_Vendor_No__', PurchCrMemoHdr."Pay-to Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchCrMemoHeader__Source_Code_', PurchCrMemoHdr."Source Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchCrMemoHeader__Pay_to_Name_', PurchCrMemoHdr."Pay-to Name");
    end;

    local procedure VerifyVendorDocumentsNosReport(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();

        LibraryReportDataset.AssertCurrentRowValueEquals('VendLedgerEntry__Vendor_No__', VendorLedgerEntry."Vendor No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('VendLedgerEntry__Source_Code_', VendorLedgerEntry."Source Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('VendLedgerEntry__Document_No__', VendorLedgerEntry."Document No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorLabelReportRequestPageHandler(var VendorLabels: TestRequestPage "Vendor - Labels")
    begin
        VendorLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

