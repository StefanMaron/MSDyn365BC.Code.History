codeunit 142081 "Test Intrastat DACH"
{
    // // [FEATURE] [Intrastat]
    // Test Cases for Intrastat Journal.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IntrastatJnlLinesEUVendorCountErr: Label 'The only Intrastat Line with EU vendor should be created';
        IntrastatJnlLinesNonEUVendorCountErr: Label 'Intrastat Line with non-EU vendor should not be created';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestIntrastatGetEntriesWithNonEUItem()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        TempCompanyInfo: Record "Company Information" temporary;
        PostingDate: Date;
        VendorNo: Code[20];
        ItemNoX: Code[20];
        ItemNoY: Code[20];
    begin
        // [SCENARIO 122961] Run GetEntries from Intrastat Journal and get the only line with EU Vendor
        Initialize();
        SetIntrastatCodeOnCountryRegion(TempCompanyInfo);

        PostingDate := CalcDate('<3M>', WorkDate);
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, PostingDate);
        // [GIVEN] Posted Purchase Invoice for EU-Vendor "X" and non-EU Item "X"
        VendorNo := CreateVendor(true);
        CreateAndPostPurchInvoice(VendorNo, PostingDate, ItemNoX);
        // [GIVEN] Posted Purchase Invoice for NonEU-Vendor "Y" and non-EU Item "Y"
        VendorNo := CreateVendor(false);
        CreateAndPostPurchInvoice(VendorNo, PostingDate, ItemNoY);

        // [WHEN] Intrastat journal gets Item Ledger Entries
        RunGetItemLedgerEntries(IntrastatJnlBatch, PostingDate);

        // [THEN] Only one line with EU vendor "X" and Item "X" is created
        VerifyIntrastatJnlLines(IntrastatJnlBatch, ItemNoX, ItemNoY);

        // Tear Down: Restore Company Information
        RestoreCompanyInfo(TempCompanyInfo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlaceOfDispatcherCodeCannotBeBlank()
    var
        PlaceOfDispatchers: TestPage "Place of Dispatchers";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create Place Of Dispatcher with blank Code.
        Initialize();

        PlaceOfDispatchers.OpenNew();
        asserterror PlaceOfDispatchers.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlaceOfReceiverCodeCannotBeBlank()
    var
        PlaceOfReceivers: TestPage "Place of Receivers";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create Place Of Receiver with blank Code.
        Initialize();

        PlaceOfReceivers.OpenNew();
        asserterror PlaceOfReceivers.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Intrastat DACH");

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Intrastat DACH");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Intrastat DACH");
    end;

    local procedure CreateAndPostPurchInvoice(VendorNo: Code[20]; PostingDate: Date; var ItemNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);
        ItemNo := CreateItemWithTariffNo;
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreateVendor(EUVendor: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CreateCountryRegionWithIntrastatCode(EUVendor));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithTariffNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        with Item do begin
            Validate("Tariff No.", LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
            Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
            Validate("Country/Region of Origin Code", CreateCountryRegionWithIntrastatCode(false));
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateCountryRegionWithIntrastatCode(EUCountryRegion: Boolean): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate("Intrastat Code", Code);
            if EUCountryRegion then
                Validate("EU Country/Region Code", Code);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure RunGetItemLedgerEntries(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; NewDate: Date)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GetItemLedgerEntries: Report "Get Item Ledger Entries";
    begin
        IntrastatJnlLine.Init();
        IntrastatJnlLine.Validate("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.Validate("Journal Batch Name", IntrastatJnlBatch.Name);
        GetItemLedgerEntries.SetIntrastatJnlLine(IntrastatJnlLine);
        GetItemLedgerEntries.InitializeRequest(
          CalcDate('<-CM>', NewDate), CalcDate('<CM>', NewDate), 0);
        GetItemLedgerEntries.UseRequestPage(false);
        GetItemLedgerEntries.Run();
    end;

    local procedure SetIntrastatCodeOnCountryRegion(var TempCompanyInformation: Record "Company Information" temporary)
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        TempCompanyInformation := CompanyInformation;
        TempCompanyInformation.Insert();

        LibraryERM.CreateCountryRegion(CountryRegion);
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        CompanyInformation.Modify(true);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure RestoreCompanyInfo(TempCompanyInformation: Record "Company Information" temporary)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", TempCompanyInformation."Country/Region Code");
        CompanyInformation.Validate("Ship-to Country/Region Code", TempCompanyInformation."Ship-to Country/Region Code");
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyIntrastatJnlLines(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ItemNoX: Code[20]; ItemNoY: Code[20])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        with IntrastatJnlLine do begin
            SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
            SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
            SetRange("Item No.", ItemNoX);
            Assert.AreEqual(1, Count, IntrastatJnlLinesEUVendorCountErr);
            SetRange("Item No.", ItemNoY);
            Assert.IsTrue(IsEmpty, IntrastatJnlLinesNonEUVendorCountErr);
        end;
    end;
}

