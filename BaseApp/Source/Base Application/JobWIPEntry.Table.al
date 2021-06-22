table 1004 "Job WIP Entry"
{
    Caption = 'Job WIP Entry';
    DrillDownPageID = "Job WIP Entries";
    LookupPageID = "Job WIP Entries";

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
        field(5; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
        }
        field(6; "WIP Entry Amount"; Decimal)
        {
            AutoFormatType = 1;
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
        field(11; "Job Complete"; Boolean)
        {
            Caption = 'Job Complete';
        }
        field(12; "Job WIP Total Entry No."; Integer)
        {
            Caption = 'Job WIP Total Entry No.';
            TableRelation = "Job WIP Total";
        }
        field(13; Reverse; Boolean)
        {
            Caption = 'Reverse';
            InitValue = true;
        }
        field(14; "WIP Posting Method Used"; Option)
        {
            Caption = 'WIP Posting Method Used';
            OptionCaption = 'Per Job,Per Job Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
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
        key(Key2; "Job No.", "Job Posting Group", "WIP Posting Date", Type, "Job Complete")
        {
            SumIndexFields = "WIP Entry Amount";
        }
        key(Key3; "G/L Account No.")
        {
        }
        key(Key4; "Job No.", "Job Complete", Type)
        {
            SumIndexFields = "WIP Entry Amount";
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure DeleteEntriesForJob(Job: Record Job)
    begin
        SetCurrentKey("Job No.");
        SetRange("Job No.", Job."No.");
        if not IsEmpty then
            DeleteAll(true);
    end;

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

