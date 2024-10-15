page 12458 "Posted Item Receipt Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Item Receipt Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item description.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of item units.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Unit Amount"; "Unit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit price for the item.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction amount.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        ShowItemTrackingLines;
                    end;
                }
            }
        }
    }
}

