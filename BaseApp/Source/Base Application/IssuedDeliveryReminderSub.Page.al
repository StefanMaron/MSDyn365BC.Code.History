page 5005274 "Issued Delivery Reminder Sub"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Issued Deliv. Reminder Line";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                }
                field("Reorder Quantity"; "Reorder Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Del. Rem. Date Field"; "Del. Rem. Date Field")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Requested Receipt Date"; "Requested Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that you want the vendor to deliver your order. The field is used to calculate the latest date you can order, as follows: requested receipt date - lead time calculation = order date. If you do not need delivery on a specific date, you can leave the field blank.';
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Days overdue"; "Days overdue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
            }
        }
    }

    actions
    {
    }
}

