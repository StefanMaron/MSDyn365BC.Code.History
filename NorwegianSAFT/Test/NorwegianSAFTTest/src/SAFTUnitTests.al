codeunit 148502 "SAF-T Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SAF-T] [UT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SAFTTestHelper: Codeunit "SAF-T Test Helper";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        MatchChartOfAccountsQst: Label 'Do you want to match a chart of accounts with SAF-T standard account codes?';
        CreateChartOfAccountsQst: Label 'Do you want to create a chart of accounts based on SAF-T standard account codes?';
        StandardAccountsMatchedMsg: Label '%1 of %2 standard accounts have been automatically matched to the chart of accounts.', Comment = '%1,%2 = both integer values';

    [Test]
    procedure VATPostingSetupHasTaxCodesOnInsert()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 309923] A newly inserted VAT Posting Setup has "Sales SAF-T Tax Code" and "Purchase SAF-T Tax Code" 
        Initialize();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.TestField("Sales SAF-T Tax Code");
        VATPostingSetup.TestField("Purchase SAF-T Tax Code");
    end;

    [Test]
    procedure DimensionHasSAFTCodeAndExportToSAFTByDefaultOnInsert()
    var
        Dimension: Record Dimension;
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 309923] A newly inserted Dimension has "SAF-T Analysis Type" and "Export-To SAF-T" on

        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        Dimension.TestField("SAF-T Analysis Type");
        Dimension.TestField("Export to SAF-T");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    procedure MatchChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
        AccountsToBeMatched: Integer;
        i: Integer;
    begin
        // [SCENARIO 309923] G/L accounts with numbers same as SAF-T Standard Account are matched automatically

        Initialize();
        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            SAFTMappingRange, SAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));
        SAFTMappingHelper.Run(SAFTMappingRange);
        GLAccount.DeleteAll();
        SAFTMapping.SetRange("Mapping Type", SAFTMappingRange."Mapping Type");
        SAFTMapping.FindSet();
        AccountsToBeMatched := LibraryRandom.RandIntInRange(3, 5);
        for i := 1 to AccountsToBeMatched do begin
            GLAccount.Init();
            GLAccount."No." := SAFTMapping."No.";
            GLAccount."Account Type" := GLAccount."Account Type"::Posting;
            GLAccount.Insert();
            SAFTMapping.Next();
        end;
        LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(MatchChartOfAccountsQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(StandardAccountsMatchedMsg, AccountsToBeMatched, GLAccount.Count()));
        SAFTMappingHelper.MatchChartOfAccounts(SAFTMappingRange);
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        SAFTGLAccountMapping.SetFilter("No.", '<>%1', '');
        Assert.RecordCount(SAFTGLAccountMapping, AccountsToBeMatched);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MessageHandler')]
    procedure CreateChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
    begin
        // [SCENARIO 309923] G/L accounts creates from SAF-T Standard Accounts

        Initialize();
        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            SAFTMappingRange, SAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));
        GLAccount.DeleteAll();
        SAFTMapping.SetRange("Mapping Type", SAFTMappingRange."Mapping Type");
        LibraryVariableStorage.Enqueue(CreateChartOfAccountsQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(StandardAccountsMatchedMsg, SAFTMapping.Count(), SAFTMapping.Count()));
        SAFTMappingHelper.CreateChartOfAccounts(SAFTMappingRange);
        SAFTMappingHelper.Run(SAFTMappingRange);
        Assert.AreEqual(SAFTMapping.Count(), GLAccount.Count(), 'Accounts are not matched');
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        Assert.AreEqual(SAFTMapping.Count(), SAFTGLAccountMapping.Count(), 'Accounts are not matched');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CopyMappingNoReplace()
    var
        GLAccount: Record "G/L Account";
        FromSAFTMappingRange: Record "SAF-T Mapping Range";
        ToSAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
    begin
        // [SCENARIO 309923] Copy SAF-T Mapping from one range to another without replace

        Initialize();
        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            FromSAFTMappingRange, FromSAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));
        LibraryERM.CreateGLAccountNo();
        SAFTMappingHelper.Run(FromSAFTMappingRange);
        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            ToSAFTMappingRange, ToSAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));

        SAFTMappingHelper.CopyMapping(FromSAFTMappingRange.Code, ToSAFTMappingRange.Code, false);

        SAFTGLAccountMapping.SetRange("Mapping Range Code", ToSAFTMappingRange.Code);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        Assert.RecordCount(SAFTGLAccountMapping, GLAccount.Count());
    end;

    [Test]
    procedure CopyMappingReplace()
    var
        FromSAFTMappingRange: Record "SAF-T Mapping Range";
        ToSAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
        GLAccNo: Code[20];
    begin
        // [SCENARIO 309923] Copy SAF-T Mapping from one range to another with replace

        Initialize();
        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            FromSAFTMappingRange, FromSAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));
        GLAccNo := LibraryERM.CreateGLAccountNo();
        SAFTMappingHelper.Run(FromSAFTMappingRange);
        SAFTMapping.SetRange("Mapping Type", FromSAFTMappingRange."Mapping Type");
        SAFTMapping.FindFirst();
        SAFTGLAccountMapping.Get(FromSAFTMappingRange.Code, GLAccNo);
        SAFTGLAccountMapping.Validate("Category No.", SAFTMapping."Category No.");
        SAFTGLAccountMapping.Validate("No.", SAFTMapping."No.");
        SAFTGLAccountMapping.Modify();

        SAFTTestHelper.InsertSAFTMappingRangeWithSource(
            ToSAFTMappingRange, ToSAFTMappingRange."Mapping Type"::"Four Digit Standard Account",
            CalcDate('<-CY>', WorkDate()), CalcDate('<-CY>', WorkDate()));
        SAFTMappingHelper.Run(ToSAFTMappingRange);

        SAFTMappingHelper.CopyMapping(FromSAFTMappingRange.Code, ToSAFTMappingRange.Code, true);

        SAFTGLAccountMapping.Get(ToSAFTMappingRange.Code, GLAccNo);
        SAFTGLAccountMapping.TestField("No.", SAFTMapping."No.");
    end;

    [Test]
    procedure ExportLinesWithActivityLogDeletsOnExportHeaderDeletion()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        ActivityLog: Record "Activity Log";
    begin
        // [SCENARIO 309923] SAF-T Export Lines and activity log related to SAF-T Export Header are remove on Header's deletion

        SAFTExportHeader.Init();
        SAFTExportHeader.Insert();
        SAFTExportLine.Init();
        SAFTExportLine.ID := SAFTExportHeader.ID;
        SAFTExportLine.Insert();
        ActivityLog.Init();
        ActivityLog."Record ID" := SAFTExportLine.RecordId();
        ActivityLog.Insert();

        SAFTExportHeader.Delete(true);

        Assert.IsFalse(SAFTExportLine.Find(), 'SAF-T Export Line stil exist');
        Assert.IsFalse(ActivityLog.Find(), 'Activity log stil exist');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SAF-T Unit Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SAF-T Unit Tests");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SAF-T Unit Tests");
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

}