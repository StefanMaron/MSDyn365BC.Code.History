xmlport 31072 "Sales Price Import"
{
    Caption = 'Sales Price Import';
    DefaultFieldsValidation = true;
    Direction = Import;

    schema
    {
        textelement(SalesPriceTable)
        {
            textelement(Lines)
            {
                tableelement("Sales Price"; "Sales Price")
                {
                    XmlName = 'Line';
                    UseTemporary = true;
                    fieldelement(ItemNo; "Sales Price"."Item No.")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(SalesType; "Sales Price"."Sales Type")
                    {
                    }
                    fieldelement(SalesCode; "Sales Price"."Sales Code")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(CurrencyCode; "Sales Price"."Currency Code")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(StartingDate; "Sales Price"."Starting Date")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(UnitPrice; "Sales Price"."Unit Price")
                    {
                    }
                    fieldelement(PriceIncludesVAT; "Sales Price"."Price Includes VAT")
                    {
                    }
                    fieldelement(AllowInvoiceDisc; "Sales Price"."Allow Invoice Disc.")
                    {
                    }
                    fieldelement(VATBusPostingGrPrice; "Sales Price"."VAT Bus. Posting Gr. (Price)")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(MinimumQuantity; "Sales Price"."Minimum Quantity")
                    {
                    }
                    fieldelement(EndingDate; "Sales Price"."Ending Date")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(UnitofMeasureCode; "Sales Price"."Unit of Measure Code")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(VariantCode; "Sales Price"."Variant Code")
                    {
                        FieldValidate = yes;
                    }
                    fieldelement(AllowLineDisc; "Sales Price"."Allow Line Disc.")
                    {
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    begin
        // copy data from Temporary table "Sales Price" to table Sales Price (7002)
        if "Sales Price".Find('-') then
            repeat
                if greSalesPrice.Get("Sales Price"."Item No.", "Sales Price"."Sales Type",
                     "Sales Price"."Sales Code", "Sales Price"."Starting Date",
                     "Sales Price"."Currency Code", "Sales Price"."Variant Code",
                     "Sales Price"."Unit of Measure Code", "Sales Price"."Minimum Quantity")
                then begin
                    greSalesPrice."Unit Price" := "Sales Price"."Unit Price";
                    greSalesPrice."Price Includes VAT" := "Sales Price"."Price Includes VAT";
                    greSalesPrice."Allow Invoice Disc." := "Sales Price"."Allow Invoice Disc.";
                    greSalesPrice."VAT Bus. Posting Gr. (Price)" := "Sales Price"."VAT Bus. Posting Gr. (Price)";
                    greSalesPrice."Ending Date" := "Sales Price"."Ending Date";
                    greSalesPrice."Allow Line Disc." := "Sales Price"."Allow Line Disc.";
                    greSalesPrice.Modify();
                end else begin
                    greSalesPrice."Item No." := "Sales Price"."Item No.";
                    greSalesPrice."Sales Type" := "Sales Price"."Sales Type";
                    greSalesPrice."Sales Code" := "Sales Price"."Sales Code";
                    greSalesPrice."Starting Date" := "Sales Price"."Starting Date";
                    greSalesPrice."Currency Code" := "Sales Price"."Currency Code";
                    greSalesPrice."Variant Code" := "Sales Price"."Variant Code";
                    greSalesPrice."Unit of Measure Code" := "Sales Price"."Unit of Measure Code";
                    greSalesPrice."Minimum Quantity" := "Sales Price"."Minimum Quantity";
                    greSalesPrice."Unit Price" := "Sales Price"."Unit Price";
                    greSalesPrice."Price Includes VAT" := "Sales Price"."Price Includes VAT";
                    greSalesPrice."Allow Invoice Disc." := "Sales Price"."Allow Invoice Disc.";
                    greSalesPrice."VAT Bus. Posting Gr. (Price)" := "Sales Price"."VAT Bus. Posting Gr. (Price)";
                    greSalesPrice."Ending Date" := "Sales Price"."Ending Date";
                    greSalesPrice."Allow Line Disc." := "Sales Price"."Allow Line Disc.";
                    greSalesPrice.Insert();
                end;
            until "Sales Price".Next = 0;
    end;

    var
        greSalesPrice: Record "Sales Price";
}

