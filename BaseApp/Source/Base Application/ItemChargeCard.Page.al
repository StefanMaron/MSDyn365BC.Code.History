#if not CLEAN20
page 31074 "Item Charge Card"
{
    Caption = 'Item Charge Card';
    PageType = Card;
    SourceTable = "Item Charge";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by PageExtension 31103 and PageExtension 31104 in Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of the item charge.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a description of the item charge number that you are setting up.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the search description.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the general product posting group to which this item charge belongs.';
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies tax groups. A tax group represents a group of inventory items.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code associated with the Item.';
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
#endif
