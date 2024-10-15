page 12184 Bill
{
    Caption = 'Bill';
    PageType = List;
    SourceTable = Bill;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a bill code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the bill.';
                }
                field("Allow Issue"; "Allow Issue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if documents related to the bill code are automatically issued.';
                }
                field("Bank Receipt"; "Bank Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the bill code automatically creates bank receipts that you can use to manage customer bills.';
                }
                field("Bills for Coll. Temp. Acc. No."; "Bills for Coll. Temp. Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary general ledger account number where the bills for collection will be posted.';
                }
                field("Temporary Bill No."; "Temporary Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary identification number for the customer bill.';
                }
                field("Final Bill No."; "Final Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a final identification number for the customer bill.';
                }
                field("List No."; "List No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill list identification number.';
                }
                field("Bill Source Code"; "Bill Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code linked to identify bank transfer entries for customers.';
                }
                field("Vendor Bill List"; "Vendor Bill List")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bill lists.';
                }
                field("Vendor Bill No."; "Vendor Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bill that will be send out.';
                }
                field("Vend. Bill Source Code"; "Vend. Bill Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code linked to identify bank transfers entries for vendors.';
                }
            }
        }
    }

    actions
    {
    }
}

