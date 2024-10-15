codeunit 148184 "Sustainability Posting Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibrarySustainability: Codeunit "Library - Sustainability";
        LibraryRandom: Codeunit "Library - Random";
        InformationTakenToLedgerEntryLbl: Label '%1 on the Ledger Entry should be taken from %2', Locked = true;

    [Test]
    procedure TestInformationIsTransferredToLedgerEntry()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityAccount: Record "Sustainability Account";
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainAccountSubcategory: Record "Sustain. Account Subcategory";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
        SustainabilityPostMgt: Codeunit "Sustainability Post Mgt";
    begin
        // [SCENARIO] All information from Journal Line/Account/Category is transferred to the ledger Entry
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] A Sustainability Journal Batch and An Account that's ready to Post 
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);
        SustainabilityAccount := LibrarySustainability.GetAReadyToPostAccount();

        // [GIVEN] A Sustainability Journal Line is created and all fields are filled out
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(SustainabilityJnlBatch, SustainabilityAccount, 1000);
        SustainabilityJournalLine."Unit of Measure" := 'kg';
        SustainabilityJournalLine.Validate("Fuel/Electricity", 123);
        SustainabilityJournalLine.Modify(true);

        // [WHEN] A Ledger Entry is inserted basing on the Journal Line
        SustainabilityPostMgt.InsertLedgerEntry(SustainabilityJournalLine);
        SustainabilityLedgerEntry.FindFirst();

        // [THEN] All information from Journal Line is transferred to the ledger Entry
        Assert.AreEqual(WorkDate(), SustainabilityLedgerEntry."Posting Date", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Posting Date"), SustainabilityJournalLine.TableCaption()));
        Assert.AreEqual(SustainabilityAccount."No.", SustainabilityLedgerEntry."Account No.", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Account No."), SustainabilityJournalLine.TableCaption()));
        // [THEN] All information from Account is transferred to the ledger Entry
        Assert.AreEqual(SustainabilityAccount.Name, SustainabilityLedgerEntry."Account Name", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Account Name"), SustainabilityAccount.TableCaption()));
        Assert.AreEqual(SustainabilityAccount.Category, SustainabilityLedgerEntry."Account Category", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Account Category"), SustainabilityAccount.TableCaption()));
        Assert.AreEqual(SustainabilityAccount.Subcategory, SustainabilityLedgerEntry."Account Subcategory", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Account Subcategory"), SustainabilityAccount.TableCaption()));
        // [THEN] All information from Category is transferred to the ledger Entry
        SustainAccountCategory.Get(SustainabilityAccount.Category);
        Assert.AreEqual(SustainAccountCategory."Emission Scope", SustainabilityLedgerEntry."Emission Scope", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Scope"), SustainAccountCategory.TableCaption()));
        Assert.AreEqual(SustainAccountCategory."Calculation Foundation", SustainabilityLedgerEntry."Calculation Foundation", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Calculation Foundation"), SustainAccountCategory.TableCaption()));
        Assert.AreEqual(SustainAccountCategory.CO2, SustainabilityLedgerEntry.CO2, StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("CO2"), SustainAccountCategory.TableCaption()));
        Assert.AreEqual(SustainAccountCategory.CH4, SustainabilityLedgerEntry.CH4, StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("CH4"), SustainAccountCategory.TableCaption()));
        Assert.AreEqual(SustainAccountCategory.N2O, SustainabilityLedgerEntry.N2O, StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("N2O"), SustainAccountCategory.TableCaption()));
        // [THEN] All information from Subcategory is transferred to the ledger Entry
        SustainAccountSubcategory.Get(SustainabilityAccount.Category, SustainabilityAccount.Subcategory);
        Assert.AreEqual(SustainAccountSubcategory."Renewable Energy", SustainabilityLedgerEntry."Renewable Energy", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Renewable Energy"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(SustainAccountSubcategory."Emission Factor CO2", SustainabilityLedgerEntry."Emission Factor CO2", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor CO2"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(SustainAccountSubcategory."Emission Factor CH4", SustainabilityLedgerEntry."Emission Factor CH4", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor CH4"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(SustainAccountSubcategory."Emission Factor N2O", SustainabilityLedgerEntry."Emission Factor N2O", StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor N2O"), SustainAccountSubcategory.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure TestSustainabilityJournalPostedWithZeroEmissionWhenRenewableEnergyEnabled()
    var
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        NoSeries: Record "No. Series";
        SustainabilityAccount: Record "Sustainability Account";
        SustainAccountSubcategory: Record "Sustain. Account Subcategory";
        SustainabilityJournalLine: Record "Sustainability Jnl. Line";
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilityJournalMgt: Codeunit "Sustainability Journal Mgt.";
        SustainabilityJournal: TestPage "Sustainability Journal";
    begin
        // [SCENARIO 541991] Impossible to post an emission records in the Sustainability Ledger Entry with Emissions that are equal to zero even with the flag "Renewable Energy" set to true
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] A Sustainability Journal Batch and update No. Series so Manual No. allowed while posting the Sustainability Journal
        SustainabilityJnlBatch := SustainabilityJournalMgt.GetASustainabilityJournalBatch(false);
        NoSeries.Get(SustainabilityJnlBatch."No Series");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify(true);

        // [GIVEN] Create a Sustainability Account that's ready to Post 
        SustainabilityAccount := GetAReadyToPostSustainabilityAccount(
            Enum::"Emission Scope"::"Scope 2",
            Enum::"Calculation Foundation"::"Fuel/Electricity",
            true, false, false, '', false, 0, 0, 0, true);

        // [GIVEN] A Sustainability Journal Line is created and all fields are filled out
        SustainabilityJournalLine := LibrarySustainability.InsertSustainabilityJournalLine(SustainabilityJnlBatch, SustainabilityAccount, 1000);
        SustainabilityJournalLine."Unit of Measure" := 'kg';
        SustainabilityJournalLine.Validate("Fuel/Electricity", 123);
        SustainabilityJournalLine.Modify(true);

        // [WHEN] Post Sustainability Journal without any Error
        SustainabilityJournal.OpenEdit();
        SustainabilityJournal.GoToRecord(SustainabilityJournalLine);
        SustainabilityJournal.Post.Invoke();

        // [THEN] Verify Renewable Energy is true and Emissions are zero on posted Sustainability Ledger Entry
        SustainabilityLedgerEntry.FindFirst();
        SustainAccountSubcategory.Get(SustainabilityAccount.Category, SustainabilityAccount.Subcategory);
        Assert.AreEqual(
            SustainAccountSubcategory."Renewable Energy", SustainabilityLedgerEntry."Renewable Energy",
            StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Renewable Energy"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(
            SustainAccountSubcategory."Emission Factor CO2", SustainabilityLedgerEntry."Emission Factor CO2",
            StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor CO2"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(
            SustainAccountSubcategory."Emission Factor CH4", SustainabilityLedgerEntry."Emission Factor CH4",
            StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor CH4"), SustainAccountSubcategory.TableCaption()));
        Assert.AreEqual(
            SustainAccountSubcategory."Emission Factor N2O", SustainabilityLedgerEntry."Emission Factor N2O",
            StrSubstNo(InformationTakenToLedgerEntryLbl, SustainabilityLedgerEntry.FieldCaption("Emission Factor N2O"), SustainAccountSubcategory.TableCaption()));
    end;

    procedure GetAReadyToPostSustainabilityAccount(
        Scope: Enum "Emission Scope";
        CalcFoundation: Enum "Calculation Foundation";
        CO2: Boolean; CH4: Boolean; N2O: Boolean;
        CustomValue: Text[100]; CalcFromGL: Boolean;
        EFCO2: Decimal; EFCH4: Decimal; EFN2O: Decimal; RenewableEnergy: Boolean) Account: Record "Sustainability Account"
    var
        CategoryTok, SubcategoryTok, AccountTok : Code[20];
    begin
        CategoryTok := LibraryRandom.RandText(20);
        SubcategoryTok := LibraryRandom.RandText(20);
        AccountTok := Format(LibraryRandom.RandIntInRange(10000, 20000));
        LibrarySustainability.InsertAccountCategory(CategoryTok, '', Scope, CalcFoundation, CO2, CH4, N2O, CustomValue, CalcFromGL);
        LibrarySustainability.InsertAccountSubcategory(CategoryTok, SubcategoryTok, '', EFCO2, EFCH4, EFN2O, RenewableEnergy);
        Account := LibrarySustainability.InsertSustainabilityAccount(
            AccountTok, LibraryRandom.RandText(20), CategoryTok, SubcategoryTok, Enum::"Sustainability Account Type"::Posting, '', true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}