page 3010532 "ESR Setup List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'ESR Setup List';
    CardPageID = "ESR Setup";
    Editable = false;
    PageType = List;
    SourceTable = "ESR Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1150000)
            {
                ShowCaption = false;
                field("Bank Code"; "Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ESR bank is identified by the bank code.';
                }
                field("ESR System"; "ESR System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice amount will be printed and no deduction can be made with the payment.';
                }
                field("ESR Payment Method Code"; "ESR Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that vendors are linked with the ESR bank using the payment method code.';
                }
                field("ESR Currency Code"; "ESR Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that ESR can be used for CHF and EUR.';
                }
            }
        }
    }

    actions
    {
    }
}

