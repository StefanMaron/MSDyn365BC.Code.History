table 130401 "CAL Test Line"
{
    Caption = 'CAL Test Line';
    ReplicateData = false;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            Caption = 'Test Suite';
            TableRelation = "CAL Test Suite".Name;
        }
        field(2; "Line No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Line No.';
        }
        field(3; "Line Type"; Option)
        {
            Caption = 'Line Type';
            Editable = false;
            InitValue = "Codeunit";
            OptionCaption = 'Group,Codeunit,Function';
            OptionMembers = Group,"Codeunit","Function";

            trigger OnValidate()
            begin
                case "Line Type" of
                    "Line Type"::Group:
                        TestField("Test Codeunit", 0);
                    "Line Type"::Codeunit:
                        begin
                            TestField("Function", '');
                            Name := '';
                        end;
                end;

                UpdateLevelNo;
            end;
        }
        field(4; "Test Codeunit"; Integer)
        {
            Caption = 'Test Codeunit';
            Editable = false;
            TableRelation = IF ("Line Type" = CONST(Codeunit)) AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Codeunit),
                                                                                                  "Object Subtype" = CONST('Test'));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                if "Test Codeunit" = 0 then
                    exit;
                TestField("Function", '');
                if "Line Type" = "Line Type"::Group then
                    TestField("Test Codeunit", 0);
                if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, "Test Codeunit") then
                    Name := AllObjWithCaption."Object Name";
                UpdateLevelNo;
            end;
        }
        field(5; Name; Text[128])
        {
            Caption = 'Name';
            Editable = false;

            trigger OnValidate()
            var
                TestUnitNo: Integer;
            begin
                case "Line Type" of
                    "Line Type"::Group:
                        ;
                    "Line Type"::"Function":
                        TestField(Name, "Function");
                    "Line Type"::Codeunit:
                        begin
                            TestField(Name);
                            Evaluate(TestUnitNo, Name);
                            Validate("Test Codeunit", TestUnitNo);
                        end;
                end;
            end;
        }
        field(6; "Function"; Text[128])
        {
            Caption = 'Function';
            Editable = false;

            trigger OnValidate()
            begin
                if "Line Type" <> "Line Type"::"Function" then begin
                    TestField("Function", '');
                    exit;
                end;
                UpdateLevelNo;
                Name := "Function";
            end;
        }
        field(7; Run; Boolean)
        {
            Caption = 'Run';

            trigger OnValidate()
            begin
                if "Function" = 'OnRun' then
                    Error(CannotChangeValueErr);
                CALTestLine.Copy(Rec);
                UpdateGroup(CALTestLine);
                UpdateChildren(CALTestLine);
            end;
        }
        field(8; Result; Option)
        {
            Caption = 'Result';
            Editable = false;
            OptionCaption = ' ,Failure,Success,Skipped';
            OptionMembers = " ",Failure,Success,Skipped;

            trigger OnValidate()
            begin
                "First Error" := '';
            end;
        }
        field(9; "First Error"; Text[250])
        {
            Caption = 'First Error';
            Editable = false;
        }
        field(10; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
            Editable = false;
        }
        field(11; "Finish Time"; DateTime)
        {
            Caption = 'Finish Time';
            Editable = false;
        }
        field(12; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
        field(13; "Hit Objects"; Integer)
        {
            CalcFormula = Count ("CAL Test Coverage Map" WHERE("Test Codeunit ID" = FIELD("Test Codeunit")));
            Caption = 'Hit Objects';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite", Result, "Line Type", Run)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteChildren;
    end;

    trigger OnInsert()
    begin
        if "Line Type" = "Line Type"::Codeunit then
            CALTestMgt.RunSuite(Rec, false);
    end;

    trigger OnModify()
    begin
        if ("Line Type" = "Line Type"::Codeunit) and
           ("Test Codeunit" <> xRec."Test Codeunit")
        then
            CALTestMgt.RunSuite(Rec, false);
    end;

    var
        CALTestLine: Record "CAL Test Line";
        CannotChangeValueErr: Label 'You cannot change the value of the OnRun.', Locked = true;
        CALTestMgt: Codeunit "CAL Test Management";

    procedure UpdateGroup(var CALTestLine: Record "CAL Test Line")
    var
        CopyOfCALTestLine: Record "CAL Test Line";
        OutOfGroup: Boolean;
    begin
        if not CALTestLine.Run then
            exit;
        if not ("Line Type" = "Line Type"::"Function") then
            exit;

        CopyOfCALTestLine.Copy(CALTestLine);
        with CALTestLine do begin
            Reset;
            SetRange("Test Suite", "Test Suite");
            repeat
                OutOfGroup :=
                  (Next(-1) = 0) or
                  ("Test Codeunit" <> CopyOfCALTestLine."Test Codeunit");

                if (("Line Type" in ["Line Type"::Group, "Line Type"::Codeunit]) or ("Function" = 'OnRun')) and
                   not Run
                then begin
                    Run := true;
                    Modify;
                end;
            until OutOfGroup;
        end;
        CALTestLine.Copy(CopyOfCALTestLine);
    end;

    procedure UpdateChildren(var CALTestLine: Record "CAL Test Line")
    var
        CopyOfCALTestLine: Record "CAL Test Line";
    begin
        if CALTestLine."Line Type" = "Line Type"::"Function" then
            exit;

        CopyOfCALTestLine.Copy(CALTestLine);
        with CALTestLine do begin
            Reset;
            SetRange("Test Suite", "Test Suite");
            while (Next <> 0) and not ("Line Type" in ["Line Type"::Group, CopyOfCALTestLine."Line Type"]) do begin
                Run := CopyOfCALTestLine.Run;
                Modify;
            end;
        end;
        CALTestLine.Copy(CopyOfCALTestLine);
    end;

    procedure GetMinCodeunitLineNo() MinLineNo: Integer
    var
        CALTestLine: Record "CAL Test Line";
    begin
        with CALTestLine do begin
            Copy(Rec);
            Reset;
            SetRange("Test Suite", "Test Suite");

            MinLineNo := "Line No.";
            repeat
                MinLineNo := "Line No.";
            until (Level < 2) or (Next(-1) = 0);
        end;
    end;

    procedure GetMaxGroupLineNo() MaxLineNo: Integer
    var
        CALTestLine: Record "CAL Test Line";
    begin
        with CALTestLine do begin
            Copy(Rec);
            Reset;
            SetRange("Test Suite", "Test Suite");

            MaxLineNo := "Line No.";
            while (Next <> 0) and (Level >= Rec.Level) do
                MaxLineNo := "Line No.";
        end;
    end;

    procedure GetMaxCodeunitLineNo(var NoOfFunctions: Integer) MaxLineNo: Integer
    var
        CALTestLine: Record "CAL Test Line";
    begin
        TestField("Test Codeunit");
        NoOfFunctions := 0;

        with CALTestLine do begin
            Copy(Rec);
            Reset;
            SetRange("Test Suite", "Test Suite");
            MaxLineNo := "Line No.";
            while (Next <> 0) and ("Line Type" = "Line Type"::"Function") do begin
                MaxLineNo := "Line No.";
                if Run then
                    NoOfFunctions += 1;
            end;
        end;
    end;

    procedure DeleteChildren()
    var
        CopyOfCALTestLine: Record "CAL Test Line";
    begin
        CopyOfCALTestLine.Copy(Rec);
        Reset;
        SetRange("Test Suite", "Test Suite");
        while (Next <> 0) and (Level > CopyOfCALTestLine.Level) do
            Delete(true);
        Copy(CopyOfCALTestLine);
    end;

    procedure CalcTestResults(var Success: Integer; var Fail: Integer; var Skipped: Integer; var NotExecuted: Integer)
    var
        CALTestLine: Record "CAL Test Line";
    begin
        CALTestLine.SetRange("Test Suite", "Test Suite");
        CALTestLine.SetFilter("Function", '<>%1', 'OnRun');
        CALTestLine.SetRange("Line Type", "Line Type"::"Function");

        CALTestLine.SetRange(Result, Result::Success);
        Success := CALTestLine.Count();

        CALTestLine.SetRange(Result, Result::Failure);
        Fail := CALTestLine.Count();

        CALTestLine.SetRange(Result, Result::Skipped);
        Skipped := CALTestLine.Count();

        CALTestLine.SetRange(Result, Result::" ");
        NotExecuted := CALTestLine.Count();
    end;

    local procedure UpdateLevelNo()
    begin
        case "Line Type" of
            "Line Type"::Group:
                Level := 0;
            "Line Type"::Codeunit:
                Level := 1;
            else
                Level := 2;
        end;
    end;

    procedure ShowTestResults()
    var
        CALTestResult: Record "CAL Test Result";
    begin
        CALTestResult.SetRange("Codeunit ID", "Test Codeunit");
        if "Function" <> '' then
            CALTestResult.SetRange("Function Name", "Function");
        if CALTestResult.FindLast then;
        PAGE.Run(PAGE::"CAL Test Results", CALTestResult);
    end;
}

