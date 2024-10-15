table 17416 "Posted Payroll Document"
{
    Caption = 'Posted Payroll Document';
    DataCaptionFields = "No.", "Employee No.";
    LookupPageID = "Posted Payroll Documents";

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
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(5; "Posting Type"; Option)
        {
            Caption = 'Posting Type';
            OptionCaption = 'Calculation,Data Entry';
            OptionMembers = Calculation,"Data Entry";
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(10; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(11; "Reversing Document No."; Code[20])
        {
            Caption = 'Reversing Document No.';
            TableRelation = "Posted Payroll Document" WHERE("Employee No." = FIELD("Employee No."));
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("P.Payroll Document"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Reversed; Boolean)
        {
            Caption = 'Reversed';
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
            CalcFormula = Sum ("Posted Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                                     "Element Type" = CONST(Wage)));
            Caption = 'Wage Amount';
            FieldClass = FlowField;
        }
        field(21; "Bonus Amount"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                                     "Element Type" = CONST(Bonus)));
            Caption = 'Bonus Amount';
            FieldClass = FlowField;
        }
        field(22; "Other Gain Amount"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                                     "Element Type" = CONST(Other)));
            Caption = 'Other Gain Amount';
            FieldClass = FlowField;
        }
        field(23; "Deduction Amount"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
                                                                                     "Element Type" = CONST(Deduction)));
            Caption = 'Deduction Amount';
            FieldClass = FlowField;
        }
        field(24; "Income Tax Amount"; Decimal)
        {
            CalcFormula = Sum ("Posted Payroll Document Line"."Payroll Amount" WHERE("Document No." = FIELD("No."),
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
                ShowDimensions;
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
        fieldgroup(DropDown; "No.", "Employee No.", "Period Code", "Posting Date")
        {
        }
    }

    trigger OnDelete()
    begin
        PostedPayrollDocLine.SetRange("Document No.", "No.");
        if not PostedPayrollDocLine.IsEmpty then
            PostedPayrollDocLine.DeleteAll();
    end;

    var
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "No.");
        NavigateForm.Run;
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."));
    end;

    [Scope('OnPrem')]
    procedure CalcPayrollAmount(): Decimal
    begin
        PostedPayrollDocLine.Reset();
        PostedPayrollDocLine.SetRange("Document No.", "No.");
        PostedPayrollDocLine.SetFilter("Element Type", '%1|%2|%3|%4|%5',
          PostedPayrollDocLine."Element Type"::Wage,
          PostedPayrollDocLine."Element Type"::Bonus,
          PostedPayrollDocLine."Element Type"::Deduction,
          PostedPayrollDocLine."Element Type"::Other,
          PostedPayrollDocLine."Element Type"::"Income Tax");
        PostedPayrollDocLine.SetRange(
          "Posting Type",
          PostedPayrollDocLine."Posting Type"::Charge,
          PostedPayrollDocLine."Posting Type"::Liability);
        PostedPayrollDocLine.CalcSums("Payroll Amount");
        exit(PostedPayrollDocLine."Payroll Amount");
    end;
}

