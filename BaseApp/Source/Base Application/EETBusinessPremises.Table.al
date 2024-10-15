table 31121 "EET Business Premises"
{
    Caption = 'EET Business Premises';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(15; Identification; Code[6])
        {
            Caption = 'Identification';
            Numeric = true;
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
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
