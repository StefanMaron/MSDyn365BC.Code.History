namespace Microsoft.Service.Pricing;

table 6082 "Service Price Adjustment Group"
{
    Caption = 'Service Price Adjustment Group';
    LookupPageID = "Serv. Price Adjmt. Group";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
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

    trigger OnDelete()
    var
        ServPriceAdjmtDetail: Record "Serv. Price Adjustment Detail";
    begin
        ServPriceAdjmtDetail.SetRange("Serv. Price Adjmt. Gr. Code", Code);
        if ServPriceAdjmtDetail.FindFirst() then
            ServPriceAdjmtDetail.DeleteAll();
    end;
}

