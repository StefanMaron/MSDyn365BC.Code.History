page 130415 "Semi-Manual Test Wizard"
{
    Caption = 'Semi-Manual Test Wizard';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Semi-Manual Test Wizard";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(StepCodeunit)
            {
                Caption = '';
                Visible = NOT TestExecuting;
                group(Para1)
                {
                    Caption = 'Codeunit';
                    InstructionalText = 'Choose the codeunit, and then load it. The wizard will do the actions that could be automated, and list actions for each step that you need to do manually.';
                    field(CodeunitId; CodeunitId)
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                        ColumnSpan = 2;

                        trigger OnDrillDown()
                        var
                            AllObjWithCaption: Record AllObjWithCaption;
                            GetSemiManualTestCodeunits: Page "Get Semi-Manual Test Codeunits";
                        begin
                            GetSemiManualTestCodeunits.LookupMode := true;
                            if GetSemiManualTestCodeunits.RunModal() = ACTION::LookupOK then begin
                                GetSemiManualTestCodeunits.SetSelectionFilter(AllObjWithCaption);
                                if AllObjWithCaption.FindFirst() then
                                    CodeunitId := AllObjWithCaption."Object ID";
                                LoadTest();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            LoadTest();
                        end;
                    }
                }
            }
            group(StepManualSteps)
            {
                Caption = '';
                Visible = TestExecuting;
                group(Para3)
                {
                    Caption = '';
                    field(CodeunitIdentifier; CodeunitIdentifier)
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        Style = Strong;
                        StyleExpr = TRUE;
                    }
                }
                group(Para2)
                {
                    Caption = 'Manual steps';
                    InstructionalText = 'These are the actions that cannot be automated. Manually perform each of the actions listed for each step. If an error message displays, you''ve found a bug! Copy information about the error after clicking on the Download log button, and provide that when you report the bug.';
                    field(StepHeading; StepHeading)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies title of this set of manual actions';
                    }
                    field(ManualSteps; ManualSteps)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        MultiLine = true;
                        ToolTip = 'Specifies the manual actions for this step in the test.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GetExecutionLog)
            {
                ApplicationArea = All;
                Caption = 'Download log';
                Enabled = TestExecuting;
                InFooterBar = true;
                ToolTip = 'Displays a list of actions executed so far ';

                trigger OnAction()
                var
                    SemiManualExecutionLog: Record "Semi-Manual Execution Log";
                    FileManagement: Codeunit "File Management";
                    File: File;
                    OutStream: OutStream;
                    ServerFileName: Text;
                begin
                    ServerFileName := FileManagement.ServerTempFileName('txt');
                    File.Create(ServerFileName);
                    File.CreateOutStream(OutStream);
                    if SemiManualExecutionLog.FindSet() then
                        repeat
                            OutStream.Write('[' + Format(SemiManualExecutionLog."Time stamp") + '] ');
                            OutStream.WriteText(SemiManualExecutionLog.GetMessage());
                            OutStream.WriteText();
                        until SemiManualExecutionLog.Next() = 0;
                    File.Close();
                    FileManagement.DownloadTempFile(ServerFileName);
                end;
            }
            action(ClearExecutionLog)
            {
                ApplicationArea = All;
                Caption = 'Clear log';
                InFooterBar = true;
                ToolTip = 'Delete all entries in the execution log.';

                trigger OnAction()
                begin
                    SemiManualExecutionLog.DeleteAll();
                end;
            }
            action(Load)
            {
                ApplicationArea = All;
                Caption = 'Load';
                Enabled = NOT TestExecuting;
                InFooterBar = true;
                ToolTip = 'Load the selected codeunit.';

                trigger OnAction()
                begin
                    LoadTest();
                end;
            }
            action(SkipStep)
            {
                ApplicationArea = All;
                Caption = 'Skip step';
                Enabled = TestExecuting;
                InFooterBar = true;
                ToolTip = 'Specifies that the automated actions are complete, and displays the manual actions for the next step.';

                trigger OnAction()
                begin
                    "Skip current step" := true;
                    OnNextStep();
                end;
            }
            action(NextStep)
            {
                ApplicationArea = All;
                Caption = 'Next step';
                Enabled = TestExecuting;
                InFooterBar = true;
                ToolTip = 'Specifies that the manual actions for this step are complete, and displays the actions for the next step.';

                trigger OnAction()
                begin
                    "Skip current step" := false;
                    OnNextStep();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "Step number" > "Total steps" then
            StepHeading := 'TEST COMPLETE'
        else
            StepHeading := StrSubstNo('Step %1 of %2. %3', "Step number", "Total steps", "Step heading");
    end;

    var
        SemiManualExecutionLog: Record "Semi-Manual Execution Log";
        StepHeading: Text;
        ManualSteps: Text;
        CodeunitId: Integer;
        CodeunitIdentifier: Text;
        TestExecuting: Boolean;
        ErrorOccuredErr: Label 'The following error occured: %1', Locked = true;
        TestSuccessfulMsg: Label 'Test successfully completed.';

    local procedure LoadTest()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        TestExecuting := false;
        if CodeunitId <= 0 then
            exit;

        SemiManualExecutionLog.Log(StrSubstNo('Attempting to load codeunit %1.', CodeunitId));
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object ID", CodeunitId);
        if not AllObjWithCaption.FindFirst() then
            exit;

        CodeunitIdentifier := StrSubstNo('%1: %2', CodeunitId, AllObjWithCaption."Object Name");
        Initialize(AllObjWithCaption."Object ID", AllObjWithCaption."Object Name");
        ManualSteps := GetManualSteps();
        TestExecuting := true;
        SemiManualExecutionLog.Log(StrSubstNo('Loaded codeunit %1. Total steps = %2.',
            CodeunitId, "Total steps"));
        CurrPage.Update();
    end;

    local procedure OnNextStep()
    begin
        ClearLastError();
        SemiManualExecutionLog.Log(StrSubstNo('Manual step %1- %2 executed. Attempting to execute the automation post process.',
            "Step number", "Step heading"));
        if CODEUNIT.Run("Codeunit number", Rec) then begin
            ManualSteps := GetManualSteps();
            if "Step number" > "Total steps" then begin
                TestExecuting := false;
                Message(TestSuccessfulMsg);
            end;
            CurrPage.Update();
            if "Skip current step" then
                SemiManualExecutionLog.Log('The automation post process step skipped.')
            else
                SemiManualExecutionLog.Log('The automation post process executed without errors.');
        end else begin
            SemiManualExecutionLog.Log(StrSubstNo(ErrorOccuredErr, GetLastErrorText));
            Error(ErrorOccuredErr, GetLastErrorText);
        end;
    end;
}

