page 7023 "Sales Price Worksheet"
{
    AdditionalSearchTerms = 'special price,alternate price';
    ApplicationArea = Suite;
    Caption = 'Sales Price Worksheet';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Sales Price Worksheet";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the item can be sold at the sales price.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the sales price agreement ends.';
                }
                field("Sales Type"; "Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of sale that the price is based on, such as All Customers or Campaign.';
                }
                field("Sales Code"; "Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Sales Type code.';
                }
                field("Sales Description"; "Sales Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the sales type, such as Campaign, on the worksheet line.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the sales price.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which sales prices are being changed or set up.';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the item on the worksheet line.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; "Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum sales quantity that must be met to warrant the sales price.';
                }
                field("Current Unit Price"; "Current Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit price of the item.';
                }
                field("New Unit Price"; "New Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new unit price that is valid for the selected combination of Sales Code, Currency Code and/or Starting Date.';
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
                field("Price Includes VAT"; "Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the sales price includes VAT.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; "VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the VAT business posting group of customers for whom the sales prices will apply.';
                    Visible = false;
                }
                field("Allow Line Disc."; "Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a line discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest &Item Price on Wksh.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest &Item Price on Wksh.';
                    Ellipsis = true;
                    Image = SuggestItemPrice;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create suggestions for changing the agreed item unit prices for your sales prices in the Sales Prices window on the basis of the unit price on the item cards. When the batch job has completed, you can see the result in the Sales Price Worksheet window. You can also use the Suggest Sales Price on Wksh. batch job to create suggestions for new sales prices.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Item Price on Wksh.", true, true);
                    end;
                }
                action("Suggest &Sales Price on Wksh.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest &Sales Price on Wksh.';
                    Ellipsis = true;
                    Image = SuggestSalesPrice;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create suggestions for changing the agreed item unit prices for your sales prices in the Sales Prices window on the basis of the unit price on the item cards. When the batch job has completed, you can see the result in the Sales Price Worksheet window. You can also use the Suggest Sales Price on Wksh. batch job to create suggestions for new sales prices.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Suggest Sales Price on Wksh.", true, true);
                    end;
                }
                action("I&mplement Price Change")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I&mplement Price Change';
                    Ellipsis = true;
                    Image = ImplementPriceChange;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'Update the alternate prices in the Sales Prices window with the ones in the Sales Price Worksheet window.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Implement Price Change", true, true, Rec);
                    end;
                }
            }
        }
    }
}

