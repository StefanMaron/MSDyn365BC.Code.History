table 332 "Currency Total Buffer"
{
    Caption = 'Currency Total Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(2; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "Total Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(4; Counter; Integer)
        {
            Caption = 'Counter';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure UpdateTotal(CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; var Counter: Integer)
    begin
        if Get(CurrencyCode) then begin
            "Total Amount" := "Total Amount" + Amount;
            "Total Amount (LCY)" := "Total Amount (LCY)" + AmountLCY;
            Modify;
        end else begin
            "Currency Code" := CurrencyCode;
            "Total Amount" := Amount;
            "Total Amount (LCY)" := AmountLCY;
            Counter := Counter + 1;
            Insert;
        end;
    end;
}

