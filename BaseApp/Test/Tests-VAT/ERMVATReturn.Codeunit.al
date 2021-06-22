codeunit 134096 "ERM VAT Return"
{
    Subtype = Test;
    TestPermissions = Restrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Return] [Suggest Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATReturnSuggestLines()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        // [SCENARIO] Get VAT data for government reporting
        // [GIVEN] Demodata - VAT Report Suggest Lines Codeunit is setup in the VAT Report configuration table
        // [GIVEN] Demodata - VAT Entries
        // [GIVEN] VAT Report header of type VAT Return
        CreateVATReturn(VATReportHdr, DATE2DMY(WORKDATE, 3));

        // [GIVEN] VAT Statememt for VAT Return calculation
        SetupVATStatementLineForVATReturn();
        Commit;

        // [WHEN] Stan is running "Suggest Lines"
        LibraryLowerPermissions.SetO365BusFull;
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);

        // [THEN] VAT Values are calculated from the VAT Entries
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindSet;
        Assert.RecordCount(VATStatementReportLine, 2);
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
        VATStatementReportLine.Next;
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATReturnSuggestLinesUpdateLines()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [SCENARIO] Recalculate  VAT data for government reporting
        // [GIVEN] Demodata - VAT Report Suggest Lines Codeunit is setup in the VAT Report configuration table
        // [GIVEN] Demodata - VAT Entries
        // [GIVEN] VAT Report header of type VAT Return
        CreateVATReturn(VATReportHdr, DATE2DMY(WORKDATE, 3));

        // [GIVEN] VAT Statememt for VAT Return calculation
        SetupVATStatementLineForVATReturn();
        Commit;

        // [GIVEN] Existing VAT Return Lines
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);

        // [GIVEN] Defferent VAT Statement Lines
        VATStatementLine.FindFirst();
        VATStatementLine."Box No." := '';
        VATStatementLine.Modify();
        Commit;

        // [WHEN] Stan is running "Suggest Lines"
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);

        // [THEN] VAT Values are calculated from the VAT Entries based on the new VAT statement
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindFirst;
        Assert.RecordCount(VATStatementReportLine, 1);
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATReturnSuggestLinesWithDifferentFilter()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        // [SCENARIO] Suggest lines for different filters
        // [GIVEN] Demodata - VAT Report Suggest Lines Codeunit is setup in the VAT Report configuration table
        // [GIVEN] Demodata - VAT Entries
        // [GIVEN] VAT Report header of type VAT Return
        CreateVATReturn(VATReportHdr, DATE2DMY(WORKDATE, 3));

        // [GIVEN] VAT Statememt for VAT Return calculation
        SetupVATStatementLineForVATReturn();
        Commit();

        // [WHEN] Stan is running "Suggest Lines"
        // [WHEN] Handler is setting periode to 2000 (no VAT Entries)
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year" - 5, false);

        // [THEN] VAT Values are calculated from the VAT Entries
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindSet();
        Assert.RecordCount(VATStatementReportLine, 2);
        Assert.AreEqual(0, VATStatementReportLine.Amount, 'No VAT Entries should exist in 2000');
        VATStatementReportLine.Next();
        Assert.AreEqual(0, VATStatementReportLine.Amount, 'No VAT Entries should exist in 2000');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATStatementReportLineModification()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        TempDescription: Text;
    begin
        // [SCENARIO] VAT Statement Report Line modification is allowed
        // [GIVEN] VAT Report Header with VAT Statement Report Line "L1"
        CreateVATReturn(VATReportHdr, DATE2DMY(WORKDATE, 3));
        SetupVATStatementLineForVATReturn();
        Commit();
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindFirst;

        // [WHEN] Line "L1" is modified
        TempDescription := LibraryUtility.GenerateRandomText(MaxStrLen(VATStatementReportLine.Description));
        VATStatementReportLine.Description := CopyStr(TempDescription, 1, MaxStrLen(VATStatementReportLine.Description));
        VATStatementReportLine.Modify(true);

        // [THEN] Modification is done
        VATStatementReportLine.TestField(Description, TempDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReturnAddRepCurrField()
    var
        VATReport: TestPage "VAT Report";
    begin
        // [FEATURE] [UT] [UI] [ACY]
        // [SCENARIO 311850] VAT Return "Amounts in Add. Rep. Currency" field should not be editable
        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetO365BusFull();
        VATReport.OpenEdit();
        Assert.IsTrue(
          VATReport."Amounts in Add. Rep. Currency".Visible(),
          'VATReport."Amounts in Add. Rep. Currency" should be visible');
        Assert.IsFalse(
          VATReport."Amounts in Add. Rep. Currency".Editable(),
          'VATReport."Amounts in Add. Rep. Currency" should not be editable');
        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure SuggestLinesLCY()
    var
        VATReportHeader: Record "VAT Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 311850] Suggest Lines for VAT Return in case of "Amounts in Add. Rep. Currency" = false
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] VAT Return for the period
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3) + 1);

        // [GIVEN] VAT Entries for the period with Amount\Base, unrealized Amount\Base LCY and ACY values
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupFourVATStatementLines(VATPostingSetup);
        MockVATEntry(VATEntry, VATPostingSetup, VATReportHeader."Start Date");

        // [WHEN] Suggest Lines for the VAT Return using "Amounts in Add. Reporting Currency" = false
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", false);

        // [THEN] VAT Return header "Amounts in Add. Rep. Currency" = false
        VATReportHeader.Find();
        Assert.IsFalse(VATReportHeader."Amounts in Add. Rep. Currency", 'VATReportHeader."Amounts in Add. Rep. Currency"');

        // [THEN] VAT Return lines have been suggested for the correspondent VAT Entries with LCY values
        VerifyVATStatementReportLine(VATReportHeader, '1', VATEntry.Amount);
        VerifyVATStatementReportLine(VATReportHeader, '2', VATEntry.Base);
        VerifyVATStatementReportLine(VATReportHeader, '3', VATEntry."Remaining Unrealized Amount");
        VerifyVATStatementReportLine(VATReportHeader, '4', VATEntry."Remaining Unrealized Base");

        // Tear Down
        LibraryLowerPermissions.SetOutsideO365Scope();
        VATEntry.Delete();
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure SuggestLinesACY()
    var
        VATReportHeader: Record "VAT Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 311850] Suggest Lines for VAT Return in case of "Amounts in Add. Rep. Currency" = true
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] VAT Return for the period
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3) + 1);

        // [GIVEN] VAT Entries for the period with Amount\Base, unrealized Amount\Base LCY and ACY values
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupFourVATStatementLines(VATPostingSetup);
        MockVATEntry(VATEntry, VATPostingSetup, VATReportHeader."Start Date");

        // [WHEN] Suggest Lines for the VAT Return using "Amounts in Add. Reporting Currency" = true
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", true);

        // [THEN] VAT Return header "Amounts in Add. Rep. Currency" = true
        VATReportHeader.Find();
        Assert.IsTrue(VATReportHeader."Amounts in Add. Rep. Currency", 'VATReportHeader."Amounts in Add. Rep. Currency"');

        // [THEN] VAT Return lines have been suggested for the correspondent VAT Entries with ACY values
        VerifyVATStatementReportLine(VATReportHeader, '1', VATEntry."Additional-Currency Amount");
        VerifyVATStatementReportLine(VATReportHeader, '2', VATEntry."Additional-Currency Base");
        VerifyVATStatementReportLine(VATReportHeader, '3', VATEntry."Add.-Curr. Rem. Unreal. Amount");
        VerifyVATStatementReportLine(VATReportHeader, '4', VATEntry."Add.-Curr. Rem. Unreal. Base");

        // Tear Down
        LibraryLowerPermissions.SetOutsideO365Scope();
        VATEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetupAutoUpdatePeriodUI()
    var
        VATReportSetup: Record "VAT Report Setup";
        ERMVATReturn: Codeunit "ERM VAT Return";
        VATReportSetupPage: TestPage "VAT Report Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 309370] PAG 743 "VAT Report Setup" field "Auto Receive Period CU ID"
        // [SCENARIO 309370] is only editable in case of "Update Period Job Frequency" = Never
        LibraryLowerPermissions.SetO365BusFull();
        VATReportSetup.Get();
        VATReportSetupPage.OpenEdit();

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Never);
        Assert.IsTrue(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        BindSubscription(ERMVATReturn); // suppress job queue
        VATReportSetupPage."Auto Receive Period CU ID".SetValue(Codeunit::"Gen. Jnl.-Check Line");
        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Daily);
        Assert.IsFalse(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Weekly);
        Assert.IsFalse(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Never);
        Assert.IsTrue(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');
        VATReportSetupPage.Close();
    end;

    local procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header"; PeriodYear: Integer);
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("Period Year", PeriodYear);
        VATReportHeader.Modify();
    end;

    local procedure SetupVATStatementLineForVATReturn()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.ModifyAll("Box No.", '');
        VATStatementLine.FindFirst();
        VATStatementLine."Box No." := '1';
        VATStatementLine.Modify();
        VATStatementLine.Next();
        VATStatementLine."Box No." := '2';
        VATStatementLine.Modify();
    end;

    local procedure SetupFourVATStatementLines(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
    begin
        GetVATStatementNameW1(VATStatementName);
        with VATStatementLine do begin
            SetRange("Statement Template Name", VATStatementName."Statement Template Name");
            SetRange("Statement Name", VATStatementName.Name);
            ModifyAll("Box No.", '');
            FindLast();

            "VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

            InsertVATStatementLine(VATStatementLine, '1', "Amount Type"::Amount);
            InsertVATStatementLine(VATStatementLine, '2', "Amount Type"::Base);
            InsertVATStatementLine(VATStatementLine, '3', "Amount Type"::"Unrealized Amount");
            InsertVATStatementLine(VATStatementLine, '4', "Amount Type"::"Unrealized Base");
        end;
    end;

    local procedure InsertVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; BoxNo: Text[30]; AmountType: Option)
    begin
        with VATStatementLine do begin
            "Line No." += 10000;
            "Box No." := BoxNo;
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            Type := Type::"VAT Entry Totaling";
            "Amount Type" := AmountType;
            "Print with" := "Print with"::Sign;
            Insert();
        end;
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date)
    begin
        with VATEntry do begin
            "Entry No." := LibraryUtility.GetNewRecNo(VATEntry, FIELDNO("Entry No."));
            Type := Type::Sale;
            "Posting Date" := PostingDate;
            Closed := FALSE;
            "VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            Amount := LibraryRandom.RandDec(1000, 2);
            Base := LibraryRandom.RandDec(1000, 2);
            "Remaining Unrealized Amount" := LibraryRandom.RandDec(1000, 2);
            "Remaining Unrealized Base" := LibraryRandom.RandDec(1000, 2);
            "Additional-Currency Amount" := LibraryRandom.RandDec(1000, 2);
            "Additional-Currency Base" := LibraryRandom.RandDec(1000, 2);
            "Add.-Curr. Rem. Unreal. Amount" := LibraryRandom.RandDec(1000, 2);
            "Add.-Curr. Rem. Unreal. Base" := LibraryRandom.RandDec(1000, 2);
            Insert();
        end;
    end;

    local procedure SuggestLines(VATReportHeader: Record "VAT Report Header"; Selection: Option; PeriodSelection: Option; PeriodYear: Integer; AmountInACY: Boolean);
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(PeriodYear);
        LibraryVariableStorage.Enqueue(AmountInACY);
        VATReportMediator.GetLines(VATReportHeader);
    end;

    local procedure GetVATStatementNameW1(var VATStatementName: Record "VAT Statement Name");
    begin
        VATStatementName.GET('VAT', 'DEFAULT');
    end;

    local procedure VerifyVATStatementReportLine(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedAmount: Decimal)
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        with VATStatementReportLine do begin
            SetRange("VAT Report No.", VATReportHeader."No.");
            SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
            SetRange("Box No.", BoxNo);
            FindFirst();
            Assert.AreEqual(ExpectedAmount, Amount, 'VATStatementReportLine.Amount');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        GetVATStatementNameW1(VATStatementName);
        VATReportRequestPage.VATStatementTemplate.SETVALUE(VATStatementName."Statement Template Name");
        VATReportRequestPage.VATStatementName.SETVALUE(VATStatementName.Name);

        Selection := LibraryVariableStorage.DequeueInteger();
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := LibraryVariableStorage.DequeueInteger();
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger);
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean);
        VATReportRequestPage.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Table, database::"Job Queue Entry", 'OnBeforeScheduleTask', '', true, true)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        TaskGUID := CreateGuid();
    end;
}

