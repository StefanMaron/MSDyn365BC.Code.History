codeunit 144061 "UT TAB INTRSTAT"
{
    // Test for feature - INTRASTAT.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Intrastat]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TariffNoFieldLength()
    var
        IntraFormBuffer: Record "Intra - form Buffer";
        TariffNumber: Record "Tariff Number";
    begin
        // Purpose of the test is to validate table 'Intra - form Buffer' can handle Tariff No.
        // field of maximum length defined by Tariff Number "No."
        TariffNumber.Init();
        TariffNumber."No." := PadStr(TariffNumber."No.", MaxStrLen(TariffNumber."No."), '9');
        TariffNumber.Insert();

        IntraFormBuffer."Tariff No." := TariffNumber."No.";
        IntraFormBuffer.TestField("Tariff No.", TariffNumber."No.");
    end;

    [Test]
    procedure IntrastatJnlLine_GetIntrastatCountryCode()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        CountryRegion2: Record "Country/Region";
    begin
        // [SCENARIO 423727] TAB 263 "Intrastat Jnl. Line".GetIntrastatCountryCode() reads company info in case of blanked country code
        Initialize();

        CountryRegion.Code := LibraryUtility.GenerateGUID();
        CountryRegion."Intrastat Code" := LibraryUtility.GenerateGUID();
        if CountryRegion.Insert() then;

        CountryRegion2.Code := LibraryUtility.GenerateGUID();
        CountryRegion2."Intrastat Code" := '';
        if CountryRegion2.Insert() then;

        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation.Modify();

        Assert.AreEqual(CountryRegion."Intrastat Code", IntrastatJnlLine.GetIntrastatCountryCode(CountryRegion.Code), '');
        Assert.AreEqual(CountryRegion."Intrastat Code", IntrastatJnlLine.GetIntrastatCountryCode(''), '');
        Assert.AreEqual(CountryRegion2.Code, IntrastatJnlLine.GetIntrastatCountryCode(CountryRegion2.Code), '');
    end;

    [Test]
    procedure IntrastatJnlLine_GetCountryOfOriginCode()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Item: Record Item;
    begin
        // [SCENARIO 424270] TAB 263 "Intrastat Jnl. Line".GetCountryOfOriginCode() in case of sales
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Country/Region of Origin Code" := LibraryUtility.GenerateGUID();
        Item.Modify();

        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        IntrastatJnlBatch.Validate(Type, IntrastatJnlBatch.Type::Sales);
        IntrastatJnlBatch.Modify();
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);

        IntrastatJnlLine.Validate("Item No.", Item."No.");

        Assert.AreEqual(Item."Country/Region of Origin Code", IntrastatJnlLine.GetCountryOfOriginCode, '');
    end;

    [Test]
    procedure ValidateSourceEntryNo_PurchaseLocal()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 423727] TAB 263 "Intrastat Jnl. Line".ValidateSourceEntryNo() in case of purchase source entry with local country/region code
        Initialize();

        CountryRegion.Code := LibraryUtility.GenerateGUID();
        CountryRegion."Intrastat Code" := LibraryUtility.GenerateGUID();
        if CountryRegion.Insert() then;

        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation.Modify();

        if VATEntry.FindLast() then;
        VATEntry."Entry No." += 1;
        VATEntry."Country/Region Code" := '';
        VATEntry.Type := VATEntry.Type::Purchase;
        if VATEntry.Insert() then;

        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.ValidateSourceEntryNo(VATEntry."Entry No.");
        IntrastatJnlLine.TestField("Country/Region of Payment Code", CountryRegion."Intrastat Code");
    end;

    [Test]
    procedure ValidateSourceEntryNo_Sales()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 423727] TAB 263 "Intrastat Jnl. Line".ValidateSourceEntryNo() in case of sales source entry
        Initialize();

        CountryRegion.Code := LibraryUtility.GenerateGUID();
        CountryRegion."Intrastat Code" := LibraryUtility.GenerateGUID();
        if CountryRegion.Insert() then;

        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryRegion.Code;
        CompanyInformation.Modify();

        if VATEntry.FindLast() then;
        VATEntry."Entry No." += 1;
        VATEntry."Country/Region Code" := '';
        VATEntry.Type := VATEntry.Type::Sale;
        if VATEntry.Insert() then;

        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.ValidateSourceEntryNo(VATEntry."Entry No.");
        IntrastatJnlLine.TestField("Country/Region of Payment Code", CountryRegion."Intrastat Code");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
    end;
}

