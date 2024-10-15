pageextension 18719 "Purchase Order Statistics" extends "Purchase Order Statistics"
{
    layout
    {
        addlast(General)
        {
            field("Total Amount"; TotalTaxAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the amount, including TDS amount. On the General fast tab, this is the amount posted to the vendor account for all the lines in the purchase order if you post the purchase order as invoiced.';
                Caption = 'Net Total';
            }
            field("TDS Amount"; TDSAmount)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the amount of TDS that is included in the total amount.';
                Caption = 'TDS Amount';
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TDSSubscribers: Codeunit "TDS Subscribers";
    begin
        TDSSubscribers.GetStatiticsAmount(Rec, TotalTaxAmount, TDSAmount);
    end;

    var
        TotalTaxAmount: Decimal;
        TDSAmount: Decimal;
}