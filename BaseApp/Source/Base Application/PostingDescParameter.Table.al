table 11786 "Posting Desc. Parameter"
{
    Caption = 'Posting Desc. Parameter';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of posting description will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Posting Desc. Code"; Code[10])
        {
            Caption = 'Posting Desc. Code';
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            InitValue = 1;
            MaxValue = 9;
            MinValue = 1;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Caption,Value,Constant';
            OptionMembers = Caption,Value,Constant;
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(5; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
    }

    keys
    {
        key(Key1; "Posting Desc. Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Field Name");
    end;
}

