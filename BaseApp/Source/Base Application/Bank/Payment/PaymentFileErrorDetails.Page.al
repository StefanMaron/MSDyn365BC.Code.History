namespace Microsoft.Bank.Payment;

page 1229 "Payment File Error Details"
{
    Caption = 'Payment File Error Details';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Payment Jnl. Export Error Text";

    layout
    {
        area(content)
        {
            field("Error Text"; Rec."Error Text")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the error that is shown in the Payment Journal window in case payment lines cannot be exported.';
            }
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies more information that may help you resolve the error.';
            }
            field("Support URL"; Rec."Support URL")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = URL;
                ToolTip = 'Specifies a web page containing information that may help you resolve the error.';
            }
        }
    }

    actions
    {
    }
}

