table 2132 "O365 Settings Menu"
{
    Caption = 'O365 Settings Menu';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Key';
        }
        field(2; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(3; Title; Text[30])
        {
            Caption = 'Title';
        }
        field(4; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; Link; Text[250])
        {
            Caption = 'Link';
            ExtendedDatatype = URL;
        }
        field(6; "On Open Action"; Option)
        {
            Caption = 'On Open Action';
            OptionCaption = 'Hyperlink,Page';
            OptionMembers = Hyperlink,"Page";
        }
        field(10; Parameter; Text[250])
        {
            Caption = 'Parameter';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

