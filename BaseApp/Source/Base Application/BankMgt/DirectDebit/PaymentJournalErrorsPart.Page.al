namespace Microsoft.Bank.Payment;

page 1228 "Payment Journal Errors Part"
{
    Caption = 'Payment Journal Errors Part';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Payment Jnl. Export Error Text";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies the error that is shown in the Payment Journal window in case payment lines cannot be exported.';

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"Payment File Error Details", Rec);
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

