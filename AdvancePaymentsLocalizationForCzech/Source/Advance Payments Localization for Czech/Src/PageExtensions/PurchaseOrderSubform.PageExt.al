pageextension 31038 "Purchase Order Subform CZZ" extends "Purchase Order Subform"
{
    layout
    {
        modify("Prepayment %")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Prepmt. Line Amount")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Prepmt. Amt. Inv.")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Prepmt Amt to Deduct")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Prepmt Amt Deducted")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
    }

    var
        AdvancePaymentsMgtCZZ: Codeunit "Advance Payments Mgt. CZZ";
        AdvancePaymentsEnabledCZZ: Boolean;

    trigger OnOpenPage()
    begin
        AdvancePaymentsEnabledCZZ := AdvancePaymentsMgtCZZ.IsEnabled();
    end;
}
