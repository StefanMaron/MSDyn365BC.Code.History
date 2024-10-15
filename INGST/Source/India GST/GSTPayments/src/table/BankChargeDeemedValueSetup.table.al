table 18244 "Bank Charge Deemed Value Setup"
{
    Caption = 'Bank Charge Deemed Value Setup';
    DataCaptionFields = "Bank Charge Code";

    fields
    {
        field(1; "Bank Charge Code"; code[10])
        {
            Caption = 'Bank Charge Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Bank Charge" WHERE("Foreign Exchange" = FILTER(true));
            NotBlank = true;
        }
        field(2; "Lower Limit"; Decimal)
        {
            Caption = 'Lower Limit';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Upper Limit"; Decimal)
        {
            Caption = 'Upper Limit';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(4; "Formula"; enum "Deemed Value Calculation")
        {
            Caption = 'Formula';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Min. Deemed Value"; Decimal)
        {
            Caption = 'Min. Deemed Value';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(6; "Max. Deemed Value"; Decimal)
        {
            Caption = 'Max. Deemed Value';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
        field(7; "Deemed %"; Decimal)
        {
            Caption = 'Deemed %';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
            MaxValue = 100;
        }
        field(8; "Fixed Amount"; Decimal)
        {
            Caption = 'Fixed Amount';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Bank Charge Code", "Lower Limit", "Upper Limit")
        {
            Clustered = true;
        }
    }
}
