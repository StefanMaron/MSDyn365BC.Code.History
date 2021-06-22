table 8510 "Over-Receipt Code"
{
    DataClassification = CustomerContent;
    LookupPageId = "Over-Receipt Codes";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            var
                OverReceiptCode: Record "Over-Receipt Code";
            begin
                if Default then begin
                    OverReceiptCode.SetRange(Default, true);
                    OverReceiptCode.ModifyAll(Default, false, false);
                end;
            end;
        }
        field(4; "Over-Receipt Tolerance %"; Decimal)
        {
            Caption = 'Over-Receipt Tolerance %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }
        field(5; "Required Approval"; Boolean)
        {
            Caption = 'Approval Required';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}