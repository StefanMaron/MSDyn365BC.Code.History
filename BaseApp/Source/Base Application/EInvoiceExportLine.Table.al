table 10605 "E-Invoice Export Line"
{
    Caption = 'E-Invoice Export Line';

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Item,Resource,Fixed Asset,Charge (Item)';
            OptionMembers = " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(22; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            Caption = 'Line Discount Amount';
        }
        field(29; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            Caption = 'Inv. Discount Amount';
        }
        field(77; "VAT Calculation Type"; Option)
        {
            Caption = 'VAT Calculation Type';
            OptionCaption = 'Normal VAT,Reverse Charge VAT,Full VAT,Sales Tax';
            OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(10605; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
        }
        field(10680; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

