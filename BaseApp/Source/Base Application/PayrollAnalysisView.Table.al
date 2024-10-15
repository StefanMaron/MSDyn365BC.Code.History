table 14965 "Payroll Analysis View"
{
    Caption = 'Payroll Analysis View';
    LookupPageID = "Payroll Analysis View List";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
            Editable = false;
        }
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
            Editable = false;
        }
        field(7; "Update on Posting"; Boolean)
        {
            Caption = 'Update on Posting';
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked and "Refresh When Unblocked" then begin
                    ValidateDelete(FieldCaption(Blocked));
                    PayrollAnalysisViewReset;
                    "Refresh When Unblocked" := false;
                end;
            end;
        }
        field(9; "Payroll Element Filter"; Code[250])
        {
            Caption = 'Payroll Element Filter';
            TableRelation = "Payroll Element";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
                PayrollElement: Record "Payroll Element";
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Payroll Element Filter" = '') and ("Payroll Element Filter" <> '') then begin
                    ValidateModify(FieldCaption("Payroll Element Filter"));
                    PayrollElement.SetFilter(Code, "Payroll Element Filter");
                    if PayrollElement.FindSet then
                        repeat
                            PayrollElement.Mark := true;
                        until PayrollElement.Next = 0;
                    PayrollElement.SetRange(Code);
                    if PayrollElement.FindSet then
                        repeat
                            if not PayrollElement.Mark then begin
                                PayrollAnalysisViewEntry.SetRange("Analysis View Code", Code);
                                PayrollAnalysisViewEntry.SetRange("Element Code", PayrollElement.Code);
                                PayrollAnalysisViewEntry.DeleteAll();
                            end;
                        until PayrollElement.Next = 0;
                end;
                if ("Last Entry No." <> 0) and ("Payroll Element Filter" <> xRec."Payroll Element Filter") and
                   (xRec."Payroll Element Filter" <> '')
                then begin
                    ValidateDelete(FieldCaption("Payroll Element Filter"));
                    PayrollAnalysisViewReset;
                end;
            end;
        }
        field(10; "Employee Filter"; Code[250])
        {
            Caption = 'Employee Filter';
            TableRelation = Employee;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Employee: Record Employee;
                TempEmployee: Record Employee temporary;
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Employee Filter" = '') and
                   ("Employee Filter" <> xRec."Employee Filter")
                then begin
                    ValidateModify(FieldCaption("Employee Filter"));
                    if Employee.FindSet then
                        repeat
                            TempEmployee := Employee;
                            TempEmployee.Insert();
                        until Employee.Next = 0;
                    TempEmployee.Init();
                    TempEmployee."No." := '';
                    TempEmployee.Insert();
                    TempEmployee.SetFilter("No.", "Employee Filter");
                    TempEmployee.DeleteAll();
                    TempEmployee.SetRange("No.");
                    if TempEmployee.FindSet then
                        repeat
                            PayrollAnalysisViewEntry.SetRange("Analysis View Code", Code);
                            PayrollAnalysisViewEntry.SetRange("Employee No.", TempEmployee."No.");
                            PayrollAnalysisViewEntry.DeleteAll();
                        until TempEmployee.Next = 0
                end;
                if ("Last Entry No." <> 0) and (xRec."Employee Filter" <> '') and
                   ("Employee Filter" <> xRec."Employee Filter")
                then begin
                    ValidateDelete(FieldCaption("Employee Filter"));
                    PayrollAnalysisViewReset;
                end;
            end;
        }
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Starting Date" <> xRec."Starting Date") then begin
                    ValidateDelete(FieldCaption("Starting Date"));
                    PayrollAnalysisViewReset;
                end;
            end;
        }
        field(12; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            InitValue = Day;
            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
            OptionMembers = "None",Day,Week,Month,Quarter,Year,Period;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Date Compression" <> xRec."Date Compression") then begin
                    ValidateDelete(FieldCaption("Date Compression"));
                    PayrollAnalysisViewReset;
                end;
            end;
        }
        field(13; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 1 Code", 20, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 1 Code"), "Dimension 1 Code", xRec."Dimension 1 Code");
                Modify;
            end;
        }
        field(14; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 2 Code", 21, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 2 Code"), "Dimension 2 Code", xRec."Dimension 2 Code");
                Modify;
            end;
        }
        field(15; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 3 Code", 22, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 3 Code"), "Dimension 3 Code", xRec."Dimension 3 Code");
                Modify;
            end;
        }
        field(16; "Dimension 4 Code"; Code[20])
        {
            Caption = 'Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 4 Code", 23, '', Code, 0) then
                    Error(Text000, Dim.GetCheckDimErr);
                ModifyDim(FieldCaption("Dimension 4 Code"), "Dimension 4 Code", xRec."Dimension 4 Code");
                Modify;
            end;
        }
        field(18; "Refresh When Unblocked"; Boolean)
        {
            Caption = 'Refresh When Unblocked';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PayrollAnalysisViewFilter: Record "Payroll Analysis View Filter";
    begin
        PayrollAnalysisViewReset;
        PayrollAnalysisViewFilter.SetRange("Analysis View Code", Code);
        PayrollAnalysisViewFilter.DeleteAll();
    end;

    var
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        NewPayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
        Dim: Record Dimension;
        Text000: Label 'You cannot use the same dimension twice in the same analysis view. Error %1.';
        Text001: Label 'The dimension %1 is used in the analysis view %2. You must therefore retain the dimension to keep consistency between the analysis view and the Item entries.';
        Text011: Label 'If you change the contents of the %1 field, the analysis view entries will be deleted.\You will have to update again.\\Do you want to enter a new value?';
        Text013: Label 'The update has been interrupted in response to the warning.';
        Text014: Label 'If you change the contents of the %1 field, the analysis view entries will be changed as well.\\Do you want to enter a new value?';

    [Scope('OnPrem')]
    procedure ModifyDim(DimFieldName: Text[100]; DimValue: Code[20]; xDimValue: Code[20])
    begin
        if ("Last Entry No." <> 0) and (DimValue <> xDimValue) then begin
            if DimValue <> '' then begin
                ValidateDelete(DimFieldName);
                PayrollAnalysisViewReset;
            end;
            if DimValue = '' then begin
                ValidateModify(DimFieldName);
                case DimFieldName of
                    FieldCaption("Dimension 1 Code"):
                        PayrollAnalysisViewEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                    FieldCaption("Dimension 2 Code"):
                        PayrollAnalysisViewEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                    FieldCaption("Dimension 3 Code"):
                        PayrollAnalysisViewEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                    FieldCaption("Dimension 4 Code"):
                        PayrollAnalysisViewEntry.SetFilter("Dimension 4 Value Code", '<>%1', '');
                end;
                PayrollAnalysisViewEntry.SetRange("Analysis View Code", Code);
                if PayrollAnalysisViewEntry.FindSet then
                    repeat
                        PayrollAnalysisViewEntry.Delete();
                        NewPayrollAnalysisViewEntry := PayrollAnalysisViewEntry;
                        case DimFieldName of
                            FieldCaption("Dimension 1 Code"):
                                NewPayrollAnalysisViewEntry."Dimension 1 Value Code" := '';
                            FieldCaption("Dimension 2 Code"):
                                NewPayrollAnalysisViewEntry."Dimension 2 Value Code" := '';
                            FieldCaption("Dimension 3 Code"):
                                NewPayrollAnalysisViewEntry."Dimension 3 Value Code" := '';
                            FieldCaption("Dimension 4 Code"):
                                NewPayrollAnalysisViewEntry."Dimension 4 Value Code" := '';
                        end;
                        InsertPayrollAnalysisViewEntry;
                    until PayrollAnalysisViewEntry.Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertPayrollAnalysisViewEntry()
    begin
        if not NewPayrollAnalysisViewEntry.Insert() then begin
            NewPayrollAnalysisViewEntry.Find;
            NewPayrollAnalysisViewEntry."Payroll Amount" :=
              NewPayrollAnalysisViewEntry."Payroll Amount" + PayrollAnalysisViewEntry."Payroll Amount";
            NewPayrollAnalysisViewEntry."Taxable Amount" :=
              NewPayrollAnalysisViewEntry."Taxable Amount" + PayrollAnalysisViewEntry."Taxable Amount";
            NewPayrollAnalysisViewEntry.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure PayrollAnalysisViewReset()
    var
        PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry";
    begin
        PayrollAnalysisViewEntry.SetRange("Analysis View Code", Code);
        PayrollAnalysisViewEntry.DeleteAll();
        "Last Entry No." := 0;
        "Last Date Updated" := 0D;
    end;

    local procedure CheckDimIsRetained(ObjectType: Integer; ObjectID: Integer; DimCode: Code[20]; AnalysisViewCode: Code[10])
    var
        SelectedDim: Record "Selected Dimension";
    begin
        if DimCode <> '' then
            if not SelectedDim.Get(UserId, ObjectType, ObjectID, '', DimCode) then
                Error(Text001, DimCode, AnalysisViewCode);
    end;

    [Scope('OnPrem')]
    procedure ValidateDelete(FieldName: Text[250])
    var
        Question: Text[250];
    begin
        Question := StrSubstNo(Text011, FieldName);
        if not Confirm(Question, true) then
            Error(Text013);
    end;

    [Scope('OnPrem')]
    procedure ValidateModify(FieldName: Text[250])
    var
        Question: Text[250];
    begin
        Question := StrSubstNo(Text014, FieldName);
        if not Confirm(Question, true) then
            Error(Text013);
    end;
}

