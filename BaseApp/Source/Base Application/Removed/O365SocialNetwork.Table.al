table 2122 "O365 Social Network"
{
    Caption = 'O365 Social Network';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; URL; Text[250])
        {
            Caption = 'URL';
        }
        field(5; "Media Resources Ref"; Code[50])
        {
            Caption = 'Media Resources Ref';
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
