table 31030 "Purchase Adv. Payment Template"
{
    Caption = 'Purchase Adv. Payment Template';
    LookupPageID = "Purchase Adv. Paym. Selection";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(10; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(11; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(21; "Advance Letter Nos."; Code[20])
        {
            Caption = 'Advance Letter Nos.';
            TableRelation = "No. Series";
        }
        field(32; "Advance Invoice Nos."; Code[20])
        {
            Caption = 'Advance Invoice Nos.';
            TableRelation = "No. Series";
        }
        field(33; "Advance Credit Memo Nos."; Code[20])
        {
            Caption = 'Advance Credit Memo Nos.';
            TableRelation = "No. Series";
        }
        field(40; "Check Posting Group on Link"; Boolean)
        {
            Caption = 'Check Posting Group on Link';
        }
        field(51; "Post Advance VAT Option"; Option)
        {
            Caption = 'Post Advance VAT Option';
            InitValue = Always;
            OptionCaption = ' ,Never,Optional,Always';
            OptionMembers = " ",Never,Optional,Always;
        }
        field(60; "Automatic Adv. Invoice Posting"; Boolean)
        {
            Caption = 'Automatic Adv. Invoice Posting';
        }
        field(70; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
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

