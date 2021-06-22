page 7021 "Suggest Price Lines"
{
    Caption = 'Price Lines';
    PageType = StandardDialog;
    SourceTable = "Price Line Filters";
    DataCaptionExpression = DataCaption;

    layout
    {
        area(content)
        {
            group(All)
            {
                field("From Price List Code"; Rec."From Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CopyLines;
                    Caption = 'From Price List';
                    ToolTip = 'Specifies the price list code to copy lines from.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PriceListHeader: Record "Price List Header";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceListHeader.Get(Rec."To Price List Code");
                        Rec."From Price List Code" := Rec."To Price List Code";
                        if PriceUXManagement.LookupPriceLists(
                            PriceListHeader."Source Group", PriceListHeader."Price Type", Rec."From Price List Code")
                        then begin
                            PriceListHeader.Get(Rec."From Price List Code");
                            Rec.Validate("From Price List Code");
                            CurrPage.Update(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Price Line Filter"; Rec."Price Line Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CopyLines;
                    Caption = 'Price Line Filter';
                    ToolTip = 'Specifies the filters applied to the product table.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.EditPriceLineFilter();
                    end;
                }
                field("Product Type"; Rec."Asset Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = not CopyLines;
                    Caption = 'Product Type';
                    ToolTip = 'Specifies the product type that defines the table being a source for the suggested price list lines.';
                }
                field("Product Filter"; Rec."Asset Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = not CopyLines;
                    Caption = 'Product Filter';
                    ToolTip = 'Specifies the filters applied to the product table.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.EditAssetFilter();
                    end;
                }
                group(Options)
                {
                    Caption = 'Options';
                    field("Minimum Quantity"; Rec."Minimum Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = not CopyLines;
                        Caption = 'Minimum Quantity';
                        ToolTip = 'Specifies the default minimum quantity for the suggested lines. If you do not specify minimum qunatity, pricing will apply same price irrespective of quantity.';
                    }
                    group(Adjustment)
                    {
                        ShowCaption = false;
                        Visible = "Different Currencies";
                        field("Exchange Rate Date"; Rec."Exchange Rate Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Exchange Rate Date';
                            ToolTip = 'Specifies a date for the currency exchange rate calculations.';
                        }
                    }
                    field("Adjustment Factor"; Rec."Adjustment Factor")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjustment Factor';
                        ToolTip = 'Specifies an adjustment factor to multiply the amounts that you want to copy. By entering an adjustment factor, you can increase or decrease the amounts.';
                    }
                    field("Rounding Method Code"; Rec."Rounding Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding Method';
                        ToolTip = 'Specifies a rounding method code that you want applied to prices.';
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Insert();
        CopyLines := Rec."Copy Lines";
        if CopyLines then
            DataCaption := DataCaptionCopyLbl
        else
            DataCaption := DataCaptionSuggestLbl;
    end;

    var
        DataCaption: Text;
        DataCaptionCopyLbl: Label 'Copy existing';
        DataCaptionSuggestLbl: Label 'Create new';
        CopyLines: Boolean;
}