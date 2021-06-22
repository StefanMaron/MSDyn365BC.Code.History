table 5617 "FA Register"
{
    Caption = 'FA Register';
    LookupPageID = "FA Registers";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(8; "Journal Type"; Option)
        {
            Caption = 'Journal Type';
            OptionCaption = 'G/L,Fixed Asset';
            OptionMembers = "G/L","Fixed Asset";
        }
        field(9; "G/L Register No."; Integer)
        {
            BlankZero = true;
            Caption = 'G/L Register No.';
            TableRelation = "G/L Register";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(10; "From Maintenance Entry No."; Integer)
        {
            Caption = 'From Maintenance Entry No.';
            TableRelation = "Maintenance Ledger Entry";
        }
        field(11; "To Maintenance Entry No."; Integer)
        {
            Caption = 'To Maintenance Entry No.';
            TableRelation = "Maintenance Ledger Entry";
        }
        field(13; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure GetLastGLRegisterNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("G/L Register No.")))
    end;

}

