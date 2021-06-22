table 6 "Customer Price Group"
{
    Caption = 'Customer Price Group';
    LookupPageID = "Customer Price Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            var
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if "Price Includes VAT" then begin
                    SalesSetup.Get();
                    if SalesSetup."VAT Bus. Posting Gr. (Price)" <> '' then
                        Validate("VAT Bus. Posting Gr. (Price)", SalesSetup."VAT Bus. Posting Gr. (Price)");
                end;
            end;
        }
        field(5; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(6; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
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
        fieldgroup(DropDown; "Code", Description, "Allow Invoice Disc.", "Allow Line Disc.")
        {
        }
    }

    trigger OnDelete()
    begin
        UpdateSalesPrices(false);
    end;

    trigger OnRename()
    begin
        UpdateSalesPrices(true);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    local procedure UpdateSalesPrices(CreateNewSalesPrice: Boolean)
    var
        SalesPrice: Record "Sales Price";
        NewSalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", xRec.Code);
        if CreateNewSalesPrice then
            if SalesPrice.FindSet then
                repeat
                    NewSalesPrice := SalesPrice;
                    NewSalesPrice."Sales Code" := Code;
                    NewSalesPrice.Insert(true);
                until SalesPrice.Next = 0;
        SalesPrice.DeleteAll(true);
    end;
}

