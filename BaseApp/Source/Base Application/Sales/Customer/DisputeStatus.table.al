namespace Microsoft.Sales.Customer;

table 142 "Dispute Status"
{
    Caption = 'Dispute Status';
    DataCaptionFields = "Code", "Description";
    LookupPageID = "Dispute Status";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(10; "Overwrite on hold"; Boolean)
        {
            Caption = 'Overwrite on hold';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}