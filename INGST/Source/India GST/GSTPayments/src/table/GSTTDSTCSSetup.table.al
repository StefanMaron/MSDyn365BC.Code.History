table 18246 "GST TDS/TCS Setup"
{
    Caption = 'GST TDS/TCS Setup';
    DataCaptionFields = "GST Component Code";

    fields
    {
        field(1; "GST Component Code"; code[10])
        {
            Caption = 'GST Component Code';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(2; "Effective Date"; date)
        {
            Caption = 'Effective Date';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(3; "GST TDS/TCS %"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST TDS/TCS %';
            MinValue = 0;
            MaxValue = 100;
        }
        field(4; "GST Jurisdiction"; Enum "GST Jurisdiction Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'GST Jurisdiction';
        }
        field(5; "Type"; Enum "TDSTCS Type")
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Type';
        }
    }
    keys
    {
        key(PK; "GST Component Code", "Effective Date", "Type")
        {
        }
    }
}
