page 5718 "Item Substitution Entries"
{
    Caption = 'Item Substitution Entries';
    DataCaptionFields = "No.", Description;
    DelayedInsert = true;
    Editable = false;
    PageType = Worksheet;
    SourceTable = "Item Substitution";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Substitute No."; "Substitute No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item that can be used as a substitute in case the original item is unavailable.';
                }
                field("Substitute Variant Code"; "Substitute Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the variant that can be used as a substitute.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the description of the substitute item.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Suite;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units (such as pieces, boxes, or cans) of the item are available.';
                }
                field("Quantity Avail. on Shpt. Date"; "Quantity Avail. on Shpt. Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the substitute item quantity available on the shipment date.';
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a condition exists for this substitution.';
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
            action("&Condition")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Condition';
                Image = ViewComments;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Sub. Conditions";
                RunPageLink = Type = FIELD(Type),
                              "No." = FIELD("No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Substitute Type" = FIELD("Substitute Type"),
                              "Substitute No." = FIELD("Substitute No."),
                              "Substitute Variant Code" = FIELD("Substitute Variant Code");
                ToolTip = 'Specify a condition for the item substitution, which is for information only and does not affect the item substitution.';
            }
        }
    }
}

