table 18002 "GST Claim Setoff"
{
    Caption = 'GST Claim Setoff';
    DataCaptionFields = "GST Component Code", "Set Off Component Code";
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "GST Component Code"; Code[10])
        {
            Caption = 'GST Component Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;

        }
        field(2; "Set Off Component Code"; code[10])
        {
            Caption = 'Set Off Component Code';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }

        field(3; "Priority"; Integer)
        {
            Caption = 'Priority';
            NotBlank = true;
            MinValue = 1;
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; "GST Component Code", "Set Off Component Code")
        {
            Clustered = true;
        }
        key(Fk; Priority)
        {
        }
    }
}