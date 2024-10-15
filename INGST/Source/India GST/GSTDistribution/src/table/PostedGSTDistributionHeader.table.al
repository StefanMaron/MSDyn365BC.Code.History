table 18207 "Posted GST Distribution Header"
{
    Caption = 'Posted GST Distribution Header';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = false;
        }
        field(2; "From GSTIN No."; Code[20])
        {
            Caption = 'From GSTIN No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "GST Registration Nos."
                where("Input Service Distributor" = filter(true));
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; "Dist. Document Type"; Enum "BankCharges DocumentType")
        {
            Caption = 'Dist. Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; Reversal; Boolean)
        {
            Caption = 'Reversal';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Reversal Invoice No."; Code[20])
        {
            Caption = 'Reversal Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "ISD Document Type"; Enum "Adjustment Document Type")
        {
            Caption = 'ISD Document Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "From Location Code"; Code[10])
        {
            Caption = 'From Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location where("GST Input Service Distributor" = filter(true));
        }
        field(16; "Dist. Credit Type"; Enum "GST Distribution Credit Type")
        {
            Caption = 'Dist. Credit Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Total Amout Applied for Dist."; Decimal)
        {
            Caption = 'Total Amout Applied for Dist.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Distribution Basis"; Text[50])
        {
            Caption = 'Distribution Basis';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "Pre Distribution No."; Code[20])
        {
            Caption = 'Pre Distribution No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Completely Reversed"; Boolean)
        {
            Caption = 'Completely Reversed';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }
}

