pageextension 18716 "Posted Purch. Inv Statistics" extends "Purchase Invoice Statistics"
{
    layout
    {
        addlast(General)
        {
            field("Total Amount"; TotalTaxAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Caption = 'Net Total';
                ToolTip = 'Specifies the amount, including TDS amount. On the General fast tab, this is the amount posted to the vendors account for all the lines in the purchase order if you post the purchase order as invoiced.';
            }
            field("TDS Amount"; TDSAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Caption = 'TDS Amount';
                ToolTip = 'Specifies the amount of TDS that is included in the total amount.';
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TDSSubscribers: Codeunit "TDS Subscribers";
    begin
        TDSSubscribers.GetStatiticsPostedAmount(Rec, TotalTaxAmount, TDSAmount);
    end;

    var
        TotalTaxAmount: Decimal;
        TDSAmount: Decimal;
}