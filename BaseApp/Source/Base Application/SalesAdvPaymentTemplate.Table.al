table 31010 "Sales Adv. Payment Template"
{
    Caption = 'Sales Adv. Payment Template';
#if not CLEAN19
    LookupPageID = "Sales Advanced Paym. Selection";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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
        field(10; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
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
        field(60; "Amounts Including VAT"; Boolean)
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

