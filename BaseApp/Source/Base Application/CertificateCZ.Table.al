table 31131 "Certificate CZ"
{
    Caption = 'Certificate';
    DataCaptionFields = "Certificate Code", Description;
    Permissions = TableData "Service Password" = rimd;
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by tab 1262 "Isolated Certificate"';

    fields
    {
        field(1; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            NotBlank = true;
        }
        field(2; "Valid From"; DateTime)
        {
            Caption = 'Valid From';
        }
        field(3; "Valid To"; DateTime)
        {
            Caption = 'Valid To';
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Store Type"; Option)
        {
            Caption = 'Store Type';
            OptionCaption = 'Server,Client,Database';
            OptionMembers = Server,Client,Database;
        }
        field(11; "Store Location"; Option)
        {
            Caption = 'Store Location';
            OptionCaption = ' ,Current User,Local Machine';
            OptionMembers = " ","Current User","Local Machine";
        }
        field(12; "Store Name"; Option)
        {
            Caption = 'Store Name';
            OptionCaption = ' ,Address Book,Authority Root,Certificate Authority,Disallowed,My,Root,Trusted People,Trusted Publisher';
            OptionMembers = " ","Address Book","Authority Root","Certificate Authority",Disallowed,My,Root,"Trusted People","Trusted Publisher";
        }
        field(13; Thumbprint; Text[80])
        {
            Caption = 'Thumbprint';
        }
        field(15; "Certificate Key"; Guid)
        {
            Caption = 'Certificate Key';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Certificate Code", "User ID", "Valid From")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

