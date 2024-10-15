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
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of the item charge.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a description of the item charge number that you are setting up.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the search description.';
                }
                field("Use Ledger Entry Dimensions"; "Use Ledger Entry Dimensions")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the option to use ledger entry dimensions from item.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Assigment on Receive/Shipment"; "Assigment on Receive/Shipment")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the assigment of charges by item receive/shipment.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Incl. in Intrastat Amount"; "Incl. in Intrastat Amount")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies to include Intrastat amounts for item charges.';
                }
                field("Incl. in Intrastat Stat. Value"; "Incl. in Intrastat Stat. Value")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies to include Intrastat amounts for value entries.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the general product posting group to which this item charge belongs.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies tax groups. A tax group represents a group of inventory items.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this group should not be used. (Obsolete::Removed in release 01.2021)';
                field("Sales Only"; "Sales Only")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the use the charge only on sales document.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Disable Sales Schipment Lines"; "Disable Sales Schipment Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge sales schipment line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Disable Return Schipment Lines"; "Disable Return Schipment Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge return schipment line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this group should not be used. (Obsolete::Removed in release 01.2021)';
                field("Purchase Only"; "Purchase Only")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the use the charge only on purchase document.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Disable Receipt Lines"; "Disable Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Disable Transfer Receipt Lines"; "Disable Transfer Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge transfer receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                }
                field("Disable Return Receipt Lines"; "Disable Return Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge return receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
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
                    ApplicationArea = ItemCharges;
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
                    ApplicationArea = Dimensions;
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

