table 31301 "Intrastat Delivery Group CZ"
{
    Caption = 'Intrastat Delivery Group';
    DrillDownPageID = "Intrastat Delivery Groups CZ";
    LookupPageID = "Intrastat Delivery Groups CZ";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
