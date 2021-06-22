page 5800 "Item Charges"
{
    AdditionalSearchTerms = 'fee transportation freight handling landed cost';
    ApplicationArea = ItemCharges;
    Caption = 'Item Charges';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Item Charge';
    SourceTable = "Item Charge";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a description of the item charge number that you are setting up.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the item charge''s product type to link transactions made for this item charge with the appropriate general ledger account according to the general posting setup.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the sales tax group code that this item charge belongs to.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies text to search for when you do not know the number of the item charge.';
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
        area(navigation)
        {
            group("&Item Charge")
            {
                Caption = '&Item Charge';
                Image = Add;
                action("Value E&ntries")
                {
                    ApplicationArea = ItemCharges;
                    Caption = 'Value E&ntries';
                    Image = ValueLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Entry Type" = CONST("Direct Cost"),
                                  "Item Charge No." = FIELD("No.");
                    RunPageView = SORTING("Item Charge No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the amounts related to item or capacity ledger entries for the record on the document or journal line.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5800),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }
}

