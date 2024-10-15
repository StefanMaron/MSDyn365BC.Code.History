codeunit 134832 "Alloc. Acc. Jounral E2E Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        TestProxyNotifMgtExt: Codeunit "Test Proxy Notif. Mgt. Ext.";
        Any: Codeunit Any;
        Assert: Codeunit Assert;
        Initialized: Boolean;

    local procedure Initialize()
    var
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AllocationAccount.DeleteAll();
        GenJournalLine.DeleteAll();
        AllocAccManualOverride.DeleteAll();
        LibraryVariableStorage.Clear();

        if Initialized then
            exit;

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        BindSubscription(TestProxyNotifMgtExt);
        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    procedure TestAllocateToDifferentAccountsVariableGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocationAccountPage: TestPage "Allocation Account";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, ThirdDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries created for the first destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        GLEntry.SetRange("G/L Account No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        GLEntry.SetRange("G/L Account No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    procedure TestAllocationWithCreditAmountVariableGLAllocation()
    var
        AllocationAccount: Record "Allocation Account";
        AllocationLine: Record "Allocation Line";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        GLAccountNo: array[2] of Code[20];
        BreakdownGLAccountNo: array[2] of Code[20];
        PostedAmount: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 533958] Test variable allocation with credit (negative) amount
        Initialize();

        // [GIVEN] Create Allocation Account "X" with variable GL distributions
        AllocationAccount := CreateAllocationAccountWithVariableDistribution();

        // [GIVEN] Create two G/L Accounts "X" and "Y" with direct posting 
        // [GIVEN] Create two G/L Accounts "M" and "N" with direct posting with negative balance
        // [GIVEN] Create and post General Journal line: Gen. Journal Batch "X", G/L Account "M", amount is negative
        // [GIVEN] Create and post General Journal line: Gen. Journal Batch "X", G/L Account "N", amount is negative
        // [GIVEN] Create two Allocation Account Distribution Lines:
        // [GIVEN] All. Acc. Distribution Line 1: Allocation Account = "X", G/L Account "X", Breakdown Account "M"
        // [GIVEN] All. Acc. Distribution Line 2: Allocation Account = "X", G/L Account "Y", Breakdown Account "N"
        for i := 1 to ArrayLen(GLAccountNo) do begin
            GLAccountNo[i] := LibraryERM.CreateGLAccountNoWithDirectPosting();
            BreakdownGLAccountNo[i] := LibraryERM.CreateGLAccountNoWithDirectPosting();
            CreateBalanceForGLAccount(-Random(100), BreakdownGLAccountNo[i], 0);
            CreateAllocationAccountDistributionLine(AllocationAccount."No.", GLAccountNo[i], BreakdownGLAccountNo[i]);
        end;

        // [WHEN] Test allocation calculation on allocation lines, amount to distribute = 1000
        AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, 1000, WorkDate(), 0, '');

        // [THEN] The amount and percentage on created Allocation Lines is calculated correctly
        for i := 1 to ArrayLen(PostedAmount) do
            PostedAmount[i] := GetPostedAmount(BreakdownGLAccountNo[i]);

        VerifyAllocationLine(AllocationLine, AllocationAccount."No.", PostedAmount[1], PostedAmount[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountDifferentDimensionsVariableGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateBalancingAccountVariableGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.", DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
#pragma warning disable AA0210
        GLEntry.SetRange("Bal. Account No.", DestinationGLAccount."No.");
#pragma warning restore AA0210
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        GeneralJournalPage.RedistributeAccAllocations.Invoke();

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocationIsDeletedIfLineChanged()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
        NewAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithVariableGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);
        GeneralJournalPage.RedistributeAccAllocations.Invoke();
        Assert.IsFalse(AllocAccManualOverride.IsEmpty(), 'The manual override was not created');

        // [WHEN] The General Journal line is modified
        NewAmount := Round(GetLineAmountToForceRounding() / 2, 0.01);
        GeneralJournalPage.Amount.SetValue(NewAmount);

        // [THEN] Manual overrides are deleted
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');

        // [WHEN] The General Journal line is posted without overrides
        GeneralJournalPage.Post.Invoke();

        // [THEN] Regular values are used
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(NewAmount / 6, GLEntry.Amount, 'The new amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(NewAmount / 3, GLEntry.Amount, 'The new amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(NewAmount, PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountFixedGLAllocation()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        CreateAllocationAccountwithFixedGLDistributions(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, DestinationGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"Allocation Account", AllocationAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first line');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second line');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third line');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    procedure TestAllocateToDifferentAccountsInheritFromParentVariableGLAllocation()
    var
        FirstDestinationGLAccount: Record "G/L Account";
        SecondDestinationGLAccount: Record "G/L Account";
        ThirdDestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocationAccountPage: TestPage "Allocation Account";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] Three GL accounts with dimensions and balances, one Balancing G/L Account and three Destination G/L Accounts
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        FirstDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        SecondDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        ThirdDestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions
        AllocationAccount.Get(CreateAllocationAccountWithVariableDistribution(AllocationAccountPage));
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, FirstDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, SecondDestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        AllocationAccountPage.Close();

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", ThirdDestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        GeneralJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        Commit();
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", FirstDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries created for the first destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        GLEntry.SetRange("G/L Account No.", SecondDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        GLEntry.SetRange("G/L Account No.", ThirdDestinationGLAccount."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second destination account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestAllocateToSameAccountDifferentDimensionsVariableGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        GeneralJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage,OverrideGLDistributions')]
    procedure TestOverrideGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        GeneralJournalPage: TestPage "General Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The General Journal line with Allocation Account
        CreateLineOnGeneralJournal(DocumentNumber, GeneralJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        GeneralJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);

        // [WHEN] We invoke the override action
        GeneralJournalPage.RedistributeAccAllocations.Invoke();

        // [THEN] The override lines are created with parent account replaced with the account that is defined on the line
        AllocAccManualOverride.SetRange("Allocation Account No.", AllocationAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Override lines were not created correctly');
        AllocAccManualOverride.SetRange("Destination Account Number", DestinationGLAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Destination account was not replaced correctly');

        // [WHEN] The General Journal line is posted
        GeneralJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestSalesJournalInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        SalesJournalPage: TestPage "Sales Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Journal line with Allocation Account
        CreateLineOnSalesJournal(DocumentNumber, SalesJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        SalesJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        SalesJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,HandleEditDimensionSetEntriesPage,GeneralJournalTemplateHandler,OverrideGLDistributions')]
    procedure TestSalesJournalOverrideGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        SalesJournalPage: TestPage "Sales Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Sales Journal line with Allocation Account
        CreateLineOnSalesJournal(DocumentNumber, SalesJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        SalesJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);

        // [WHEN] We invoke the override action
        SalesJournalPage.RedistributeAccAllocations.Invoke();

        // [THEN] The override lines are created with parent account replaced with the account that is defined on the line
        AllocAccManualOverride.SetRange("Allocation Account No.", AllocationAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Override lines were not created correctly');
        AllocAccManualOverride.SetRange("Destination Account Number", DestinationGLAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Destination account was not replaced correctly');

        // [WHEN] The Sales Journal is posted
        SalesJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestPurcahseJournalInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        PurchaseJournalPage: TestPage "Purchase Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Journal line with Allocation Account
        CreateLineOnPurchaseJournal(DocumentNumber, PurchaseJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        PurchaseJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        PurchaseJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,HandleEditDimensionSetEntriesPage,GeneralJournalTemplateHandler,OverrideGLDistributions')]
    procedure TestPurchaseJournalOverrideGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        PurchaseJournalPage: TestPage "Purchase Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Purchase Journal line with Allocation Account
        CreateLineOnPurchaseJournal(DocumentNumber, PurchaseJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        PurchaseJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);

        // [WHEN] We invoke the override action
        PurchaseJournalPage.RedistributeAccAllocations.Invoke();

        // [THEN] The override lines are created with parent account replaced with the account that is defined on the line
        AllocAccManualOverride.SetRange("Allocation Account No.", AllocationAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Override lines were not created correctly');
        AllocAccManualOverride.SetRange("Destination Account Number", DestinationGLAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Destination account was not replaced correctly');

        // [WHEN] The Purchase Journal is posted
        PurchaseJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler,HandleEditDimensionSetEntriesPage')]
    procedure TestCashReceiptJournalInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        CashReceiptJournalPage: TestPage "Cash Receipt Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Cash Receipt Journal line with Allocation Account
        CreateLineOnCashReceiptJournal(DocumentNumber, CashReceiptJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        CashReceiptJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [WHEN] The General Journal line is posted
        CashReceiptJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        FirstDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(FirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 6);
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(SecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 3);
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(ThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        VerifyGLEntryAmount(GLEntry, GetLineAmountToForceRounding(), 2);
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,HandleEditDimensionSetEntriesPage,GeneralJournalTemplateHandler,OverrideGLDistributions')]
    procedure TestCashReceiptJournalOverrideGLAllocationInheritFromParent()
    var
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        OverrideFirstDimensionValue: Record "Dimension Value";
        OverrideSecondDimensionValue: Record "Dimension Value";
        OverrideThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account";
        BalancingGLAccount: Record "G/L Account";
        DummyGenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        GLEntry: Record "G/L Entry";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        CashReceiptJournalPage: TestPage "Cash Receipt Journal";
        DocumentNumber: Code[10];
        PostedAmount: Decimal;
    begin
        Initialize();

        // [GIVEN] A dimension that is defined as a department with three values
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue);
        CreateDimensionsWithValues(OverrideFirstDimensionValue, OverrideSecondDimensionValue, OverrideThirdDimensionValue);

        // [GIVEN] Three GL accounts with dimensions and balances and one Balancing G/L Account
        CreateBreakdownAccountsWithBalances(FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);
        DestinationGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        BalancingGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] An Allocation Account with variable GL distributions and thre inherit from parent values
        CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(AllocationAccount, FirstDimensionValue, SecondDimensionValue, ThirdDimensionValue, FirstBreakdownGLAccount, SecondBreakdownGLAccount, ThirdBreakdownGLAccount);

        // [GIVEN] The Cash Receipt Journal line with Allocation Account
        CreateLineOnCashReceiptJournal(DocumentNumber, CashReceiptJournalPage, DummyGenJournalLine."Account Type"::"G/L Account", DestinationGLAccount."No.", DummyGenJournalLine."Bal. Account Type"::"G/L Account", BalancingGLAccount."No.");
        CashReceiptJournalPage."Allocation Account No.".SetValue(AllocationAccount."No.");

        // [GIVEN] User defines an override manually
        LibraryVariableStorage.Enqueue(GetLineAmountToForceRounding());
        LibraryVariableStorage.Enqueue(OverrideFirstDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideSecondDimensionValue.SystemId);
        LibraryVariableStorage.Enqueue(OverrideThirdDimensionValue.SystemId);

        // [WHEN] We invoke the override action
        CashReceiptJournalPage.RedistributeAccAllocations.Invoke();

        // [THEN] The override lines are created with parent account replaced with the account that is defined on the line
        AllocAccManualOverride.SetRange("Allocation Account No.", AllocationAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Override lines were not created correctly');
        AllocAccManualOverride.SetRange("Destination Account Number", DestinationGLAccount."No.");
        Assert.AreEqual(3, AllocAccManualOverride.Count(), 'Destination account was not replaced correctly');

        // [WHEN] The Cash Receipt Journal is posted
        CashReceiptJournalPage.Post.Invoke();

        // [THEN] The costs are split into mulitple ledger entries which has the same dimension code
        GLEntry.SetRange("Document No.", DocumentNumber);
        GLEntry.SetRange("G/L Account No.", DestinationGLAccount."No.");
        Assert.AreEqual(3, GLEntry.Count(), 'Wrong number of G/L Entries created for the destination account');

        // [THEN] Override values are used
        FirstDimensionValue.SetRecFilter();
        OverrideFirstDimensionValue.SetFilter(SystemId, '%1|%2', FirstDimensionValue.SystemId, OverrideFirstDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideFirstDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the first breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount := GLEntry.Amount;

        SecondDimensionValue.SetRecFilter();
        OverrideSecondDimensionValue.SetFilter(SystemId, '%1|%2', SecondDimensionValue.SystemId, OverrideSecondDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideSecondDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the second breakdown account');
        GLEntry.FindFirst();
        Assert.AreEqual(GetOverrideAmount(), GLEntry.Amount, 'The override amount was not used');
        PostedAmount += GLEntry.Amount;

        ThirdDimensionValue.SetRecFilter();
        OverrideThirdDimensionValue.SetFilter(SystemId, '%1|%2', ThirdDimensionValue.SystemId, OverrideThirdDimensionValue.SystemId);
        GLEntry.SetRange("Dimension Set ID", CreateDimensionSetID(OverrideThirdDimensionValue));
        Assert.AreEqual(1, GLEntry.Count(), 'Wrong number of G/L Entries for the third breakdown account');
        GLEntry.FindFirst();
        PostedAmount += GLEntry.Amount;

        Assert.AreEqual(GetLineAmountToForceRounding(), PostedAmount, 'The rounding amount was not distributed correctly');
        Assert.IsTrue(AllocAccManualOverride.IsEmpty(), 'The manual override was not deleted');
    end;

    local procedure CreateLineOnCashReceiptJournal(var DocumentNumber: Code[10]; var CashReceiptJournalPage: TestPage "Cash Receipt Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                         BalancingAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                         BalancingAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::"Cash Receipts");
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::"Cash Receipts");
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        CashReceiptJournalPage.OpenEdit();
#pragma warning disable AA0139
        DocumentNumber := Any.AlphanumericText(10);
#pragma warning restore AA0139
        CashReceiptJournalPage."Document No.".SetValue(DocumentNumber);
        CashReceiptJournalPage."Account Type".SetValue(AccountType);
        CashReceiptJournalPage."Account No.".SetValue(AccountNo);
        CashReceiptJournalPage.Description.SetValue(DocumentNumber);
        CashReceiptJournalPage.Amount.SetValue(GetLineAmountToForceRounding());
        CashReceiptJournalPage."Bal. Account Type".SetValue(BalancingAccountType);
        CashReceiptJournalPage."Bal. Account No.".SetValue(BalancingAccountNo);
    end;

    local procedure CreateLineOnPaymentJournal(var DocumentNumber: Code[10]; var PaymentJournalPage: TestPage "Payment Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                  BalancingAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                  BalancingAccountNo: Code[20])

    begin
        PaymentJournalPage.OpenEdit();
#pragma warning disable AA0139
        DocumentNumber := Any.AlphanumericText(10);
#pragma warning restore AA0139
        PaymentJournalPage."Document No.".SetValue(DocumentNumber);
        PaymentJournalPage."Account Type".SetValue(AccountType);
        PaymentJournalPage."Account No.".SetValue(AccountNo);
        PaymentJournalPage.Description.SetValue(DocumentNumber);
        PaymentJournalPage.Amount.SetValue(GetLineAmountToForceRounding());
        PaymentJournalPage."Bal. Account Type".SetValue(BalancingAccountType);
        PaymentJournalPage."Bal. Account No.".SetValue(BalancingAccountNo);
    end;

    local procedure CreateLineOnSalesJournal(var DocumentNumber: Code[10]; var SalesJournalPage: TestPage "Sales Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                     BalancingAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                     BalancingAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::Sales);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::Sales);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        SalesJournalPage.OpenEdit();
#pragma warning disable AA0139
        DocumentNumber := Any.AlphanumericText(10);
#pragma warning restore AA0139
        SalesJournalPage."Document No.".SetValue(DocumentNumber);
        SalesJournalPage."Account Type".SetValue(AccountType);
        SalesJournalPage."Account No.".SetValue(AccountNo);
        SalesJournalPage.Description.SetValue(DocumentNumber);
        SalesJournalPage.Amount.SetValue(GetLineAmountToForceRounding());
        SalesJournalPage."Bal. Account Type".SetValue(BalancingAccountType);
        SalesJournalPage."Bal. Account No.".SetValue(BalancingAccountNo);
    end;

    local procedure CreateLineOnPurchaseJournal(var DocumentNumber: Code[10]; var PurchaseJournalPage: TestPage "Purchase Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                   BalancingAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                   BalancingAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::Purchases);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::Purchases);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        PurchaseJournalPage.OpenEdit();
#pragma warning disable AA0139
        DocumentNumber := Any.AlphanumericText(10);
#pragma warning restore AA0139
        PurchaseJournalPage."Document No.".SetValue(DocumentNumber);
        PurchaseJournalPage."Account Type".SetValue(AccountType);
        PurchaseJournalPage."Account No.".SetValue(AccountNo);
        PurchaseJournalPage.Description.SetValue(DocumentNumber);
        PurchaseJournalPage.Amount.SetValue(GetLineAmountToForceRounding());
        PurchaseJournalPage."Bal. Account Type".SetValue(BalancingAccountType);
        PurchaseJournalPage."Bal. Account No.".SetValue(BalancingAccountNo);
    end;

    local procedure CreateLineOnGeneralJournal(var DocumentNumber: Code[10]; var GeneralJournalPage: TestPage "General Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                                  BalancingAccountType: Enum "Gen. Journal Account Type";
                                                                                                                                                  BalancingAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GeneralJournalPage.OpenEdit();
#pragma warning disable AA0139
        DocumentNumber := Any.AlphanumericText(10);
#pragma warning restore AA0139
        GeneralJournalPage."Document No.".SetValue(DocumentNumber);
        GeneralJournalPage."Account Type".SetValue(AccountType);
        GeneralJournalPage."Account No.".SetValue(AccountNo);
        GeneralJournalPage.Description.SetValue(DocumentNumber);
        GeneralJournalPage.Amount.SetValue(GetLineAmountToForceRounding());
        GeneralJournalPage."Bal. Account Type".SetValue(BalancingAccountType);
        GeneralJournalPage."Bal. Account No.".SetValue(BalancingAccountNo);
    end;

    local procedure GetLineAmountToForceRounding(): Decimal
    begin
        exit(1025.27)
    end;

    local procedure CreateAllocationAccountwithFixedGLDistributions(
       var AllocationAccount: Record "Allocation Account";
       FirstDimensionValue: Record "Dimension Value";
       SecondDimensionValue: Record "Dimension Value";
       ThirdDimensionValue: Record "Dimension Value";
       DestinationGLAccount: Record "G/L Account"
   )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(100);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(200);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, DestinationGLAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(300);
        SetDimensionToCurrentFixedLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountwithVariableGLDistributions(
        var AllocationAccount: Record "Allocation Account";
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        DestinationGLAccount: Record "G/L Account";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account"
    )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        VariableAllocationAccountCode: Code[20];
    begin
        VariableAllocationAccountCode := CreateAllocationAccountWithVariableDistribution(AllocationAccountPage);
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddGLDestinationAccountForVariableDistribution(AllocationAccountPage, DestinationGLAccount);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(VariableAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountwithVariableGLDistributionsAndInheritFromParent(
        var AllocationAccount: Record "Allocation Account";
        FirstDimensionValue: Record "Dimension Value";
        SecondDimensionValue: Record "Dimension Value";
        ThirdDimensionValue: Record "Dimension Value";
        FirstBreakdownGLAccount: Record "G/L Account";
        SecondBreakdownGLAccount: Record "G/L Account";
        ThirdBreakdownGLAccount: Record "G/L Account"
    )
    var
        AllocationAccountPage: TestPage "Allocation Account";
        VariableAllocationAccountCode: Code[20];
    begin
        VariableAllocationAccountCode := CreateAllocationAccountWithVariableDistribution(AllocationAccountPage);
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, FirstBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, FirstDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, SecondBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, SecondDimensionValue);

        AllocationAccountPage.VariableAccountDistribution.New();
        AddInheritFromParentForVariableDistribution(AllocationAccountPage);
        AddGLBreakdownAccountForVariableDistribution(AllocationAccountPage, ThirdBreakdownGLAccount);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, ThirdDimensionValue);
        AllocationAccountPage.Close();

        AllocationAccount.Get(VariableAllocationAccountCode);
    end;

    local procedure AddInheritFromParentForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocationAccountPage.VariableAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
    end;

    local procedure AddGLDestinationAccountForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        AllocationAccountPage.VariableAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.VariableAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure CreateAllocationAccountWithVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
#pragma warning disable AA0139
        AllocationAccountNo := Any.AlphanumericText(MaxStrLen(DummyAllocationAccount."No."));
#pragma warning restore AA0139

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Variable);
        AllocationAccountPage.Name.SetValue(Any.AlphabeticText(MaxStrLen(DummyAllocationAccount.Name)));
        exit(AllocationAccountNo);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();
#pragma warning disable AA0139
        AllocationAccountNo := Any.AlphanumericText(MaxStrLen(DummyAllocationAccount."No."));
#pragma warning restore AA0139

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Fixed);
        AllocationAccountPage.Name.SetValue(Any.AlphabeticText(MaxStrLen(DummyAllocationAccount.Name)));
        exit(AllocationAccountNo);
    end;

    local procedure AddGLDestinationAccountForFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure SetDimensionToCurrentFixedLine(var AllocationAcccount: TestPage "Allocation Account"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(DimensionValue.SystemId);
        AllocationAcccount.FixedAccountDistribution.Dimensions.Invoke();
    end;

    local procedure AddGLBreakdownAccountForVariableDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocationAccountPage.VariableAccountDistribution."Breakdown Account Type".SetValue(DummyAllocAccountDistribution."Breakdown Account Type"::"G/L Account");
        AllocationAccountPage.VariableAccountDistribution."Breakdown Account Number".SetValue(GLAccount."No.");
    end;

    local procedure VerifyGLEntryAmount(var GLEntry: Record "G/L Entry"; ExpectedAmount: Decimal; Division: Integer)
    begin
        Assert.IsTrue((ExpectedAmount / Division + 0.01) >= GLEntry.Amount, 'The G/L Entry amount is too high');
        Assert.IsTrue((ExpectedAmount / Division - 0.01) <= GLEntry.Amount, 'The G/L Entry amount is too low');
    end;

    local procedure CreateBreakdownAccountsWithBalances(var FirstBreakdownGLAccount: Record "G/L Account"; var SecondBreakdownGLAccount: Record "G/L Account"; var ThirdBreakdownGLAccount: Record "G/L Account")
    begin
        FirstBreakdownGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        CreateBalanceForGLAccount(100, FirstBreakdownGLAccount."No.", 0);

        SecondBreakdownGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        CreateBalanceForGLAccount(200, SecondBreakdownGLAccount."No.", 0);

        ThirdBreakdownGLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        CreateBalanceForGLAccount(300, ThirdBreakdownGLAccount."No.", 0);
    end;

    local procedure CreateBalanceForGLAccount(Balance: Decimal; GLAccountNo: Code[20]; DimensionSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, Balance);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Dimension Set ID", DimensionSetID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateDimensionSetID(var DimensionValue: Record "Dimension Value"): Integer
    var
        DimSetID: Integer;
    begin
        DimensionValue.FindSet();

        repeat
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        until DimensionValue.Next() = 0;

        exit(DimSetID);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplateType::General);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Income Statement";
        GLAccount.Modify(true);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure SetDimensionToCurrentVariableLine(var AllocationAcccount: TestPage "Allocation Account"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(DimensionValue.SystemId);
        AllocationAcccount.VariableAccountDistribution.Dimensions.Invoke();
    end;

    local procedure CreateDimensionsWithValues(var FirstDimensionValue: Record "Dimension Value"; var SecondDimensionValue: Record "Dimension Value"; var ThirdDimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(FirstDimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(SecondDimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(ThirdDimensionValue, Dimension.Code);
    end;

    local procedure VerifyAllocationLine(var AllocationLine: Record "Allocation Line"; AllocationAccountNo: Code[20]; PostedAmount1: Decimal; PostedAmount2: Decimal)
    var
        TotalPostedAmount: Decimal;
        AmountRoundingPrecision: Decimal;
        TestAllocationErr: Label 'Allocation account calculation is not correct.', Locked = true;
    begin
        TotalPostedAmount := PostedAmount1 + PostedAmount2;

        AllocationLine.SetLoadFields(Amount, Percentage);
        AllocationLine.SetRange("Allocation Account No.", AllocationAccountNo);
        AllocationLine.FindSet();

        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreEqual(Round(PostedAmount1 * 1000 / TotalPostedAmount, AmountRoundingPrecision), Round(AllocationLine.Amount, AmountRoundingPrecision), TestAllocationErr);
        Assert.AreEqual(Round(PostedAmount1 * 100 / TotalPostedAmount, AmountRoundingPrecision), Round(AllocationLine.Percentage, AmountRoundingPrecision), TestAllocationErr);
        AllocationLine.Next();
        Assert.AreEqual(Round(PostedAmount2 * 1000 / TotalPostedAmount, AmountRoundingPrecision), Round(AllocationLine.Amount, AmountRoundingPrecision), TestAllocationErr);
        Assert.AreEqual(Round(PostedAmount2 * 100 / TotalPostedAmount, AmountRoundingPrecision), Round(AllocationLine.Percentage, AmountRoundingPrecision), TestAllocationErr);
    end;

    local procedure GetPostedAmount(GLAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetLoadFields(Amount);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        exit(GLEntry.Amount);
    end;

    local procedure CreateAllocationAccountWithVariableDistribution() AllocationAccount: Record "Allocation Account"
    begin
#pragma warning disable AA0139
        AllocationAccount."No." := Any.AlphabeticText(MaxStrLen(AllocationAccount."No."));
#pragma warning restore AA0139
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Variable;
        AllocationAccount.Name := AllocationAccount."No.";
        AllocationAccount.Insert();
    end;

    local procedure CreateAllocationAccountDistributionLine(AllocationAccountNo: Code[20]; GLAccountNo: Code[20]; BreakdownGLAccountNo: Code[20])
    var
        AllocationAccountDistribution: Record "Alloc. Account Distribution";
        RecRef: RecordRef;
    begin
        AllocationAccountDistribution."Allocation Account No." := AllocationAccountNo;
        RecRef.GetTable(AllocationAccountDistribution);
        AllocationAccountDistribution."Line No." := LibraryUtility.GetNewLineNo(RecRef, AllocationAccountDistribution.FieldNo("Line No."));
        AllocationAccountDistribution."Account Type" := AllocationAccountDistribution."Account Type"::Variable;
        AllocationAccountDistribution."Destination Account Type" := AllocationAccountDistribution."Destination Account Type"::"G/L Account";
        AllocationAccountDistribution."Destination Account Number" := GLAccountNo;
        AllocationAccountDistribution."Breakdown Account Type" := AllocationAccountDistribution."Breakdown Account Type"::"G/L Account";
        AllocationAccountDistribution."Breakdown Account Number" := BreakdownGLAccountNo;
        AllocationAccountDistribution.Insert();
    end;

    local procedure GetOverrideAmount(): Decimal
    begin
        exit(100.11);
    end;

    [ModalPageHandler]
    procedure HandleEditDimensionSetEntriesPage(var EditDimensionSetEntriesPage: TestPage "Edit Dimension Set Entries")
    var
        DimensionValue: Record "Dimension Value";
        DimensionValueSystemId: Text;
    begin
        DimensionValueSystemId := LibraryVariableStorage.DequeueText();
        DimensionValue.GetBySystemId(DimensionValueSystemId);
        EditDimensionSetEntriesPage.New();
        EditDimensionSetEntriesPage."Dimension Code".SetValue(DimensionValue."Dimension Code");
        EditDimensionSetEntriesPage.DimensionValueCode.SetValue(DimensionValue.Code);
        EditDimensionSetEntriesPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OverrideGLDistributions(var RedistributeAccAllocations: TestPage "Redistribute Acc. Allocations")
    var
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryVariableStorage.DequeueDecimal();

        RedistributeAccAllocations.First();
        RedistributeAccAllocations.Amount.SetValue(GetOverrideAmount());
        TotalAmount -= GetOverrideAmount();

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Amount.SetValue(GetOverrideAmount());
        TotalAmount -= GetOverrideAmount();

        RedistributeAccAllocations.Dimensions.Invoke();

        RedistributeAccAllocations.Next();
        RedistributeAccAllocations.Amount.SetValue(TotalAmount);
        RedistributeAccAllocations.Dimensions.Invoke();
    end;
}