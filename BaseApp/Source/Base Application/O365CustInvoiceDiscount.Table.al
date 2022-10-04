table 2113 "O365 Cust. Invoice Discount"
{
    Caption = 'O365 Cust. Invoice Discount';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Minimum Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
#if not CLEAN21
            trigger OnValidate()
            begin
                CheckMinimalAmount();
            end;
#endif
        }
        field(6; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Minimum Amount", "Discount %")
        {
        }
    }
#if not CLEAN21
    var
        DuplicateMinimumAmountErr: Label 'Customer Invoice Discount with Minimal Amount %1 already exists.', Comment = '%1 - some amount';

    local procedure CheckMinimalAmount()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Code);
        CustInvoiceDisc.SetRange("Minimum Amount", "Minimum Amount");
        if not CustInvoiceDisc.IsEmpty() then
            Error(DuplicateMinimumAmountErr, "Minimum Amount");
    end;
#endif
}

