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
        LibraryVATReport: Codeunit "Library - VAT Report";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        IsInitialized: Boolean;
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        GeneratedMsg: Label 'The report has been successfully generated.';
        SubmittedMsg: Label 'The report has been successfully submitted.';

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
        Commit();

        // [WHEN] Stan is running "Suggest Lines"
        LibraryLowerPermissions.SetO365BusFull;
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);

        // [THEN] VAT Values are calculated from the VAT Entries
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindSet();
        Assert.RecordCount(VATStatementReportLine, 9);
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
        VATStatementReportLine.Next();
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
        Assert.RecordCount(VATStatementReportLine, 9);
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
        VATStatementReportLine.FindFirst();

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

    [Test]
    [Scope('OnPrem')]
    procedure GenerateActionVisibleWhenNoSubmissionCodeunitSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Generate" action is visible when no "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Content Codeunit ID" specified and "Submission Codeunit ID" not specified
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Report with VAT Reports Configuration
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));

        // [WHEN] Open VAT Report page
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Generate" action is visible but not enabled
        Assert.IsTrue(VATReportPage.Generate.Visible(), '');
        Assert.IsFalse(VATReportPage.Generate.Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitActionVisibleWhenSubmissionCodeunitSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Submit" action is visible when "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(Codeunit::"Test VAT Submission");

        // [GIVEN] VAT Report with VAT Reports Configuration
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));

        // [WHEN] Open VAT Report page
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Submit" action is visible but not enabled
        Assert.IsTrue(VATReportPage.Submit.Visible(), '');
        Assert.IsFalse(VATReportPage.Submit.Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseVATReportWhenValidateCodeunitFails()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan cannot release VAT report when "Validate Codeunit" fails on execution

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with blank "Additional Information"
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [WHEN] Stan click "Release" action
        VATReportPage.Release.Invoke();

        // [THEN] Messages factbox shown on the "VAT Report" page with the "Additional Information must not be blank" error
        VATReportPage.ErrorMessagesPart.Description.AssertEquals(
            StrSubstNo(IfEmptyErr, VATReportHeader.FieldCaption("Additional Information"), Format(VATReportHeader.RecordId)));

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportStatusChangesToReleasedWhenValidationCodeunitPassed()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan can release VAT report when "Validate Codeunit" passes

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with "Additional Information" specified
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));
        VATReportHeader."Additional Information" := LibraryUtility.GenerateGUID();
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [WHEN] Stan click "Release" action
        VATReportPage.Release.Invoke();

        // [THEN] VAT Report's status is released
        VATReportPage.Status.AssertEquals(VATReportHeader.Status::Released);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadSubmissionMessageEnabledhenReleasedAndSubmissionCodeunitNotSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Download Submission Message" action is enabled when report is released but submission codeunit not specified 

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with Release status
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [WHEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Download Submission Message" action is enabled
        Assert.IsTrue(VATReportPage."Download Submission Message".Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure DownloadSubmissionMessageAfterContentGeneration()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportArchive: Record "VAT Report Archive";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Submission message generates after using action "Generate" when no submission codeunit ID specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with no "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with Status = Released
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        LibraryVariableStorage.Enqueue(GeneratedMsg);

        // [WHEN] Stan click "Generate" action
        VATReportPage.Generate.Invoke();

        // [THEN] Submission message generated
        VATReportArchive.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.");
        VATReportArchive.CalcFields("Submission Message BLOB");
        VATReportArchive.TestField("Submission Message BLOB");

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure SubmitVATReportChanges()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportArchive: Record "VAT Report Archive";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan can submit VAT report when "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(Codeunit::"Test VAT Submission");

        // [GIVEN] VAT Return
        CreateVATReturn(VATReportHeader, DATE2DMY(WORKDATE, 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        LibraryVariableStorage.Enqueue(SubmittedMsg);

        // [WHEN] Stan click "Submit" action
        VATReportPage.Submit.Invoke();

        // [THEN] VAT Report's status is submitted
        VATReportPage.Status.AssertEquals(VATReportHeader.Status::Submitted);

        // [THEN] "Message ID" is assigned to VAT Report
        VATReportHeader.Find();
        VATReportHeader.TestField("Message Id");

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure VATNoteFieldIsVisibleInVATReturnSubformPageWhenReportVATNoteOptionEnabled()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
        PostingDate: Date;
        BoxNo: Text[30];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 433237] The VAT Note field is visible in the VAT return subform page when "Report VAT Note" option is enabled

        Initialize();
        SetReportNoteInVATReportSetup();

        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));

        LibraryLowerPermissions.SetO365BusFull;
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        Assert.IsTrue(VATReportPage.VATReportLines.Note.Visible(), 'VAT Note field is not visible');

        VATReportPage.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.Save(Database::"VAT Report Setup");
        IsInitialized := true;
        Commit();
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
        i: Integer;
    begin
        VATStatementLine.ModifyAll("Box No.", '');
        VATStatementLine.FindFirst();
        for i := 1 to 9 do begin
            VATStatementLine."Box No." := Format(i);
            VATStatementLine.Modify();
            VATStatementLine.Next();
        end;
    end;

    local procedure SetupFourVATStatementLines(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        i: Integer;
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

            for i := 5 to 9 do
                InsertVATStatementLine(VATStatementLine, Format(i), "Amount Type"::Amount);
        end;
    end;

    local procedure SetupSingleVATStatementLineForVATPostingSetup(var VATStatementLine: Record "VAT Statement Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Sale);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Box No.", LibraryUtility.GenerateGUID());
        VATStatementLine.Modify(true);
    end;

    local procedure InsertVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; BoxNo: Text[30]; AmountType: Enum "VAT Statement Line Amount Type")
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
            "VAT Reporting Date" := PostingDate;
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

    local procedure SuggestLines(VATReportHeader: Record "VAT Report Header"; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PeriodYear: Integer; AmountInACY: Boolean);
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

    local procedure SuggestLinesWithPeriod(VATReportHeader: Record "VAT Report Header"; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PeriodYear: Integer; PeriodNo: Integer; AmountInACY: Boolean);
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(PeriodYear);
        LibraryVariableStorage.Enqueue(PeriodNo);
        LibraryVariableStorage.Enqueue(AmountInACY);
        VATReportMediator.GetLines(VATReportHeader);
    end;

    local procedure GetVATStatementNameW1(var VATStatementName: Record "VAT Statement Name");
    begin
        VATStatementName.GET('VAT', 'DEFAULT');
    end;

    local procedure SetupVATReportsConfiguration(SubmissionCodeunitID: Integer)
    begin
        InitVATReportsConfiguration(0, Codeunit::"Test VAT Content", Codeunit::"Test VAT Validate", SubmissionCodeunitID, Codeunit::"Test VAT Response");
    end;

    local procedure SetupVATRepConfSuggestLines()
    begin
        InitVATReportsConfiguration(Codeunit::"VAT Report Suggest Lines", 0, 0, 0, 0);
    end;

    local procedure InitVATReportsConfiguration(SuggestLinesCodeunitID: Integer; ContentCodeunitID: Integer; ValidateCodeunitID: Integer; SubmissionCodeunitID: Integer; ResponseHandlerCodeunitID: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
        VATReportsConfiguration.DeleteAll();
        VATReportHeader.DeleteAll();
        LibraryVATReport.CreateVATReportConfigurationNo(
            SuggestLinesCodeunitID, ContentCodeunitID, ValidateCodeunitID, SubmissionCodeunitID, ResponseHandlerCodeunitID);
    end;

    local procedure SetReportBaseInVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Base", true);
        VATReportSetup.Modify(true);
    end;

    local procedure SetReportNoteInVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Note", true);
        VATReportSetup.Modify(true);
    end;

    local procedure FindPostingDateWithNoVATEntries(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Posting Date");
        if VATEntry.FindLast() then
            exit(CalcDate('<1Y>', VATEntry."Posting Date"));
        exit(WorkDate());
    end;

    local procedure VerifyVATStatementReportLine(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedAmount: Decimal)
    begin
        VerifyVATStatementReportLineBaseAndAmount(VATReportHeader, BoxNo, 0, ExpectedAmount)
    end;

    local procedure VerifyVATStatementReportLineBaseAndAmount(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        with VATStatementReportLine do begin
            SetRange("VAT Report No.", VATReportHeader."No.");
            SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
            SetRange("Box No.", BoxNo);
            FindFirst();
            TestField(Base, ExpectedBase);
            TestField(Amount, ExpectedAmount);
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

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger);
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean);
        VATReportRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesCustomVATStatementRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    begin
        VATReportRequestPage.VATStatementTemplate.SETVALUE(LibraryVariableStorage.DequeueText());
        VATReportRequestPage.VATStatementName.SETVALUE(LibraryVariableStorage.DequeueText());

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Period No.".SetValue(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean());
        VATReportRequestPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [EventSubscriber(ObjectType::Table, database::"Job Queue Entry", 'OnBeforeScheduleTask', '', true, true)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        TaskGUID := CreateGuid();
    end;
}

