table 18011 "Reference Invoice No."
{
    Caption = 'Reference Invoice No.';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Document Type"; Enum "Document Type Enum")
        {
            Caption = 'Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Reference Invoice Nos."; Code[20])
        {
            Caption = 'Reference Invoice Nos.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Source Type"; Enum "Party Type")
        {
            Caption = 'Source Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; Verified; Boolean)
        {
            Caption = 'Verified';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Type", "Source No.", "Reference Invoice Nos.", "Journal Template Name", "Journal Batch Name")
        {
            Clustered = true;
        }
    }
}