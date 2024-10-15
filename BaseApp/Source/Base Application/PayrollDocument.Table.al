table 17414 "Payroll Document"
{
    Caption = 'Payroll Document';
    DataCaptionFields = "No.", "Employee No.";
    LookupPageID = "Payroll Documents";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                PayrollDocLine.SetRange("Document No.", "No.");
                if not PayrollDocLine.IsEmpty then
                    Error(Text000, FieldCaption("Employee No."));

                CreateDim(DATABASE::Employee, "Employee No.");
            end;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(4; "Posting Description"; Text[50])
        {
            Caption = 'Posting Description';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(5; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            OptionCaption = 'Calculation,Data Entry';
            OptionMembers = Calculation,"Data Entry";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(10; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if not Correction then
                    TestField("Reversing Document No.", '');
            end;
        }
        field(11; "Reversing Document No."; Code[20])
        {
            Caption = 'Reversing Document No.';
            TableRelation = "Posted Payroll Document" WHERE("Employee No." = FIELD("Employee No."),
                                                             Reversed = CONST(false));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Reversing Document No." <> xRec."Reversing Document No." then
                    if "Reversing Document No." <> '' then
                        TestField(Correction, true);
            end;
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("Payroll Document"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(15; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with PayrollDocument do begin
                    PayrollDocument := Rec;
                    HRSetup.Get;
                    TestNoSeries;
                    if NoSeriesMgt.LookupSeries(HRSetup."Posted Payroll Document Nos.", "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := PayrollDocument;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    HRSetup.Get;
                    TestNoSeries;
                    NoSeriesMgt.TestSeries(HRSetup."Posted Payroll Document Nos.", "Posting No. Series");
                end;
            end;
        }
        field(18; "Calc Group Code"; Code[10])
        {
            Caption = 'Calc Group Code';
            Editable = false;
            TableRelation = "Payroll Calc Group";
        }
        field(19; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(20; "Wage Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                              "Element Type" = CONST(Wage)));
            Caption = 'Wage Amount';
            FieldClass = FlowField;
        }
        field(21; "Bonus Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                              "Element Type" = CONST(Bonus)));
            Caption = 'Bonus Amount';
            FieldClass = FlowField;
        }
        field(22; "Other Gain Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                              "Element Type" = CONST(Other)));
            Caption = 'Other Gain Amount';
            FieldClass = FlowField;
        }
        field(23; "Deduction Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                              "Element Type" = CONST(Deduction)));
            Caption = 'Deduction Amount';
            FieldClass = FlowField;
        }
        field(24; "Income Tax Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                              "Element Type" = CONST("Income Tax")));
            Caption = 'Income Tax Amount';
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Employee No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if ("Period Code" <> '') and ("Employee No." <> '') then
            if "Posting Type" = "Posting Type"::Calculation then begin
                PayrollStatus.Get("Period Code", "Employee No.");
                if PayrollStatus."Payroll Status" = PayrollStatus."Payroll Status"::Calculated then begin
                    PayrollStatus."Payroll Status" := PayrollStatus."Payroll Status"::" ";
                    PayrollStatus.Modify;
                end;
            end;

        PayrollDocLine.Reset;
        PayrollDocLine.SetRange("Document No.", "No.");
        if not PayrollDocLine.IsEmpty then
            PayrollDocLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            HRSetup.Get;
            TestNoSeries;
            NoSeriesMgt.InitSeries(
              HRSetup."Payroll Document Nos.", xRec."No. Series", "Posting Date",
              "No.", "No. Series");
        end;

        if "Posting Date" = 0D then
            "Posting Date" := WorkDate;
    end;

    var
        HRSetup: Record "Human Resources Setup";
        PayrollDocument: Record "Payroll Document";
        PayrollDocLine: Record "Payroll Document Line";
        PayrollStatus: Record "Payroll Status";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'You cannot modify %1 if there are document lines.';
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Scope('OnPrem')]
    procedure AssistEdit(OldPayrollDocument: Record "Payroll Document"): Boolean
    begin
        PayrollDocument.Copy(Rec);
        HRSetup.Get;
        TestNoSeries;
        if NoSeriesMgt.SelectSeries(HRSetup."Payroll Document Nos.", OldPayrollDocument."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            Rec := PayrollDocument;
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        HRSetup.TestField("Payroll Document Nos.");
        HRSetup.TestField("Posted Payroll Document Nos.");
    end;

    [Scope('OnPrem')]
    procedure DocLinesExist(): Boolean
    begin
        PayrollDocLine.Reset;
        PayrollDocLine.SetRange("Document No.", "No.");
        exit(not PayrollDocLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get;
        TableID[1] := Type1;
        No[1] := No1;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(TableID, No, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and DocLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if DocLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', 0, "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if DocLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text064) then
            exit;

        PayrollDocLine.Reset;
        PayrollDocLine.SetRange("Document No.", "No.");
        PayrollDocLine.LockTable;
        if PayrollDocLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(PayrollDocLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PayrollDocLine."Dimension Set ID" <> NewDimSetID then begin
                    PayrollDocLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      PayrollDocLine."Dimension Set ID", PayrollDocLine."Shortcut Dimension 1 Code", PayrollDocLine."Shortcut Dimension 2 Code");
                    PayrollDocLine.Modify;
                end;
            until PayrollDocLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcPayrollAmount(): Decimal
    begin
        PayrollDocLine.Reset;
        PayrollDocLine.SetRange("Document No.", "No.");
        PayrollDocLine.SetFilter("Element Type", '%1|%2|%3|%4|%5',
          PayrollDocLine."Element Type"::Wage,
          PayrollDocLine."Element Type"::Bonus,
          PayrollDocLine."Element Type"::Deduction,
          PayrollDocLine."Element Type"::Other,
          PayrollDocLine."Element Type"::"Income Tax");
        PayrollDocLine.SetRange(
          "Posting Type",
          PayrollDocLine."Posting Type"::Charge,
          PayrollDocLine."Posting Type"::Liability);
        PayrollDocLine.CalcSums("Payroll Amount");
        exit(PayrollDocLine."Payroll Amount");
    end;
}

