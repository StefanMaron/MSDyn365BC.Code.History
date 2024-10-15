page 5800 "Item Charges"
{
    AdditionalSearchTerms = 'fee transportation freight handling landed cost';
    ApplicationArea = ItemCharges;
    Caption = 'Item Charges';
    CardPageID = "Item Charge Card";
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
                field("Use Ledger Entry Dimensions"; "Use Ledger Entry Dimensions")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the option to use ledger entry dimensions from item.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Sales Only"; "Sales Only")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the item charges has to be only for sales document used.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Purchase Only"; "Purchase Only")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the item charges has to be only for purchase document used.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Disable Receipt Lines"; "Disable Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Disable Transfer Receipt Lines"; "Disable Transfer Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge transfer receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Disable Return Schipment Lines"; "Disable Return Schipment Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge return schipment line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Disable Sales Schipment Lines"; "Disable Sales Schipment Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge sales schipment line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Disable Return Receipt Lines"; "Disable Return Receipt Lines")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies if the charge return receipt line will be disable or not.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Assigment on Receive/Shipment"; "Assigment on Receive/Shipment")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the assigment of charges by item receive/shipment.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Item charges enhancements will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
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

