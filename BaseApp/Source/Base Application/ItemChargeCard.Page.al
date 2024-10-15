page 31074 "Item Charge Card"
{
    Caption = 'Item Charge Card';
    PageType = Card;
    SourceTable = "Item Charge";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ToolTip = 'Specifies the number of the item charge.';
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies a description of the item charge number that you are setting up.';
                }
                field("Search Description"; "Search Description")
                {
                    ToolTip = 'Specifies the search description.';
                }
                field("Use Ledger Entry Dimensions"; "Use Ledger Entry Dimensions")
                {
                    ToolTip = 'Specifies the option to use ledger entry dimensions from item.';
                }
                field("Assigment on Receive/Shipment"; "Assigment on Receive/Shipment")
                {
                    ToolTip = 'Specifies the assigment of charges by item receive/shipment.';
                }
                field("Incl. in Intrastat Amount"; "Incl. in Intrastat Amount")
                {
                    ToolTip = 'Specifies to include Intrastat amounts for item charges.';
                }
                field("Incl. in Intrastat Stat. Value"; "Incl. in Intrastat Stat. Value")
                {
                    ToolTip = 'Specifies to include Intrastat amounts for value entries.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the general product posting group to which this item charge belongs.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ToolTip = 'Specifies tax groups. A tax group represents a group of inventory items.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                field("Sales Only"; "Sales Only")
                {
                    ToolTip = 'Specifies the use the charge only on sales document.';
                }
                field("Disable Sales Schipment Lines"; "Disable Sales Schipment Lines")
                {
                    ToolTip = 'Specifies if the charge sales schipment line will be disable or not.';
                }
                field("Disable Return Schipment Lines"; "Disable Return Schipment Lines")
                {
                    ToolTip = 'Specifies if the charge return schipment line will be disable or not.';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                field("Purchase Only"; "Purchase Only")
                {
                    ToolTip = 'Specifies the use the charge only on purchase document.';
                }
                field("Disable Receipt Lines"; "Disable Receipt Lines")
                {
                    ToolTip = 'Specifies if the charge receipt line will be disable or not.';
                }
                field("Disable Transfer Receipt Lines"; "Disable Transfer Receipt Lines")
                {
                    ToolTip = 'Specifies if the charge transfer receipt line will be disable or not.';
                }
                field("Disable Return Receipt Lines"; "Disable Return Receipt Lines")
                {
                    ToolTip = 'Specifies if the charge return receipt line will be disable or not.';
                }
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
                action("Value E&ntries")
                {
                    Caption = 'Value E&ntries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Entry Type" = CONST("Direct Cost"),
                                  "Item Charge No." = FIELD("No.");
                    RunPageView = SORTING("Item Charge No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Specifies value entries';
                }
                action(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5800),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit the dimension sets that are set up for the item charge card.';
                }
            }
        }
    }
}

