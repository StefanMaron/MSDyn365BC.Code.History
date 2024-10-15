table 26558 "Requisite Option Line"
{
    Caption = 'Requisite Option Line';
    ObsoleteReason = 'Obsolete functionality';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(2; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
        }
        field(3; "Requisite Name"; Text[30])
        {
            Caption = 'Requisite Name';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(31; "Excel Cell Name"; Code[10])
        {
            Caption = 'Excel Cell Name';
        }
        field(32; "Excel Cell Value"; Code[10])
        {
            Caption = 'Excel Cell Value';
        }
        field(33; "Requisite Option Value"; Text[30])
        {
            Caption = 'Requisite Option Value';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Requisites Group Name", "Requisite Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

