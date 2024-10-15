table 10704 "Sales/Purch. Book VAT Buffer"
{
    Caption = 'Sales/Purch. Book VAT Buffer';
    LookupPageID = "VAT Entries";

    fields
    {
        field(1; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
        }
        field(2; "EC %"; Decimal)
        {
            Caption = 'EC %';
            DataClassification = SystemMetadata;
        }
        field(3; Base; Decimal)
        {
            Caption = 'Base';
            DataClassification = SystemMetadata;
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(5; "EC Amount"; Decimal)
        {
            Caption = 'EC Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT %", "EC %")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        VATPostingSetup.Get("EC %", Base);
        "VAT %" := VATPostingSetup."VAT %";
        "EC %" := VATPostingSetup."EC %";
    end;

    var
        VATPostingSetup: Record "VAT Posting Setup";
}

