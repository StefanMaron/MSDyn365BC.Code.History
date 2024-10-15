#if not CLEAN19
xmlport 31071 "Sales Price Export"
{
    Caption = 'Sales Price Export';
    Direction = Export;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';

    schema
    {
        textelement(SalesPriceTable)
        {
            textelement(Lines)
            {
                tableelement("Sales Price"; "Sales Price")
                {
                    XmlName = 'Line';
                    fieldelement(ItemNo; "Sales Price"."Item No.")
                    {
                    }
                    fieldelement(SalesType; "Sales Price"."Sales Type")
                    {
                    }
                    fieldelement(SalesCode; "Sales Price"."Sales Code")
                    {
                    }
                    fieldelement(CurrencyCode; "Sales Price"."Currency Code")
                    {
                    }
                    fieldelement(StartingDate; "Sales Price"."Starting Date")
                    {
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
                    }
                    fieldelement(MinimumQuantity; "Sales Price"."Minimum Quantity")
                    {
                    }
                    fieldelement(EndingDate; "Sales Price"."Ending Date")
                    {
                    }
                    fieldelement(UnitofMeasureCode; "Sales Price"."Unit of Measure Code")
                    {
                    }
                    fieldelement(VariantCode; "Sales Price"."Variant Code")
                    {
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
}
#endif
