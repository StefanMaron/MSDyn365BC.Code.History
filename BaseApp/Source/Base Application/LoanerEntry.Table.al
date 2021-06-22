table 5914 "Loaner Entry"
{
    Caption = 'Loaner Entry';
    DrillDownPageID = "Loaner Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            TableRelation = Loaner;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item";
        }
        field(6; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";
        }
        field(7; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(8; "Date Lent"; Date)
        {
            Caption = 'Date Lent';
        }
        field(9; "Time Lent"; Time)
        {
            Caption = 'Time Lent';
        }
        field(10; "Date Received"; Date)
        {
            Caption = 'Date Received';
        }
        field(11; "Time Received"; Time)
        {
            Caption = 'Time Received';
        }
        field(12; Lent; Boolean)
        {
            Caption = 'Lent';
        }
        field(14; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Quote,Order';
            OptionMembers = " ",Quote,"Order";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Loaner No.", "Document Type", "Document No.")
        {
        }
        key(Key3; "Document Type", "Document No.", "Loaner No.", Lent)
        {
        }
        key(Key4; "Loaner No.", "Date Lent", "Time Lent", "Date Received", "Time Received")
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
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure GetNextEntryNo(): Integer
    begin
        exit(GetLastEntryNo() + 1);
    end;
}

