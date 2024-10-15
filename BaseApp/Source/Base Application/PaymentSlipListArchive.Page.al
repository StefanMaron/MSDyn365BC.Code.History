page 10879 "Payment Slip List Archive"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Slip Archive';
    CardPageID = "Payment Slip Archive";
    Editable = false;
    PageType = List;
    SourceTable = "Payment Header Archive";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the payment slip.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the payment.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment slip was posted.';
                }
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment class used when creating this payment slip.';
                }
                field("Status Name"; "Status Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment.';
                }
            }
        }
    }

    actions
    {
    }
}

