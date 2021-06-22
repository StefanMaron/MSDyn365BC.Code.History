table 1005 "Job WIP G/L Entry"
{
    Caption = 'Job WIP G/L Entry';
    DrillDownPageID = "Job WIP G/L Entries";
    LookupPageID = "Job WIP G/L Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "WIP Entry Amount"; Decimal)
        {
            Caption = 'WIP Entry Amount';
        }
        field(7; "Job Posting Group"; Code[20])
        {
            Caption = 'Job Posting Group';
            TableRelation = "Job Posting Group";
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Applied Costs,Applied Sales,Recognized Costs,Recognized Sales,Accrued Costs,Accrued Sales';
            OptionMembers = "Applied Costs","Applied Sales","Recognized Costs","Recognized Sales","Accrued Costs","Accrued Sales";
        }
        field(9; "G/L Bal. Account No."; Code[20])
        {
            Caption = 'G/L Bal. Account No.';
            TableRelation = "G/L Account";
        }
        field(10; "WIP Method Used"; Code[20])
        {
            Caption = 'WIP Method Used';
            Editable = false;
            TableRelation = "Job WIP Method";
        }
        field(11; "WIP Posting Method Used"; Option)
        {
            Caption = 'WIP Posting Method Used';
            OptionCaption = 'Per Job,Per Job Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(12; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "G/L Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry";
        }
        field(15; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(16; Reverse; Boolean)
        {
            Caption = 'Reverse';
            InitValue = true;
        }
        field(17; "WIP Transaction No."; Integer)
        {
            Caption = 'WIP Transaction No.';
        }
        field(18; "Reverse Date"; Date)
        {
            Caption = 'Reverse Date';
        }
        field(19; "Job Complete"; Boolean)
        {
            Caption = 'Job Complete';
        }
        field(20; "Job WIP Total Entry No."; Integer)
        {
            Caption = 'Job WIP Total Entry No.';
            TableRelation = "Job WIP Total";
        }
        field(60; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(61; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
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
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", Reversed, "Job Complete", Type)
        {
            SumIndexFields = "WIP Entry Amount";
        }
        key(Key3; "Job No.", Reverse, "Job Complete", Type)
        {
            SumIndexFields = "WIP Entry Amount";
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "WIP Transaction No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "Entry No."));
    end;
}

