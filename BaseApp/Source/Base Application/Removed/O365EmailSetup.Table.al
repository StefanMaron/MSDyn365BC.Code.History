table 2118 "O365 Email Setup"
{
    Caption = 'O365 Email Setup';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[80])
        {
            Caption = 'Code';
        }
        field(2; Email; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        field(3; RecipientType; Option)
        {
            Caption = 'RecipientType';
            OptionCaption = 'CC,BCC';
            OptionMembers = CC,BCC;
        }
    }

    keys
    {
        key(Key1; "Code", RecipientType)
        {
            Clustered = true;
        }
        key(Key2; Email, RecipientType)
        {
        }
        key(Key3; Email)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; RecipientType, Email)
        {
        }
    }
}


