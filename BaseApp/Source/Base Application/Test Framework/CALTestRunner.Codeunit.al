codeunit 130400 "CAL Test Runner"
{
    Subtype = TestRunner;
    TableNo = "CAL Test Line";
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        if CALTestSuite.Get("Test Suite") then begin
            CALTestLine.Copy(Rec);
            CALTestLine.SetRange("Test Suite", "Test Suite");
            RunTests();
        end;
    end;

    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestLine: Record "CAL Test Line";
        CALTestLineFunction: Record "CAL Test Line";
        CALTestMgt: Codeunit "CAL Test Management";
        CALTestRunnerPublisher: Codeunit "CAL Test Runner Publisher";
        Window: Dialog;
        CompanyWorkDate: Date;
        TestRunNo: Integer;
        MaxLineNo: Integer;
        MinLineNo: Integer;
        "Filter": Text;
        ExecutingTestsMsg: Label 'Executing Tests...\', Locked = true;
        TestSuiteMsg: Label 'Test Suite    #1###################\', Locked = true;
        TestCodeunitMsg: Label 'Test Codeunit #2################### @3@@@@@@@@@@@@@\', Locked = true;
        TestFunctionMsg: Label 'Test Function #4################### @5@@@@@@@@@@@@@\', Locked = true;
        NoOfResultsMsg: Label 'No. of Results with:\', Locked = true;
        WindowUpdateDateTime: DateTime;
        WindowIsOpen: Boolean;
        WindowTestSuite: Code[10];
        WindowTestGroup: Text;
        WindowTestCodeunit: Text;
        WindowTestFunction: Text;
        WindowTestSuccess: Integer;
        WindowTestFailure: Integer;
        WindowTestSkip: Integer;
        SuccessMsg: Label '    Success   #6######\', Locked = true;
        FailureMsg: Label '    Failure   #7######\', Locked = true;
        SkipMsg: Label '    Skip      #8######\', Locked = true;
        WindowNoOfTestCodeunitTotal: Integer;
        WindowNoOfFunctionTotal: Integer;
        WindowNoOfTestCodeunit: Integer;
        WindowNoOfFunction: Integer;

    local procedure RunTests()
    var
        CALTestResult: Record "CAL Test Result";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        OnBeforeRunTests(CALTestLine);
        with CALTestLine do begin
            OpenWindow();
            ModifyAll(Result, Result::" ");
            ModifyAll("First Error", '');
            Commit();
            TestRunNo := CALTestResult.LastTestRunNo() + 1;
            CompanyWorkDate := WorkDate();
            Filter := GetView();
            WindowNoOfTestCodeunitTotal := CountTestCodeunitsToRun(CALTestLine);
            SetRange("Line Type", "Line Type"::Codeunit);
            if Find('-') then
                repeat
                    if UpdateTCM() then
                        CodeCoverageMgt.Start(true);

                    MinLineNo := "Line No.";
                    MaxLineNo := GetMaxCodeunitLineNo(WindowNoOfFunctionTotal);
                    if Run then
                        WindowNoOfTestCodeunit += 1;
                    WindowNoOfFunction := 0;

                    if CALTestMgt.ISPUBLISHMODE() then
                        DeleteChildren();

                    CODEUNIT.Run("Test Codeunit");

                    if UpdateTCM() then begin
                        CodeCoverageMgt.Stop();
                        CALTestMgt.ExtendTestCoverage("Test Codeunit");
                    end;
                until Next() = 0;

            CloseWindow();
        end;
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        CALTestRunnerPublisher.SetSeed(1);
        ApplicationArea('');
        WorkDate := CompanyWorkDate;
        UpDateWindow(
          CALTestLine."Test Suite", CALTestLine.Name, CodeunitName, FunctionName,
          WindowTestSuccess, WindowTestFailure, WindowTestSkip,
          WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
          WindowNoOfTestCodeunit, WindowNoOfFunction);

        InitCodeunitLine();

        if FunctionName = '' then begin
            CALTestLine.Result := CALTestLine.Result::" ";
            CALTestLine."Start Time" := CurrentDateTime;
            exit(true);
        end;

        if CALTestMgt.ISPUBLISHMODE() then
            AddTestMethod(FunctionName)
        else begin
            if not TryFindTestFunctionInGroup(FunctionName) then
                exit(false);

            InitTestFunctionLine();
            if not CALTestLineFunction.Run or not CALTestLine.Run then
                exit(false);

            UpDateWindow(
              CALTestLine."Test Suite", CALTestLine.Name, CodeunitName, FunctionName,
              WindowTestSuccess, WindowTestFailure, WindowTestSkip,
              WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
              WindowNoOfTestCodeunit, WindowNoOfFunction + 1);
        end;

        if FunctionName = 'OnRun' then
            exit(true);
        exit(CALTestMgt.ISTESTMODE());
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        if (FunctionName <> '') and (FunctionName <> 'OnRun') then
            if IsSuccess then
                UpDateWindow(
                  WindowTestSuite, WindowTestGroup, WindowTestCodeunit, WindowTestFunction,
                  WindowTestSuccess + 1, WindowTestFailure, WindowTestSkip,
                  WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
                  WindowNoOfTestCodeunit, WindowNoOfFunction)
            else
                UpDateWindow(
                  WindowTestSuite, WindowTestGroup, WindowTestCodeunit, WindowTestFunction,
                  WindowTestSuccess, WindowTestFailure + 1, WindowTestSkip,
                  WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
                  WindowNoOfTestCodeunit, WindowNoOfFunction);

        UpdateCodeunitLine(IsSuccess);

        if FunctionName = '' then
            exit;

        UpdateTestFunctionLine(IsSuccess);

        Commit();
        ApplicationArea('');
        ClearLastError();
    end;

    procedure AddTestMethod(FunctionName: Text[128])
    begin
        with CALTestLineFunction do begin
            CALTestLineFunction := CALTestLine;
            "Line No." := MaxLineNo + 1;
            "Line Type" := "Line Type"::"Function";
            Validate("Function", FunctionName);
            Run := CALTestLine.Run;
            "Start Time" := CurrentDateTime;
            "Finish Time" := CurrentDateTime;
            Insert(true);
        end;
        MaxLineNo := MaxLineNo + 1;
    end;

    procedure InitCodeunitLine()
    begin
        with CALTestLine do begin
            if CALTestMgt.ISTESTMODE() and (Result = Result::" ") then
                Result := Result::Skipped;
            "Finish Time" := CurrentDateTime;
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCodeunitLine(IsSuccess: Boolean)
    begin
        with CALTestLine do begin
            if CALTestMgt.ISPUBLISHMODE() and IsSuccess then
                Result := Result::" "
            else
                if Result <> Result::Failure then
                    if IsSuccess then
                        Result := Result::Success
                    else begin
                        "First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen("First Error"));
                        Result := Result::Failure
                    end;
            "Finish Time" := CurrentDateTime;
            Modify();
        end;
    end;

    procedure InitTestFunctionLine()
    begin
        with CALTestLineFunction do begin
            "Start Time" := CurrentDateTime;
            "Finish Time" := "Start Time";
            Result := Result::Skipped;
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTestFunctionLine(IsSuccess: Boolean)
    var
        CALTestResult: Record "CAL Test Result";
    begin
        with CALTestLineFunction do begin
            if IsSuccess then
                Result := CALTestLine.Result::Success
            else begin
                "First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen("First Error"));
                Result := Result::Failure
            end;
            "Finish Time" := CurrentDateTime;
            Modify();

            CALTestResult.Add(CALTestLineFunction, TestRunNo);
        end;
    end;

    procedure TryFindTestFunctionInGroup(FunctionName: Text[128]): Boolean
    begin
        with CALTestLineFunction do begin
            Reset();
            SetView(Filter);
            SetRange("Test Suite", CALTestLine."Test Suite");
            SetRange("Test Codeunit", CALTestLine."Test Codeunit");
            SetRange("Function", FunctionName);
            if Find('-') then
                repeat
                    if "Line No." in [MinLineNo .. MaxLineNo] then
                        exit(true);
                until Next() = 0;
            exit(false);
        end;
    end;

    procedure CountTestCodeunitsToRun(var CALTestLine: Record "CAL Test Line") NoOfTestCodeunits: Integer
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        with CALTestLine do begin
            SetRange("Line Type", "Line Type"::Codeunit);
            SetRange(Run, true);
            NoOfTestCodeunits := Count;
        end;
    end;

    procedure UpdateTCM(): Boolean
    begin
        exit(CALTestMgt.ISTESTMODE() and CALTestSuite."Update Test Coverage Map");
    end;

    local procedure OpenWindow()
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        Window.Open(
          ExecutingTestsMsg +
          TestSuiteMsg +
          TestCodeunitMsg +
          TestFunctionMsg +
          NoOfResultsMsg +
          SuccessMsg +
          FailureMsg +
          SkipMsg);
        WindowIsOpen := true;
    end;

    local procedure UpDateWindow(NewWindowTestSuite: Code[10]; NewWindowTestGroup: Text; NewWindowTestCodeunit: Text; NewWindowTestFunction: Text; NewWindowTestSuccess: Integer; NewWindowTestFailure: Integer; NewWindowTestSkip: Integer; NewWindowNoOfTestCodeunitTotal: Integer; NewWindowNoOfFunctionTotal: Integer; NewWindowNoOfTestCodeunit: Integer; NewWindowNoOfFunction: Integer)
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        WindowTestSuite := NewWindowTestSuite;
        WindowTestGroup := NewWindowTestGroup;
        WindowTestCodeunit := NewWindowTestCodeunit;
        WindowTestFunction := NewWindowTestFunction;
        WindowTestSuccess := NewWindowTestSuccess;
        WindowTestFailure := NewWindowTestFailure;
        WindowTestSkip := NewWindowTestSkip;

        WindowNoOfTestCodeunitTotal := NewWindowNoOfTestCodeunitTotal;
        WindowNoOfFunctionTotal := NewWindowNoOfFunctionTotal;
        WindowNoOfTestCodeunit := NewWindowNoOfTestCodeunit;
        WindowNoOfFunction := NewWindowNoOfFunction;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();
            Window.Update(1, WindowTestSuite);
            Window.Update(2, WindowTestCodeunit);
            Window.Update(4, WindowTestFunction);
            Window.Update(6, WindowTestSuccess);
            Window.Update(7, WindowTestFailure);
            Window.Update(8, WindowTestSkip);

            if NewWindowNoOfTestCodeunitTotal <> 0 then
                Window.Update(3, Round(NewWindowNoOfTestCodeunit / NewWindowNoOfTestCodeunitTotal * 10000, 1));
            if NewWindowNoOfFunctionTotal <> 0 then
                Window.Update(5, Round(NewWindowNoOfFunction / NewWindowNoOfFunctionTotal * 10000, 1));
        end;
    end;

    local procedure CloseWindow()
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        if WindowIsOpen then begin
            Window.Close();
            WindowIsOpen := false;
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if true in [WindowUpdateDateTime = 0DT, CurrentDateTime - WindowUpdateDateTime >= 1000] then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunTests(var CALTestLine: Record "CAL Test Line")
    begin
    end;
}

