codeunit 144003 "BAS Calculation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [BAS Calculation]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        FuelTaxIsIncorrectErr: Label 'Fuel tax fields have been calculated incorrectly.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IncorrectAccBalanceErr: Label 'Incorrect G/L account balance after posting GST Settlement.';
        LabelsFileTxt: Label '_Labels';
        GLEntryNotFoundErr: Label 'G/L Entry with set filters is not found .';
        BasXmlFieldValidationErr: Label 'Field No. %1 has already been entered for XML Field ID %2.';
        BasXmlFieldIdMustExistErr: Label 'BAS XML Field ID must exist for XML field ID "%1" and BAS field No. %2.';
        BasXmlFieldIdSetupMustExistErr: Label 'BAS XML Field ID Setup must exist for XML field ID "%1" and BAS field No. %2.';
        YouCannotPreviewErr: Label 'You cannot preview a %1 %2.', Comment = '%1 - Consolidated field, %2 - BAS Calculation Sheet table';
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryAULocalization: Codeunit "Library - AU Localization";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('BasUpdateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateBAS_GLEntry()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        Initialize();

        CreateBASCalcSheetWith7CAnd7DSetup(DebitGLAcc, CreditGLAcc, BASCalculationSheet, false);
        Commit();

        RunBASUpdate(BASCalculationSheet);

        VerifyBasUpdate(DebitGLAcc, CreditGLAcc, BASCalculationSheet);

        Cleanup(BASCalculationSheet, DebitGLAcc."No.", CreditGLAcc."No.");
    end;

    [Test]
    [HandlerFunctions('BasUpdateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateBAS_GSTEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        BasSetupName: Code[20];
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        CreateMockVATEntry(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        BasSetupName := CreateBASGSTSetup(VATPostingSetup);
        CreateBasCalcSheet(BASCalculationSheet, BasSetupName, false);

        Commit();

        RunBASUpdate(BASCalculationSheet);

        BASCalculationSheet.Get(BASCalculationSheet.A1, BASCalculationSheet."BAS Version");
        VerifyVATEntryByVATPostingSetup(BASCalculationSheet."7C", VATPostingSetup);

        Cleanup(BASCalculationSheet, '', '');
    end;

    [Test]
    [HandlerFunctions('CalcGSTSettlementRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateGSTSettlement_GLEntry()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        PostedBalance: Decimal;
    begin
        Initialize();

        CreateBASCalcSheetWith7CAnd7DSetup(DebitGLAcc, CreditGLAcc, BASCalculationSheet, true);

        DebitGLAcc.CalcFields(Balance);
        CreditGLAcc.CalcFields(Balance);

        CreateMockBASCalcSheetEntry(BASCalculationSheet, BASCalculationSheet.FieldNo("7C"), DebitGLAcc."No.");
        CreateMockBASCalcSheetEntry(BASCalculationSheet, BASCalculationSheet.FieldNo("7D"), CreditGLAcc."No.");

        PostedBalance := RunCalculateGSTSettlement(BASCalculationSheet, true, false, '');

        Assert.AreEqual(DebitGLAcc.Balance + CreditGLAcc.Balance, PostedBalance, IncorrectAccBalanceErr);

        Cleanup(BASCalculationSheet, DebitGLAcc."No.", CreditGLAcc."No.");
    end;

    [Test]
    [HandlerFunctions('CalcGSTSettlementRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateGSTSettlement_BASDocNo()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        Initialize();

        CreateBASCalcSheetWith7CAnd7DSetup(DebitGLAcc, CreditGLAcc, BASCalculationSheet, true);

        CreateMockBASCalcSheetEntry(BASCalculationSheet, BASCalculationSheet.FieldNo("7C"), DebitGLAcc."No.");

        RunCalculateGSTSettlement(BASCalculationSheet, true, false, '');

        VerifyGLEntryBASDocNo(DebitGLAcc."No.", BASCalculationSheet.A1);

        Cleanup(BASCalculationSheet, DebitGLAcc."No.", CreditGLAcc."No.");
    end;

    [Test]
    [HandlerFunctions('CalcGSTSettlementRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateGSTSettlement_GSTEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        PostedBalance: Decimal;
    begin
        Initialize();

        CreateBASCalcSheetWithGSTSetup(VATPostingSetup, BASCalculationSheet, true);
        CreateMockVATEntry(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateMockBASCalcSheetEntryGST(
          BASCalculationSheet,
          BASCalculationSheet.FieldNo("7C"),
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group");

        PostedBalance := RunCalculateGSTSettlement(BASCalculationSheet, true, false, '');

        VerifyVATEntryByVATPostingSetup(PostedBalance, VATPostingSetup);

        Cleanup(BASCalculationSheet, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS355770_SameBasFieldCanBeInUsedDifferentSetup()
    var
        XmlFieldId: Text[80];
        BasFieldNo: Integer;
        I: Integer;
    begin
        InitializeBasXmlSetup(XmlFieldId, BasFieldNo);

        CreateBasXmlFieldId(XmlFieldId, BasFieldNo, 1);

        for I := 1 to 2 do
            CreateBasXmlFieldSetup(CreateBasXmlFieldSetupName, XmlFieldId, BasFieldNo, 1);

        VerifyBasXmlSetup(XmlFieldId, BasFieldNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS355770_SameBasFieldCannotBeInUsedOneSetup()
    var
        SetupName: Code[20];
        XmlFieldId: Text[80];
        BasFieldNo: Integer;
    begin
        InitializeBasXmlSetup(XmlFieldId, BasFieldNo);

        SetupName := CreateBasXmlFieldSetupName;
        CreateBasXmlFieldSetup(SetupName, XmlFieldId, BasFieldNo, 1);
        asserterror CreateBasXmlFieldSetup(SetupName, XmlFieldId, BasFieldNo, 1);

        Assert.ExpectedError(StrSubstNo(BasXmlFieldValidationErr, BasFieldNo, XmlFieldId));
    end;

    [Test]
    [HandlerFunctions('BASSetupPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure OpenBASSetupPreviewConsolidatedForGroupCompany()
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        BASSetupPage: TestPage "BAS Setup";
        BASSetupNameCode: Code[20];
    begin
        // [SCENARIO 375568] BAS Setup Preview should be opened for Consolidated BAS Calculation Sheet and BAS Group Company = Yes
        Initialize();

        // [GIVEN] GLSetup."BAS Group Company" is set to TRUE
        UpdateBASGroupCompanyOnGLSetup(true);

        // [GIVEN] Consolidated BAS Calculation Sheet for BASSetupName = "X"
        CreateBASCalcSheetConsolidated(BASCalculationSheet, BASSetupNameCode, true);

        // [GIVEN] BAS Setup page is opened
        RunBASSetupPage(BASSetupPage, BASSetupNameCode, BASCalculationSheet.A1, BASCalculationSheet."BAS Version");
        LibraryVariableStorage.Enqueue(BASSetupNameCode);

        // [WHEN] Run BAS Setup Preview action
        BASSetupPage.Preview.Invoke;

        // [THEN] BAS Setup Preview page is opened for BASSetupName = "X"
        // verification is done in BASSetupPreviewPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBASSetupPreviewConsolidated()
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        BASSetupPage: TestPage "BAS Setup";
        BASSetupNameCode: Code[20];
    begin
        // [SCENARIO 375568] BAS Setup Preview should generate an error when it is opened for Consolidated BAS Calculation Sheet and BAS Group Company = No
        Initialize();

        // [GIVEN] GLSetup."BAS Group Company" is set to FALSE
        UpdateBASGroupCompanyOnGLSetup(false);

        // [GIVEN] Consolidated BAS Calculation Sheet
        CreateBASCalcSheetConsolidated(BASCalculationSheet, BASSetupNameCode, true);

        // [GIVEN] BAS Setup page is opened
        RunBASSetupPage(BASSetupPage, BASSetupNameCode, BASCalculationSheet.A1, BASCalculationSheet."BAS Version");

        // [WHEN] Run BAS Setup Preview action
        asserterror BASSetupPage.Preview.Invoke;

        // [THEN] Error raised 'You cannot preview a Consolidated BAS Calculation Sheet'
        Assert.ExpectedError(
          StrSubstNo(YouCannotPreviewErr, BASCalculationSheet.FieldCaption(Consolidated), BASCalculationSheet.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('BASSetupPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure OpenBASSetupPreviewNotConsolidatedForGroupCompany()
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        BASSetupPage: TestPage "BAS Setup";
        BASSetupNameCode: Code[20];
    begin
        // [SCENARIO 375568] BAS Setup Preview should be opened for not Consolidated BAS Calculation Sheet and BAS Group Company = Yes
        Initialize();

        // [GIVEN] GLSetup."BAS Group Company" is set to TRUE
        UpdateBASGroupCompanyOnGLSetup(true);

        // [GIVEN] Not Consolidated BAS Calculation Sheet for BASSetupName = "X"
        CreateBASCalcSheetConsolidated(BASCalculationSheet, BASSetupNameCode, false);

        // [GIVEN] BAS Setup page is opened
        RunBASSetupPage(BASSetupPage, BASSetupNameCode, BASCalculationSheet.A1, BASCalculationSheet."BAS Version");
        LibraryVariableStorage.Enqueue(BASSetupNameCode);

        // [WHEN] Run BAS Setup Preview action
        BASSetupPage.Preview.Invoke;

        // [THEN] BAS Setup Preview page is opened for BASSetupName = "X"
        // verification is done in BASSetupPreviewPageHandler
    end;

    [Test]
    [HandlerFunctions('BASSetupPreviewPageHandler')]
    [Scope('OnPrem')]
    procedure OpenBASSetupPreviewNotConsolidated()
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        BASSetupPage: TestPage "BAS Setup";
        BASSetupNameCode: Code[20];
    begin
        // [SCENARIO 375568] BAS Setup Preview should be opened for not Consolidated BAS Calculation Sheet and BAS Group Company = No
        Initialize();

        // [GIVEN] GLSetup."BAS Group Company" is set to FALSE
        UpdateBASGroupCompanyOnGLSetup(false);

        // [GIVEN] Not Consolidated BAS Calculation Sheet for BASSetupName = "X"
        CreateBASCalcSheetConsolidated(BASCalculationSheet, BASSetupNameCode, false);

        // [GIVEN] BAS Setup page is opened
        RunBASSetupPage(BASSetupPage, BASSetupNameCode, BASCalculationSheet.A1, BASCalculationSheet."BAS Version");
        LibraryVariableStorage.Enqueue(BASSetupNameCode);

        // [WHEN] Run BAS Setup Preview action
        BASSetupPage.Preview.Invoke;

        // [THEN] BAS Setup Preview page is opened for BASSetupName = "X"
        // verification is done in BASSetupPreviewPageHandler
    end;

    [Test]
    [HandlerFunctions('CalcGSTSettlementRequestPageHandler,MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CalculateGSTSettlementWithInterCompanySetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        PostedBalance: Decimal;
    begin
        // [FEATURE] [GST] [Post] [Report]  [Intercompany]
        // [SCENARIO 268962] Stan can run "Calculate GST Settlement" with posting and intercompany
        Initialize();

        // [GIVEN] Australian GST is enabled in General Ledger Setup
        CreateBASCalcSheetWithGSTSetup(VATPostingSetup, BASCalculationSheet, true);
        // [GIVEN] General Journal batch with Intercompany template
        SetupIntercompanyGenJournalBatch;

        // [GIVEN] Posted VAT entry "V"
        CreateMockVATEntry(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        // [GIVEN] BAS Calculation entry representing "V"
        CreateMockBASCalcSheetEntryGST(
          BASCalculationSheet,
          BASCalculationSheet.FieldNo("7C"),
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group");

        // [WHEN] Run "Calculate GST Settlement" with "Post", "Intercompany" and "IC Partner" options
        PostedBalance := RunCalculateGSTSettlement(BASCalculationSheet, true, true, CreateICPartnerCode);

        // [THEN] Posted entries are balanced
        VerifyVATEntryByVATPostingSetup(PostedBalance, VATPostingSetup);

        Cleanup(BASCalculationSheet, '', '');
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryAULocalization.EnableGSTSetup(true, false);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
    end;

    local procedure DeleteGLAccount(AccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.DeleteAll();

        GLAccount.Get(AccNo);
        GLAccount.Delete();
    end;

    local procedure DeleteBasSetup(SetupName: Code[20])
    var
        BasSetup: Record "BAS Setup";
        BasSetupName: Record "BAS Setup Name";
    begin
        BasSetup.SetRange("Setup Name", SetupName);
        BasSetup.DeleteAll(true);

        BasSetupName.Get(SetupName);
        BasSetupName.Delete(true);
    end;

    local procedure DeleteBasCalcSheet(var BASCalculationSheet: Record "BAS Calculation Sheet")
    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
    begin
        with BASCalcSheetEntry do begin
            SetRange("BAS Document No.", BASCalculationSheet.A1);
            SetRange("BAS Version", BASCalculationSheet."BAS Version");
            DeleteAll(true);
        end;

        with BASCalculationSheet do begin
            Get(A1, "BAS Version");
            Delete(true);
        end;
    end;

    local procedure Cleanup(var BASCalculationSheet: Record "BAS Calculation Sheet"; DebitAccNo: Code[20]; CreditAccNo: Code[20])
    begin
        if DebitAccNo <> '' then
            DeleteGLAccount(DebitAccNo);
        if CreditAccNo <> '' then
            DeleteGLAccount(CreditAccNo);
        DeleteBasSetup(BASCalculationSheet."BAS Setup Name");
        DeleteBasCalcSheet(BASCalculationSheet);

        Erase(TemporaryPath + '\' + BASCalculationSheet."BAS Setup Name" + LabelsFileTxt + '.xml');
        Erase(TemporaryPath + '\' + BASCalculationSheet."BAS Setup Name" + '.xml');
    end;

    local procedure CreateBASCalcSheetWith7CAnd7DSetup(var DebitGLAcc: Record "G/L Account"; var CreditGLAcc: Record "G/L Account"; var BASCalculationSheet: Record "BAS Calculation Sheet"; CreateAsExported: Boolean)
    var
        BasSetupName: Code[20];
    begin
        CreateGLAccWithEntries(DebitGLAcc, CreditGLAcc);

        BasSetupName := CreateBasGLSetup(DebitGLAcc."No.", CreditGLAcc."No.");
        CreateBasCalcSheet(BASCalculationSheet, BasSetupName, CreateAsExported);
    end;

    local procedure CreateBASCalcSheetWithGSTSetup(var VATPostingSetup: Record "VAT Posting Setup"; var BASCalculationSheet: Record "BAS Calculation Sheet"; CreateAsExported: Boolean)
    var
        BasSetupName: Code[20];
    begin
        CreateVATPostingSetup(VATPostingSetup);

        BasSetupName := CreateBASGSTSetup(VATPostingSetup);
        CreateBasCalcSheet(BASCalculationSheet, BasSetupName, CreateAsExported);
    end;

    local procedure CreateBASCalcSheetConsolidated(var BASCalculationSheet: Record "BAS Calculation Sheet"; var BASSetupNameCode: Code[20]; IsConsolidated: Boolean)
    var
        BASSetup: Record "BAS Setup";
        BASSetupName: Record "BAS Setup Name";
    begin
        LibraryAPACLocalization.CreateBASSetupName(BASSetupName);
        LibraryAPACLocalization.CreateBASSetup(BASSetup, BASSetupName.Name);
        LibraryAPACLocalization.CreateBASCalculationSheet(BASCalculationSheet);
        BASCalculationSheet.Validate(Consolidated, IsConsolidated);
        BASCalculationSheet.Modify(true);
        BASSetupNameCode := BASSetupName.Name;
    end;

    local procedure CreateGLAccWithEntries(var DebitGLAcc: Record "G/L Account"; var CreditGLAcc: Record "G/L Account")
    begin
        CreateGLAccountICGLAccount(DebitGLAcc);
        CreateGLAccountICGLAccount(CreditGLAcc);

        CreateMockGLEntry(DebitGLAcc."No.", LibraryRandom.RandInt(10000));
        CreateMockGLEntry(CreditGLAcc."No.", LibraryRandom.RandInt(10000));
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        CreateGLAccountICGLAccount(GLAccount);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);

        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateMockGLEntry(AccountNo: Code[20]; Amt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            Init();
            Validate("Entry No.", FindNextGLEntryNo);
            Validate("G/L Account No.", AccountNo);
            Validate("Posting Date", WorkDate());
            Validate(Amount, Amt);

            Insert(true);
        end;
    end;

    local procedure CreateMockVATEntry(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            Validate("Entry No.", FindNextVATEntryNo);
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
            Validate(Type, Type::Sale);
            Validate(Base, LibraryRandom.RandInt(10000));
            Validate(Amount, LibraryRandom.RandInt(10000));
            Validate("Posting Date", WorkDate());

            Insert(true);
        end;
    end;

    local procedure CreateMockBASCalcSheetEntry(var BASCalculationSheet: Record "BAS Calculation Sheet"; BASCalcSheetFieldNo: Integer; GLAccNo: Code[20])
    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(BASCalculationSheet);
        FieldRef := RecRef.Field(BASCalcSheetFieldNo);

        GLEntry.SetRange("G/L Account No.", GLAccNo);
        if GLEntry.FindSet() then
            repeat
                InsertBASCalcSheetEntry(
                  BASCalcSheetEntry, BASCalculationSheet, FieldRef, GLEntry."Entry No.", GLEntry.Amount, BASCalcSheetEntry.Type::"G/L Entry");
            until GLEntry.Next() = 0;

        GLEntry.CalcSums(Amount);
        FieldRef.Value := GLEntry.Amount;
        RecRef.Modify();

        with BASCalculationSheet do
            Get(A1, "BAS Version");
    end;

    local procedure CreateMockBASCalcSheetEntryGST(var BASCalculationSheet: Record "BAS Calculation Sheet"; BASCalcSheetFieldNo: Integer; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
        VATEntry: Record "VAT Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(BASCalculationSheet);
        FieldRef := RecRef.Field(BASCalcSheetFieldNo);

        VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        if VATEntry.FindSet() then
            repeat
                InsertBASCalcSheetEntry(
                  BASCalcSheetEntry, BASCalculationSheet, FieldRef, VATEntry."Entry No.", VATEntry.Amount, BASCalcSheetEntry.Type::"GST Entry");
            until VATEntry.Next() = 0;

        VATEntry.CalcSums(Amount);
        FieldRef.Value := VATEntry.Amount;
        RecRef.Modify();

        with BASCalculationSheet do
            Get(A1, "BAS Version");
    end;

    local procedure CreateGLAccountICGLAccount(var GLAccount: Record "G/L Account")
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        ICGLAccount.Init();
        ICGLAccount."No." := GLAccount."No.";
        ICGLAccount."Map-to G/L Acc. No." := GLAccount."No.";
        ICGLAccount.Insert();
    end;

    local procedure CreateICPartnerCode(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Init();
        ICPartner.Code := LibraryUtility.GenerateRandomCode20(ICPartner.FieldNo(Code), DATABASE::"IC Partner");
        ICPartner.Insert();

        exit(ICPartner.Code);
    end;

    local procedure FindNextGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast() then
            exit(GLEntry."Entry No." + 1);

        exit(1);
    end;

    local procedure FindNextVATEntryNo(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntry.FindLast() then
            exit(VATEntry."Entry No." + 1);

        exit(1);
    end;

    local procedure CreateBasGLSetup(DebitGLAccNo: Code[20]; CreditGLAccNo: Code[20]): Code[20]
    var
        BasSetupName: Record "BAS Setup Name";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        SetupType: Option "Account Totaling","GST Entry Totaling","Row Totaling",Description;
        GenPostingType: Option " ",Purchase,Sale,Settlement;
    begin
        LibraryAPACLocalization.CreateBASSetupName(BasSetupName);

        InsertBasSetupField(
          BasSetupName.Name,
          BASCalculationSheet.FieldNo("7C"),
          SetupType::"Account Totaling",
          CreditGLAccNo,
          GenPostingType::" ",
          '',
          '');

        InsertBasSetupField(
          BasSetupName.Name,
          BASCalculationSheet.FieldNo("7D"),
          SetupType::"Account Totaling",
          DebitGLAccNo,
          GenPostingType::" ",
          '',
          '');

        exit(BasSetupName.Name);
    end;

    local procedure CreateBASGSTSetup(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        BasSetupName: Record "BAS Setup Name";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        SetupType: Option "Account Totaling","GST Entry Totaling","Row Totaling",Description;
        GenPostingType: Option " ",Purchase,Sale,Settlement;
    begin
        LibraryAPACLocalization.CreateBASSetupName(BasSetupName);

        InsertBasSetupField(
          BasSetupName.Name,
          BASCalculationSheet.FieldNo("7C"),
          SetupType::"GST Entry Totaling",
          '',
          GenPostingType::Sale,
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group");

        exit(BasSetupName.Name);
    end;

    local procedure InsertBasSetupField(BasSetupName: Code[20]; SetupFieldNo: Integer; SetupType: Option "Account Totaling","GST Entry Totaling","Row Totaling",Description; AccNo: Code[20]; GenPostingType: Option " ",Purchase,Sale,Settlement; GSTBusPostingGroupCode: Code[20]; GSTProdPostingGroupCode: Code[20])
    var
        BasSetup: Record "BAS Setup";
    begin
        with BasSetup do begin
            Validate("Setup Name", BasSetupName);
            Validate("Line No.", SetupFieldNo);
            Validate("Row No.", Format(SetupFieldNo));
            Validate("Field No.", SetupFieldNo);
            Validate(Type, SetupType);
            Validate("Account Totaling", AccNo);
            Validate("Gen. Posting Type", GenPostingType);
            Validate("GST Bus. Posting Group", GSTBusPostingGroupCode);
            Validate("GST Prod. Posting Group", GSTProdPostingGroupCode);
            Validate("Amount Type", "Amount Type"::Amount);
            Validate(Print, true);

            Insert(true);
        end;
    end;

    local procedure InsertBASCalcSheetEntry(var BASCalcSheetEntry: Record "BAS Calc. Sheet Entry"; BASCalculationSheet: Record "BAS Calculation Sheet"; FieldRef: FieldRef; EntryNo: Integer; EntryAmount: Decimal; EntryType: Option)
    begin
        with BASCalcSheetEntry do begin
            Validate("Company Name", CompanyName);
            Validate("BAS Document No.", BASCalculationSheet.A1);
            Validate("BAS Version", BASCalculationSheet."BAS Version");
            Validate("Field Label No.", FieldRef.Name);
            Validate(Type, EntryType);
            Validate("Entry No.", EntryNo);
            Validate("Amount Type", "Amount Type"::Amount);
            Validate(Amount, EntryAmount);

            Insert(true);
        end;
    end;

    local procedure CreateBasCalcSheet(var BASCalculationSheet: Record "BAS Calculation Sheet"; BasSetupName: Code[20]; CreateAsExported: Boolean)
    begin
        with BASCalculationSheet do begin
            Validate("BAS Version", 1);
            A1 := LibraryUtility.GenerateRandomCode(FieldNo(A1), DATABASE::"BAS Calculation Sheet");
            Validate(A3, WorkDate());
            Validate(A4, WorkDate());
            Validate("BAS Setup Name", BasSetupName);

            Validate(Updated, CreateAsExported);
            Validate(Exported, CreateAsExported);

            Insert(true);
        end;
    end;

    local procedure CalcBasFieldAmount(BasDocNo: Code[11]; BasVersion: Integer; FieldLabelNo: Text[30]): Decimal
    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
    begin
        with BASCalcSheetEntry do begin
            SetRange("Company Name", CompanyName);
            SetRange("BAS Document No.", BasDocNo);
            SetRange("BAS Version", BasVersion);
            SetRange("Field Label No.", FieldLabelNo);

            CalcSums(Amount);
            exit(Amount);
        end;
    end;

    local procedure GetFieldLabel(SetupFieldNo: Integer): Text[30]
    var
        "Field": Record "Field";
    begin
        with Field do begin
            SetRange(TableNo, DATABASE::"BAS Calculation Sheet");
            SetRange("No.", SetupFieldNo);
            FindFirst();

            exit(FieldName);
        end;
    end;

    local procedure SetupIntercompanyGenJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        GenJournalTemplate.DeleteAll();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Intercompany);
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure RunBASUpdate(BASCalculationSheet: Record "BAS Calculation Sheet")
    begin
        LibraryVariableStorage.Enqueue(BASCalculationSheet.A1);
        LibraryVariableStorage.Enqueue(BASCalculationSheet."BAS Version");
        REPORT.RunModal(REPORT::"BAS-Update");
    end;

    local procedure RunCalculateGSTSettlement(var BASCalculationSheet: Record "BAS Calculation Sheet"; DoPost: Boolean; InterCompany: Boolean; ICPartnerCode: Code[20]): Decimal
    var
        GLAccountSettlement: Record "G/L Account";
        GLAccountRounding: Record "G/L Account";
        CalcGSTSettlement: Report "Calculate GST Settlement";
    begin
        CreateGLAccountICGLAccount(GLAccountSettlement);
        CreateGLAccountICGLAccount(GLAccountRounding);

        with LibraryVariableStorage do begin
            Enqueue(GLAccountSettlement."No.");
            Enqueue(GLAccountRounding."No.");
            Enqueue(LibraryUtility.GenerateGUID());
            Enqueue(BASCalculationSheet."BAS Setup Name");
            Enqueue(DoPost);
            Enqueue(InterCompany);
            Enqueue(ICPartnerCode);
        end;

        with BASCalculationSheet do begin
            SetRange(A1, A1);
            SetRange("BAS Version", "BAS Version");
        end;

        Commit();

        CalcGSTSettlement.SetTableView(BASCalculationSheet);
        CalcGSTSettlement.RunModal();

        GLAccountSettlement.CalcFields(Balance);
        GLAccountRounding.CalcFields(Balance);

        exit(GLAccountSettlement.Balance + GLAccountRounding.Balance);
    end;

    local procedure RunBASSetupPage(var BASSetupPage: TestPage "BAS Setup"; BASSetupNameCode: Code[20]; A1: Code[11]; BASVersion: Integer)
    begin
        BASSetupPage.OpenView;
        BASSetupPage.CurrentBASSetupNameCtrl.SetValue(BASSetupNameCode);
        BASSetupPage.BASIdNoCtrl.SetValue(A1);
        BASSetupPage.BASVersionNoCtrl.SetValue(BASVersion);
    end;

    local procedure CreateBasXmlFieldId(XmlFieldId: Text[80]; BasFieldNo: Integer; LineNo: Integer)
    var
        BasXmlFieldId: Record "BAS XML Field ID";
    begin
        with BasXmlFieldId do begin
            Init();
            Validate("Line No.", LineNo);
            Validate("XML Field ID", XmlFieldId);
            Validate("Field No.", BasFieldNo);
            Insert(true);
        end;
    end;

    local procedure CreateBasXmlFieldSetupName(): Code[20]
    var
        BASXMLFieldSetupName: Record "BAS XML Field Setup Name";
    begin
        BASXMLFieldSetupName.Init();
        BASXMLFieldSetupName.Validate(Name, LibraryUtility.GenerateGUID());
        BASXMLFieldSetupName.Insert(true);
        exit(BASXMLFieldSetupName.Name);
    end;

    local procedure CreateBasXmlFieldSetup(SetupName: Code[20]; XmlFieldId: Text[80]; BasFieldNo: Integer; LineNo: Integer)
    var
        BASXMLFieldIDSetup: Record "BAS XML Field ID Setup";
    begin
        with BASXMLFieldIDSetup do begin
            Init();
            Validate("Setup Name", SetupName);
            Validate("Line No.", LineNo);
            Validate("XML Field ID", XmlFieldId);
            Validate("Field No.", BasFieldNo);
            Insert(true);
        end;
    end;

    local procedure GetRandomFieldNo(TblNo: Integer): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TblNo);
        Field.Next(LibraryRandom.RandInt(Field.Count - 1));
        exit(Field."No.");
    end;

    local procedure InitializeBasXmlSetup(var XmlFieldId: Text[80]; var BasFieldNo: Integer)
    var
        BASXMLFieldID: Record "BAS XML Field ID";
    begin
        BASXMLFieldID.DeleteAll();
        XmlFieldId := LibraryUtility.GenerateGUID();
        BasFieldNo := GetRandomFieldNo(DATABASE::"BAS Calculation Sheet");
    end;

    local procedure UpdateBASGroupCompanyOnGLSetup(BASGroupCompany: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."BAS Group Company" := BASGroupCompany;
        GLSetup.Modify();
    end;

    local procedure VerifyBasUpdate(var DebitGLAcc: Record "G/L Account"; var CreditGLAcc: Record "G/L Account"; var BASCalculationSheet: Record "BAS Calculation Sheet")
    begin
        DebitGLAcc.CalcFields(Balance);
        CreditGLAcc.CalcFields(Balance);
        with BASCalculationSheet do
            Assert.IsTrue(
              (CreditGLAcc.Balance = CalcBasFieldAmount(A1, "BAS Version", GetFieldLabel(FieldNo("7C")))) and
              (DebitGLAcc.Balance = CalcBasFieldAmount(A1, "BAS Version", GetFieldLabel(FieldNo("7D")))),
              FuelTaxIsIncorrectErr);
    end;

    local procedure VerifyGLEntryBASDocNo(GLAccNo: Code[20]; BASCalcSheetA1: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("G/L Account No.", GLAccNo);
            SetFilter("Document No.", '<>''''');
            SetRange("BAS Doc. No.", BASCalcSheetA1);
            Assert.IsFalse(IsEmpty, GLEntryNotFoundErr);
        end
    end;

    local procedure VerifyBasXmlSetup(XmlFieldId: Text[80]; BasFieldNo: Integer)
    begin
        VerifyFieldNoInDefaultBasXmlSetup(XmlFieldId, BasFieldNo);
        VerifyFieldNoInAllBasXmlSetup(XmlFieldId, BasFieldNo);
    end;

    local procedure VerifyFieldNoInDefaultBasXmlSetup(XmlFieldId: Text[80]; BasFieldNo: Integer)
    var
        BasXmlFieldId: Record "BAS XML Field ID";
    begin
        with BasXmlFieldId do begin
            SetRange("XML Field ID", XmlFieldId);
            SetRange("Field No.", BasFieldNo);
            Assert.IsFalse(IsEmpty, StrSubstNo(BasXmlFieldIdMustExistErr, XmlFieldId, Format(BasFieldNo)));
        end;
    end;

    local procedure VerifyFieldNoInAllBasXmlSetup(XmlFieldId: Text[80]; BasFieldNo: Integer)
    var
        BASXMLFieldSetupName: Record "BAS XML Field Setup Name";
        BASXMLFieldIDSetup: Record "BAS XML Field ID Setup";
    begin
        with BASXMLFieldIDSetup do begin
            BASXMLFieldSetupName.FindSet();
            repeat
                SetRange("Setup Name", BASXMLFieldSetupName.Name);
                SetRange("XML Field ID", XmlFieldId);
                SetRange("Field No.", BasFieldNo);
                Assert.IsFalse(IsEmpty, StrSubstNo(BasXmlFieldIdSetupMustExistErr, XmlFieldId, Format(BasFieldNo)));
            until BASXMLFieldSetupName.Next() = 0;
        end;
    end;

    local procedure VerifyVATEntryByVATPostingSetup(ExpectedAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.CalcSums(Amount);
        Assert.AreEqual(VATEntry.Amount, ExpectedAmount, IncorrectAccBalanceErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BasUpdateRequestPageHandler(var BASUpdate: TestRequestPage "BAS-Update")
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        A1: Variant;
        BASVersion: Variant;
    begin
        LibraryVariableStorage.Dequeue(A1);
        LibraryVariableStorage.Dequeue(BASVersion);
        BASCalculationSheet.Get(A1, BASVersion);

        BASUpdate."BASCalcSheet.A1".SetValue(A1);
        BASUpdate."BASCalcSheet.""BAS Version""".SetValue(BASVersion);
        BASUpdate."BASCalcSheet.A3".SetValue(WorkDate());
        BASUpdate."BASCalcSheet.A4".SetValue(WorkDate());
        BASUpdate.UpdateBASCalcSheet.SetValue(true);

        BASUpdate."BAS Setup".SetFilter("Setup Name", BASCalculationSheet."BAS Setup Name");

        BASUpdate.SaveAsXml(
          TemporaryPath + '\' + BASCalculationSheet."BAS Setup Name" + LabelsFileTxt + '.xml',
          TemporaryPath + '\' + BASCalculationSheet."BAS Setup Name" + '.xml');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcGSTSettlementRequestPageHandler(var CalcGSTSettlment: TestRequestPage "Calculate GST Settlement")
    var
        GLAccNo: Variant;
        DocumentNo: Variant;
        BasSetupName: Variant;
    begin
        with CalcGSTSettlment do begin
            AccType.SetValue(0);

            LibraryVariableStorage.Dequeue(GLAccNo);
            AccNo.SetValue(GLAccNo);

            LibraryVariableStorage.Dequeue(GLAccNo);
            RoundAccNo.SetValue(GLAccNo);

            LibraryVariableStorage.Dequeue(DocumentNo);
            LibraryVariableStorage.Dequeue(BasSetupName);

            PostDate.SetValue(WorkDate());
            DocNo.SetValue(DocumentNo);

            Post.SetValue(LibraryVariableStorage.DequeueBoolean);
            InterCompany.SetValue(LibraryVariableStorage.DequeueBoolean);
            ICPartnerCode.SetValue(LibraryVariableStorage.DequeueText);

            SaveAsXml(
              TemporaryPath + '\' + Format(BasSetupName) + LabelsFileTxt + '.xml',
              TemporaryPath + '\' + Format(BasSetupName) + '.xml');
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BASSetupPreviewPageHandler(var BASSetupPreview: TestPage "BAS Setup Preview")
    begin
        BASSetupPreview.Name.AssertEquals(LibraryVariableStorage.DequeueText);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

