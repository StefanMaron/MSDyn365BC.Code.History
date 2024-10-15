#if not CLEAN18
codeunit 144300 "Fixed Assets"
{
    // Test Cases for Fixed Assets
    // 1. Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type
    // 2. Test the Posting of Calculated Depreciation with use Depreciation Group of Declining-Balance type
    // 3. Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line Intangible type
    // 4. Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type with Interruption
    // 5. Verify that lookup of Depreciation Group Code from FA Depreciation Book displaying only Depreciation Group of SKP Code
    // 6. Verify that change of Responsible Employee or FA Location Code on the Fixed Asset Card will cause creation FA HIstory Entry
    // 7. Test the Posting of Fixed Asset Maintenance, creation Maintenance Entry and creation G/L Entry with G/L Account from
    //   FA Extended Posting Group
    // 8. Test the Posting of Fixed Asset Disposal, change field "Disposed" on the FA Depreciation Book and
    //   creation G/L Entry with G/L Account from FA Extended Posting Group

    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFixedAssetCZ: Codeunit "Library - Fixed Asset CZ";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryPurchase: Codeunit "Library - Purchase";
        RandomNumberGenerator: Codeunit "Library - Random";
        isInitialized: Boolean;
        DepreciationGroupFilterErr: Label 'Depreciation Group Filter is not set.';

    local procedure Initialize()
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalSetup: Record "FA Journal Setup";
        DepreciationBook: Record "Depreciation Book";
    begin
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        CreateDepreciationBook(DepreciationBook);
        CreateFAJournalTemplate(FAJournalTemplate);
        CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        CreateFAJournalSetup(
          FAJournalSetup, DepreciationBook.Code,
          FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        UpdateFASetup(DepreciationBook.Code);
        UpdateHumanResourcesSetup;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationStraightLine()
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        // Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type
        CalculateDepreciation(DepreciationGroup."Depreciation Type"::"Straight-line");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationDecliningBalance()
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        // Test the Posting of Calculated Depreciation with use Depreciation Group of Declining-Balance type
        CalculateDepreciation(DepreciationGroup."Depreciation Type"::"Declining-Balance");
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationStraightLineIntangible()
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        // Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line Intangible type
        CalculateDepreciation(DepreciationGroup."Depreciation Type"::"Straight-line Intangible");
    end;

    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    local procedure CalculateDepreciation(DepreciationType: Option)
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationGroup: Record "Depreciation Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // 1.Setup:
        Initialize();

        // Get FA Setup
        FASetup.Get();

        // Create Fixed Asset and FA Depreciation Book
        CreateFixedAsset(FixedAsset);
        CreateDepreciationGroup(DepreciationGroup, DepreciationType);
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depr. Book", DepreciationGroup.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");

        if DepreciationType = DepreciationGroup."Depreciation Type"::"Straight-line Intangible" then begin
            FADepreciationBook.Validate("No. of Depreciation Years", 3);
            FADepreciationBook.Modify(true);
        end;

        // Create FA Journal Line
        CreateFAJournalLine(
          FAJournalLine, FASetup."Tax Depr. Book",
          FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.");

        // Post FA Journal Line for Acquisition Cost
        PostFAJournalLine(FAJournalLine);

        // 2.Exercise:

        // Execute Calculate Depreciation
        RunCalculateDepreciation(FixedAsset, FASetup."Tax Depr. Book");

        // Post FA Journal Line for Depreciation
        PostDepreciationWithDocumentNo(FASetup."Tax Depr. Book");

        // 3.Verify:

        // Verify FA Ledger Entry for Depreciation
        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Tax Depr. Book");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
    end;

    [Test]
    [HandlerFunctions('DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateDepreciationWithInterruption()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationGroup: Record "Depreciation Group";
        FAJournalLine: Record "FA Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Test the Posting of Calculated Depreciation with use Depreciation Group of Straight-line type with Interruption
        // 1.Setup:
        Initialize();

        // Get FA Setup
        FASetup.Get();

        // Create Fixed Asset and FA Depreciation Book
        CreateFixedAsset(FixedAsset);
        CreateDepreciationGroup(DepreciationGroup, DepreciationGroup."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          FASetup."Tax Depr. Book", DepreciationGroup.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("No. of Depreciation Years", 3);
        FADepreciationBook.Modify(true);

        // Create FA Journal Line
        CreateFAJournalLine(
          FAJournalLine, FASetup."Tax Depr. Book",
          FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.");

        // Post FA Journal Line for Acquisition Cost
        PostFAJournalLine(FAJournalLine);

        // Setup depreciation interruption
        FADepreciationBook.Validate("Depreciation Interupt up to", CalcDate('<-CY+1Y>', WorkDate));
        FADepreciationBook.Validate("Depreciation Interupt", true);
        FADepreciationBook.Modify(true);

        // 2.Exercise:

        // Execute Calculate Depreciation
        RunCalculateDepreciation(FixedAsset, FASetup."Tax Depr. Book");

        // Post FA Journal Line for Depreciation
        PostDepreciationWithDocumentNo(FASetup."Tax Depr. Book");

        // 3.Verify:

        // Verify FA Ledger Entry for Depreciation with interruption
        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Tax Depr. Book");
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, 0);
    end;

    [Test]
    [HandlerFunctions('RequestPageInitializeFAHistoryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LoggingFixedAssetChanges()
    var
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        FALocation: Record "FA Location";
        FAHistoryEntry: Record "FA History Entry";
    begin
        // Verify that change of Responsible Employee or FA Location Code on the Fixed Asset Card will cause creation FA HIstory Entry
        // 1.Setup:
        Initialize();

        UpdateFASetupWithFAHistory(true);
        CreateEmployee(Employee);
        CreateFALocation(FALocation);
        CreateFixedAsset(FixedAsset);

        // 2.Exercise:
        FixedAsset.Validate("Responsible Employee", Employee."No.");
        FixedAsset.Validate("FA Location Code", FALocation.Code);
        FixedAsset.Modify(true);

        // 3.Verify:
        FAHistoryEntry.SetCurrentKey("FA No.");
        FAHistoryEntry.SetRange("FA No.", FixedAsset."No.");
        FAHistoryEntry.SetRange(Type, FAHistoryEntry.Type::"Responsible Employee");
        FAHistoryEntry.FindFirst();
        FAHistoryEntry.TestField("New Value", Employee."No.");

        FAHistoryEntry.SetRange(Type, FAHistoryEntry.Type::Location);
        FAHistoryEntry.FindFirst();
        FAHistoryEntry.TestField("New Value", FALocation.Code);

        // 4.Teardown
        UpdateFASetupWithFAHistory(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingFixedAssetDisposal()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationGroup: Record "Depreciation Group";
        FAPostingGroup: Record "FA Posting Group";
        FAExtendedPostingGroup: Record "FA Extended Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // Test the Posting of Fixed Asset Disposal, change field "Disposed" on the FA Depreciation Book and
        // creation G/L Entry with G/L Account from FA Extended Posting Group
        // 1.Setup:
        Initialize();

        // Create Depreciation Book
        CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);

        // Create FA Posting Group and FA Extended Posting Group
        CreateFAPostingGroup(FAPostingGroup);
        CreateFAExtendedPostingGroupDisposal(FAExtendedPostingGroup, FAPostingGroup.Code);

        // Create Fixed Asset and FA Depreciation Book
        CreateFixedAsset(FixedAsset);
        CreateDepreciationGroup(DepreciationGroup, DepreciationGroup."Depreciation Type"::"Straight-line");
        CreateFADepreciationBook(
          FADepreciationBook, FixedAsset."No.",
          DepreciationBook.Code, DepreciationGroup.Code, true,
          FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Acquisition Date", WorkDate);
        FADepreciationBook.Modify(true);

        // Create FA Journal Line
        CreateGenJournalLine(
          GenJournalLine, DepreciationBook.Code,
          GenJournalLine."FA Posting Type"::Disposal, FixedAsset."No.");
        GenJournalLine.Validate("Reason Code", FAExtendedPostingGroup.Code);
        GenJournalLine.Modify(true);

        // 2.Exercise:

        PostGenJournalLine(GenJournalLine);

        // 3.Verify:

        // Verify that Fixed Asset is Disposed
        FADepreciationBook.Get(FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.TestField("Disposal Date");

        // Check G/L Account No in the G/L Entry after posting Gen. Journal Line
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Posting Date", GenJournalLine."Posting Date");
        GLEntry.FindFirst();
        GLEntry.TestField("G/L Account No.", FAExtendedPostingGroup."Sales Acc. On Disp. (Gain)");
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
    end;

    local procedure CreateFAJournalTemplate(var FAJournalTemplate: Record "FA Journal Template")
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        FAJournalTemplate.SetRange(Recurring, false);
        FAJournalTemplate.Modify(true);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch"; FAJournalTemplateName: Code[10])
    begin
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplateName);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Option; FANo: Code[20])
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalTemplate(FAJournalTemplate);
        CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);

        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", GetFAJournalLineDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("Posting Date", WorkDate);
        FAJournalLine.Validate("FA Posting Date", WorkDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate("Debit Amount", RandomNumberGenerator.RandDec(1000, 2));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10]; FAPostingType: Option; FANo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset", FANo, 0);
        GenJournalLine.Validate("Document No.", GetGenJournalLineDocumentNo(GenJournalBatch));
        GenJournalLine.Validate("Posting Date", WorkDate);
        GenJournalLine.Validate("FA Posting Date", WorkDate);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Validate("Corresp. G/L Entries on Disp.", true);
        DepreciationBook.Validate("Corresp. FA Entries on Disp.", true);
        DepreciationBook.Validate("Deprication from 1st Year Day", true);
        DepreciationBook.Validate("Check Deprication on Disposal", true);
        DepreciationBook.Validate("Use FA Ledger Check", true);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Modify(true);

        FAPostingTypeSetup.SetRange("Depreciation Book Code", DepreciationBook.Code);
        if FAPostingTypeSetup.FindSet() then
            repeat
                FAPostingTypeSetup."Include in Gain/Loss Calc." := true;
                FAPostingTypeSetup.Modify();
            until FAPostingTypeSetup.Next = 0;
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; DepreciationGroupCode: Code[10]; DefaultFADepreciationBook: Boolean; DepreciationMethod: Option)
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", LibraryFixedAssetCZ.FindFiscalYear(WorkDate));
        FADepreciationBook.Validate("Depreciation Group Code", DepreciationGroupCode);
        FADepreciationBook.Validate("Default FA Depreciation Book", DefaultFADepreciationBook);
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup"; DepreciationBookCode: Code[10]; FAJournalTemplateName: Code[10]; FAJournalBatchName: Code[10])
    begin
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBookCode, UserId);
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalTemplateName);
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatchName);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateDepreciationGroup(var DepreciationGroup: Record "Depreciation Group"; DepreciationType: Option)
    begin
        LibraryFixedAssetCZ.CreateDepreciationGroup(DepreciationGroup, CalcDate('<-CY-5Y>', WorkDate));
        DepreciationGroup.Validate("Depreciation Group", LibraryFixedAssetCZ.GenerateDeprecationGroupCode);

        case DepreciationType of
            DepreciationGroup."Depreciation Type"::"Straight-line":
                UpdateDepreciationGroupStraightLine(DepreciationGroup);
            DepreciationGroup."Depreciation Type"::"Declining-Balance":
                UpdateDepreciationGroupDecliningBalance(DepreciationGroup);
            DepreciationGroup."Depreciation Type"::"Straight-line Intangible":
                UpdateDepreciationGroupStraightLineIntangible(DepreciationGroup);
        end;
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Custom 2 Account", GetNewGLAccountNo);
        FAPostingGroup.Modify(true);
    end;

    local procedure CreateFAExtendedPostingGroupDisposal(var FAExtendedPostingGroup: Record "FA Extended Posting Group"; FAPostingGroupCode: Code[20])
    var
        ReasonCode: Record "Reason Code";
    begin
        CreateReasonCode(ReasonCode);
        LibraryFixedAssetCZ.CreateFAExtendedPostingGroup(
          FAExtendedPostingGroup, FAPostingGroupCode, FAExtendedPostingGroup."FA Posting Type"::Disposal, ReasonCode.Code);
        FAExtendedPostingGroup.Validate("Book Val. Acc. on Disp. (Gain)", GetNewGLAccountNo);
        FAExtendedPostingGroup.Validate("Book Val. Acc. on Disp. (Loss)", GetNewGLAccountNo);
        FAExtendedPostingGroup.Validate("Sales Acc. On Disp. (Gain)", GetNewGLAccountNo);
        FAExtendedPostingGroup.Validate("Sales Acc. On Disp. (Loss)", GetNewGLAccountNo);
        FAExtendedPostingGroup.Modify(true);
    end;

    local procedure CreateFAExtendedPostingGroupMaintenance(var FAExtendedPostingGroup: Record "FA Extended Posting Group"; FAPostingGroupCode: Code[20])
    var
        Maintenance: Record Maintenance;
    begin
        CreateMaintenance(Maintenance);
        LibraryFixedAssetCZ.CreateFAExtendedPostingGroup(
          FAExtendedPostingGroup, FAPostingGroupCode, FAExtendedPostingGroup."FA Posting Type"::Maintenance, Maintenance.Code);
        FAExtendedPostingGroup.Validate("Maintenance Expense Account", GetNewGLAccountNo);
        FAExtendedPostingGroup.Modify(true);
    end;

    local procedure CreateReasonCode(var ReasonCode: Record "Reason Code")
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
    end;

    local procedure CreateMaintenance(var Maintenance: Record Maintenance)
    begin
        LibraryFixedAsset.CreateMaintenance(Maintenance);
    end;

    local procedure CreateFALocation(var FALocation: Record "FA Location")
    begin
        LibraryFixedAssetCZ.CreateFALocation(FALocation);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        LibraryHumanResource.CreateEmployee(Employee);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; FANo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        PurchHeader.Validate("Vendor Invoice No.", PurchHeader."No.");
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"Fixed Asset", FANo, 1);
        PurchLine.Validate("Direct Unit Cost", RandomNumberGenerator.RandInt(1000));
        PurchLine.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
    end;

    local procedure UpdateDepreciationGroupStraightLine(var DepreciationGroup: Record "Depreciation Group")
    begin
        DepreciationGroup.Validate("Depreciation Type", DepreciationGroup."Depreciation Type"::"Straight-line");
        DepreciationGroup.Validate("No. of Depreciation Years", 3);
        DepreciationGroup.Validate("Straight First Year", 20);
        DepreciationGroup.Validate("Straight Next Years", 40);
        DepreciationGroup.Validate("Straight Appreciation", 33.3);
        DepreciationGroup.Modify(true);
    end;

    local procedure UpdateDepreciationGroupDecliningBalance(var DepreciationGroup: Record "Depreciation Group")
    begin
        DepreciationGroup.Validate("Depreciation Type", DepreciationGroup."Depreciation Type"::"Declining-Balance");
        DepreciationGroup.Validate("No. of Depreciation Years", 3);
        DepreciationGroup.Validate("Declining First Year", 3);
        DepreciationGroup.Validate("Declining Next Years", 4);
        DepreciationGroup.Validate("Declining Appreciation", 3);
        DepreciationGroup.Modify(true);
    end;

    local procedure UpdateDepreciationGroupStraightLineIntangible(var DepreciationGroup: Record "Depreciation Group")
    begin
        DepreciationGroup.Validate("Depreciation Type", DepreciationGroup."Depreciation Type"::"Straight-line Intangible");
        DepreciationGroup.Validate("No. of Depreciation Years", 3);
        DepreciationGroup.Validate("Min. Months After Appreciation", 18);
        DepreciationGroup.Modify(true);
    end;

    local procedure UpdateFASetup(TaxDeprBookCode: Code[10])
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Tax Depr. Book", TaxDeprBookCode);
        FASetup.Validate("Fixed Asset Nos.", LibraryERM.CreateNoSeriesCode);
        FASetup.Modify(true);
    end;

    local procedure UpdateFASetupWithFAHistory(FixedAssetHistory: Boolean)
    var
        FASetup: Record "FA Setup";
    begin
        LibraryVariableStorage.Enqueue(WorkDate);
        FASetup.Get();
        FASetup.Validate("Fixed Asset History", FixedAssetHistory);
        FASetup.Modify(true);
    end;

    local procedure UpdateHumanResourcesSetup()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();
        HumanResourcesSetup.Validate("Employee Nos.", LibraryERM.CreateNoSeriesCode);
        HumanResourcesSetup.Modify(true);
    end;

    local procedure GetFAJournalLineDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesManagement.GetNextNo(FAJournalBatch."No. Series", WorkDate, false));
    end;

    local procedure GetGenJournalLineDocumentNo(GenJournalBatch: Record "Gen. Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeries.Get(GenJournalBatch."No. Series");
        exit(NoSeriesManagement.GetNextNo(GenJournalBatch."No. Series", WorkDate, false));
    end;

    local procedure GetNewGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure PostDepreciationWithDocumentNo(DepreciationBookCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJournalSetup.Get(DepreciationBookCode, UserId);
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.FindFirst();

        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        FAJournalBatch.Validate("No. Series", '');
        FAJournalBatch.Modify(true);

        PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostFAJournalLine(var FAJournalLine: Record "FA Journal Line")
    begin
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchaseDocument(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure RunCalculateDepreciation(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10])
    begin
        FixedAsset.SetRecFilter;
        LibraryFixedAssetCZ.RunCalculateDepreciation(
          FixedAsset, DepreciationBookCode, CalcDate('<CY>', WorkDate), FixedAsset."No.", FixedAsset.Description);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalDepreciationGroupsHandler(var DepreciationGroups: TestPage "Depreciation Groups")
    var
        DepreciationGroupCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationGroupCode);
        Assert.IsTrue(
          DepreciationGroups.FILTER.GetFilter("Depreciation Group") = Format(DepreciationGroupCode), DepreciationGroupFilterErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageInitializeFAHistoryHandler(var InitializeFAHistory: TestRequestPage "Initialize FA History")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        InitializeFAHistory.PostingDate.SetValue(PostingDate);
        InitializeFAHistory.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        // Dummy Message Handler
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

#endif