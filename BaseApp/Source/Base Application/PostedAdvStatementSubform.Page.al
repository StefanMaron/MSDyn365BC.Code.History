page 12434 "Posted Adv. Statement Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purch. Inv. Line";

    layout
    {
        area(content)
        {
            repeater(Control1210008)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Empl. Purchase Vendor No."; "Empl. Purchase Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee purchase vendor number associated with this line.';
                }
                field("Empl. Purchase Entry No."; "Empl. Purchase Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee purchase entry number associated with this line.';
                }
                field("Empl. Purchase Document No."; "Empl. Purchase Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee purchase document number associated with this line.';
                }
                field("Empl. Purchase Document Date"; "Empl. Purchase Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee purchase document date associated with this line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price (LCY)"; "Unit Price (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ToolTip = 'Specifies if the line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Job No."; "Job No.")
                {
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Insurance No."; "Insurance No.")
                {
                    Visible = false;
                }
                field("Budgeted FA No."; "Budgeted FA No.")
                {
                    ToolTip = 'Specifies the budgeted fixed asset number that is associated with the archived general journal line.';
                    Visible = false;
                }
                field("FA Posting Type"; "FA Posting Type")
                {
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
                    Visible = false;
                }
                field("Depr. until FA Posting Date"; "Depr. until FA Posting Date")
                {
                    ToolTip = 'Specifies if depreciation was calculated until the FA posting date of the line.';
                    Visible = false;
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                    Visible = false;
                }
                field("Depr. Acquisition Cost"; "Depr. Acquisition Cost")
                {
                    ToolTip = 'Specifies if, when this line was posted, the additional acquisition cost posted on the line was depreciated in proportion to the amount by which the fixed asset had already been depreciated.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
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
                action("Item &Tracking Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
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

