codeunit 134073 "Check Document No. Unit Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document No.] [General Journal] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        DocumentNoErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1 = Document number';
        IncorrectNoSeriesCodeErr: Label 'Incorrect No. Series code';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesDifferentVendorDifferentDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor1);
        LibraryPurchase.CreateVendor(Vendor2);

        // Setup
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor1."No.", Vendor2."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines;

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesDifferentVendorSameDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor1);
        LibraryPurchase.CreateVendor(Vendor2);

        // Setup
        CreateDiffAccNoSameDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor1."No.", Vendor2."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines;

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MulitpleLinesSameVendorSameDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor);

        // Setup
        CreateSameAccNoSameDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines;

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesSameVendorWithDocNoGap()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CorrectDocumentNo: Code[20];
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor);

        // Setup
        CorrectDocumentNo := CreateSameAccLinesWithDocNoGap(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror GenJnlLine.CheckDocNoOnLines;

        // Verify
        Assert.ExpectedError(StrSubstNo(DocumentNoErr, IncStr(CorrectDocumentNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesAboveLimitDecimal()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 201310] Getting next No. Series when number encoded exceeds limit for type "decimal"

        // [GIVEN]
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] No. Series with "Last No. Used"= "T09000000000000001" and "Increment-by No." = "10"
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'T09000000000000000', 'T09999999999999991');
        NoSeriesLine."Last No. Used" := 'T09000000000000001'; // The limit for type "decimal" is "999,999,999,999,999.00"
        NoSeriesLine."Increment-by No." := 10;
        NoSeriesLine.Modify();

        // [WHEN] Get next No. Series
        NoSeriesManagement.IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");

        // [THEN] Returns Next No. generated = "T09000000000000011"
        NoSeriesLine.TestField("Last No. Used", 'T09000000000000011');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesNotAllowed()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is false when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        ActualNoSeries := NoSeriesManagement.GetNoSeriesWithCheck(NoSeries.Code, false, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedAndDefaultNos()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true and No. Series is "Default Nos." when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        ActualNoSeries := NoSeriesManagement.GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedNotDefaultNosNoRelations()
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no series relations when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        ActualNoSeries := NoSeriesManagement.GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure RelatedNoSeriesIfSelectNoSeriesAllowedSelectRelation()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Related No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no. series relation selected when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);

        ActualNoSeries := NoSeriesManagement.GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(RelatedNoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListSelectNothingModalPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedCancelSelectRelation()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no. series relation not selected when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);

        ActualNoSeries := NoSeriesManagement.GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastNoUsedForExportedPmtLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        // [FEATURE] [No. Series] [UT]
        // [SCENARIO 261484] TAB81.CheckDocNoBasedOnNoSeries updates internal "No Series" instance of NoSeriesManagement without modification. Further modification can be done by NoSeriesManagement.SaveNoSeries

        NoSeriesLine.SetRange("Series Code", LibraryERM.CreateNoSeriesCode);
        NoSeriesLine.FindFirst;

        Commit();

        GenJournalLine.Init();
        GenJournalLine."Posting Date" := WorkDate;
        GenJournalLine."Exported to Payment File" := true;
        GenJournalLine."Document No." := NoSeriesManagement.TryGetNextNo(NoSeriesLine."Series Code", GenJournalLine."Posting Date");

        GenJournalLine.CheckDocNoBasedOnNoSeries('', NoSeriesLine."Series Code", NoSeriesManagement);
        NoSeriesManagement.SaveNoSeries;

        NoSeriesLine.Find;
        NoSeriesLine.TestField("Last No. Used", GenJournalLine."Document No.");
    end;

    local procedure CreateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        BankAcc: Record "Bank Account";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryERM.SelectGenJnlTemplate);

        LibraryERM.CreateBankAccount(BankAcc);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Modify(true);

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJnlBatch.Validate("No. Series", NoSeries.Code);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateDiffAccNoDiffDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Option; FirstAccountNo: Code[20]; SecondAccountNo: Code[20])
    var
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine1."Document Type"::Payment, AccountType, FirstAccountNo, LibraryRandom.RandDec(1000, 2));

        LibraryERM.CreateGeneralJnlLine(GenJnlLine2, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine2."Document Type"::Payment, AccountType, SecondAccountNo, LibraryRandom.RandDec(1000, 2));
        GenJnlLine2.Validate("Document No.", IncStr(GenJnlLine1."Document No."));
        GenJnlLine2.Modify(true);
    end;

    local procedure BatchPostJournalLines(GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateDiffAccNoSameDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Option; FirstAccountNo: Code[20]; SecondAccountNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, AccountType, FirstAccountNo, SecondAccountNo);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst;
        DocumentNo := GenJnlLine."Document No.";

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.ModifyAll("Document No.", DocumentNo, true);
    end;

    local procedure CreateSameAccNoSameDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Option; AccountNo: Code[20])
    begin
        CreateDiffAccNoSameDocNoLines(GenJnlBatch, AccountType, AccountNo, AccountNo);
    end;

    local procedure CreateSameAccLinesWithDocNoGap(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Option; AccountNo: Code[20]) CorrectDocumentNo: Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, AccountType, AccountNo, AccountNo);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindLast;
        CorrectDocumentNo := GenJnlLine."Document No.";

        GenJnlLine.Validate("Document No.", IncStr(GenJnlLine."Document No."));
        GenJnlLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series List")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText);
        NoSeriesList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListSelectNothingModalPageHandler(var NoSeriesList: TestPage "No. Series List")
    begin
        NoSeriesList.Cancel.Invoke;
    end;
}

