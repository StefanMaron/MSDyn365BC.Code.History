table 18201 "Dist. Component Amount"
{
    Caption = 'Dist. Component Amount';

    fields
    {
        field(1; "Distribution No."; Code[20])
        {
            Caption = 'Distribution No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(3; "GST Base Amount"; Decimal)
        {
            Caption = 'GST Base Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "GST Amount"; Decimal)
        {
            Caption = 'GST Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(5; "GST Registration No."; Code[20])
        {
            Caption = 'GST Registration No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "To Location Code"; Code[10])
        {
            Caption = 'To Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location where("GST Input Service Distributor" = filter(false));
        }
        field(7; "Distribution %"; Decimal)
        {
            Caption = 'Distribution %';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "GST Credit"; enum "GST Credit")
        {
            Caption = 'GST Credit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; Type; Enum Type)
        {
            Caption = 'Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
                where(
                    "Direct Posting" = const(false),
                    "Account Type" = const(Posting),
                    Blocked = const(false));
        }
        field(11; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Distribution No.", "GST Component Code", "To Location Code", "GST Credit", Type, "No.")
        {
            Clustered = true;
        }
    }
}

