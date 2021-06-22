page 130401 "CAL Test Tool"
{
    AccessByPermission = TableData "CAL Test Line" = RIMD;
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Test Tool';
    DataCaptionExpression = CurrentSuiteName;
    DelayedInsert = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "CAL Test Line";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(CurrentSuiteName; CurrentSuiteName)
            {
                ApplicationArea = All;
                Caption = 'Suite Name';

                trigger OnLookup(var Text: Text): Boolean
                var
                    CALTestSuite: Record "CAL Test Suite";
                begin
                    CALTestSuite.Name := CurrentSuiteName;
                    if PAGE.RunModal(0, CALTestSuite) <> ACTION::LookupOK then
                        exit(false);
                    Text := CALTestSuite.Name;
                    exit(true);
                end;

                trigger OnValidate()
                begin
                    CALTestSuite.Get(CurrentSuiteName);
                    CALTestSuite.CalcFields("Tests to Execute");
                    CurrentSuiteNameOnAfterValidat;
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field(LineType; "Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = LineTypeEmphasize;
                }
                field(TestCodeunit; "Test Codeunit")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'Codeunit ID';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TestCodeunitEmphasize;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the test tool.';
                }
                field("Hit Objects"; "Hit Objects")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NameEmphasize;

                    trigger OnDrillDown()
                    var
                        CALTestCoverageMap: Record "CAL Test Coverage Map";
                    begin
                        CALTestCoverageMap.ShowHitObjects("Test Codeunit");
                    end;
                }
                field(RunColumn; Run)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Result; Result)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = ResultEmphasize;
                }
                field("First Error"; "First Error")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = TRUE;

                    trigger OnDrillDown()
                    begin
                        ShowTestResults
                    end;
                }
                field(Duration; "Finish Time" - "Start Time")
                {
                    ApplicationArea = All;
                    Caption = 'Duration';
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                field(SuccessfulTests; Success)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Successful Tests';
                    Editable = false;
                }
                field(FailedTests; Failure)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Failed Tests';
                    Editable = false;
                }
                field(SkippedTests; Skipped)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Skipped Tests';
                    Editable = false;
                }
                field(NotExecutedTests; NotExecuted)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Tests not Executed';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(DeleteLines)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Lines';
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Delete the selected line.';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                    begin
                        CurrPage.SetSelectionFilter(CALTestLine);
                        CALTestLine.DeleteAll(true);
                        CalcTestResults(Success, Failure, Skipped, NotExecuted);
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestCodeunits)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Codeunits';
                    Image = SelectEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        CALTestSuite.Get(CurrentSuiteName);
                        CALTestMgt.GetTestCodeunitsSelection(CALTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(Run)
                {
                    ApplicationArea = All;
                    Caption = '&Run';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+Ctrl+L';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        WarnNonEnglishLanguage;

                        CALTestLine := Rec;
                        CALTestMgt.RunSuiteYesNo(Rec);
                        Rec := CALTestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(RunSelected)
                {
                    ApplicationArea = All;
                    Caption = 'Run &Selected';
                    Image = TestFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        SelectedCALTestLine: Record "CAL Test Line";
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        WarnNonEnglishLanguage;

                        CurrPage.SetSelectionFilter(SelectedCALTestLine);
                        SelectedCALTestLine.SetRange("Test Suite", "Test Suite");
                        CALTestMgt.RunSelected(SelectedCALTestLine);
                        CurrPage.Update(false);
                    end;
                }
                action(ClearResults)
                {
                    ApplicationArea = All;
                    Caption = 'Clear &Results';
                    Image = ClearLog;
                    ShortCutKey = 'Ctrl+F7';

                    trigger OnAction()
                    var
                        CALTestLine: Record "CAL Test Line";
                    begin
                        CALTestLine := Rec;
                        ClearResultsInSuite(CALTestSuite);
                        Rec := CALTestLine;
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestMethods)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Methods';
                    Image = RefreshText;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    var
                        CALTestMgt: Codeunit "CAL Test Management";
                    begin
                        CALTestMgt.RunSuite(Rec, false);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(TCM)
            {
                Caption = 'TCM';
                action(TestCoverageMap)
                {
                    ApplicationArea = All;
                    Caption = 'Test Coverage Map';
                    Image = Workdays;

                    trigger OnAction()
                    var
                        CALTestCoverageMap: Record "CAL Test Coverage Map";
                    begin
                        CALTestCoverageMap.Show;
                    end;
                }
            }
            group("P&rojects")
            {
                Caption = 'P&rojects';
                action(ExportProject)
                {
                    ApplicationArea = All;
                    Caption = 'Export';
                    Image = Export;
                    ToolTip = 'Export the picture to a file.';

                    trigger OnAction()
                    var
                        CALTestProjectMgt: Codeunit "CAL Test Project Mgt.";
                    begin
                        CALTestProjectMgt.Export(CurrentSuiteName);
                    end;
                }
                action(ImportProject)
                {
                    ApplicationArea = All;
                    Caption = 'Import';
                    Image = Import;

                    trigger OnAction()
                    var
                        CALTestProjectMgt: Codeunit "CAL Test Project Mgt.";
                    begin
                        CALTestProjectMgt.Import;
                    end;
                }
            }
            action(NextError)
            {
                ApplicationArea = All;
                Caption = 'Next Error';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Go to the next error.';

                trigger OnAction()
                begin
                    FindError('>=');
                end;
            }
            action(PreviousError)
            {
                ApplicationArea = All;
                Caption = 'Previous Error';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Go to the previous error.';

                trigger OnAction()
                begin
                    FindError('<=');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcTestResults(Success, Failure, Skipped, NotExecuted);
        NameIndent := "Line Type";
        LineTypeEmphasize := "Line Type" in ["Line Type"::Group, "Line Type"::Codeunit];
        TestCodeunitEmphasize := "Line Type" = "Line Type"::Codeunit;
        NameEmphasize := "Line Type" = "Line Type"::Group;
        ResultEmphasize := Result = Result::Success;
        if "Line Type" <> "Line Type"::Codeunit then
            "Hit Objects" := 0;
    end;

    trigger OnOpenPage()
    begin
        if not CALTestSuite.Get(CurrentSuiteName) then
            if CALTestSuite.FindFirst then
                CurrentSuiteName := CALTestSuite.Name
            else begin
                CreateTestSuite(CurrentSuiteName);
                Commit();
            end;

        FilterGroup(2);
        SetRange("Test Suite", CurrentSuiteName);
        FilterGroup(0);

        if Find('-') then;
        CurrPage.Update(false);

        CALTestSuite.Get(CurrentSuiteName);
        CALTestSuite.CalcFields("Tests to Execute");
    end;

    var
        CALTestSuite: Record "CAL Test Suite";
        LanguageWarningNotification: Notification;
        CurrentSuiteName: Code[10];
        Skipped: Integer;
        Success: Integer;
        Failure: Integer;
        NotExecuted: Integer;
        [InDataSet]
        NameIndent: Integer;
        [InDataSet]
        LineTypeEmphasize: Boolean;
        NameEmphasize: Boolean;
        [InDataSet]
        TestCodeunitEmphasize: Boolean;
        [InDataSet]
        ResultEmphasize: Boolean;
        LanguageWarningShown: Boolean;
        LanguageWarningMsg: Label 'Warning: The current language is not set to English (US). The tests may only contain captions in English (US), which will cause the tests to fail. Resolve the issue by switching the language or introducing translations in the test.';

    local procedure ClearResultsInSuite(CALTestSuite: Record "CAL Test Suite")
    var
        CALTestLine: Record "CAL Test Line";
    begin
        if CALTestSuite.Name <> '' then
            CALTestLine.SetRange("Test Suite", CALTestSuite.Name);

        CALTestLine.ModifyAll(Result, Result::" ");
        CALTestLine.ModifyAll("First Error", '');
        CALTestLine.ModifyAll("Start Time", 0DT);
        CALTestLine.ModifyAll("Finish Time", 0DT);
    end;

    local procedure FindError(Which: Code[10])
    var
        CALTestLine: Record "CAL Test Line";
    begin
        CALTestLine.Copy(Rec);
        CALTestLine.SetRange(Result, Result::Failure);
        if CALTestLine.Find(Which) then
            Rec := CALTestLine;
    end;

    local procedure CreateTestSuite(var NewSuiteName: Code[10])
    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestMgt: Codeunit "CAL Test Management";
    begin
        CALTestMgt.CreateNewSuite(NewSuiteName);
        CALTestSuite.Get(NewSuiteName);
    end;

    local procedure CurrentSuiteNameOnAfterValidat()
    begin
        CurrPage.SaveRecord;

        FilterGroup(2);
        SetRange("Test Suite", CurrentSuiteName);
        FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure WarnNonEnglishLanguage()
    begin
        if LanguageWarningShown then
            exit;

        if GlobalLanguage <> 1033 then begin
            LanguageWarningNotification.Message := LanguageWarningMsg;
            LanguageWarningNotification.Send;
        end;

        LanguageWarningShown := true;
    end;
}

