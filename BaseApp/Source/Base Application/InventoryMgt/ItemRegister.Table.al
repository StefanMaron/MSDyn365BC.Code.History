table 46 "Item Register"
{
    Caption = 'Item Register';
    LookupPageID = "Item Registers";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "Item Ledger Entry";
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
            TableRelation = "Item Journal Batch".Name;
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
        field(10; "From Phys. Inventory Entry No."; Integer)
        {
            Caption = 'From Phys. Inventory Entry No.';
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(11; "To Phys. Inventory Entry No."; Integer)
        {
            Caption = 'To Phys. Inventory Entry No.';
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(5800; "From Value Entry No."; Integer)
        {
            Caption = 'From Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(5801; "To Value Entry No."; Integer)
        {
            Caption = 'To Value Entry No.';
            TableRelation = "Value Entry";
        }
        field(5831; "From Capacity Entry No."; Integer)
        {
            Caption = 'From Capacity Entry No.';
            TableRelation = "Capacity Ledger Entry";
        }
        field(5832; "To Capacity Entry No."; Integer)
        {
            Caption = 'To Capacity Entry No.';
            TableRelation = "Capacity Ledger Entry";
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
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", "Creation Date", "Source Code")
        {
        }
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;
}

