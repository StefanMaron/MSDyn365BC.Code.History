table 14917 "CD No. Format"
{
    Caption = 'CD No. Format';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to CD Tracking extension table CD Number Header.';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; Format; Code[50])
        {
            Caption = 'Format';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}

