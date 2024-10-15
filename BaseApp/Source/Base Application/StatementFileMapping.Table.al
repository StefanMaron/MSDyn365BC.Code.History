table 11766 "Statement File Mapping"
{
    Caption = 'Statement File Mapping';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(3; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(4; "Schedule Line No."; Integer)
        {
            Caption = 'Schedule Line No.';
            TableRelation = "Acc. Schedule Line"."Line No." WHERE("Schedule Name" = FIELD("Schedule Name"));
        }
        field(5; "Schedule Column Layout Name"; Code[10])
        {
            Caption = 'Schedule Column Layout Name';
            TableRelation = "Column Layout Name".Name;
        }
        field(6; "Schedule Column No."; Integer)
        {
            Caption = 'Schedule Column No.';
            TableRelation = "Column Layout"."Line No." WHERE("Column Layout Name" = FIELD("Schedule Column Layout Name"));
        }
        field(8; "Excel Cell"; Code[50])
        {
            Caption = 'Excel Cell';
            CharAllowed = '09,R,C';
        }
        field(10; "Excel Row No."; Integer)
        {
            Caption = 'Excel Row No.';
        }
        field(11; "Excel Column No."; Integer)
        {
            Caption = 'Excel Column No.';
        }
        field(20; Split; Option)
        {
            Caption = 'Split';
            OptionCaption = ' ,Right,Left';
            OptionMembers = " ",Right,Left;
        }
        field(21; Offset; Integer)
        {
            Caption = 'Offset';
        }
    }

    keys
    {
        key(Key1; "Schedule Name", "Schedule Line No.", "Schedule Column Layout Name", "Schedule Column No.", "Excel Cell")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
