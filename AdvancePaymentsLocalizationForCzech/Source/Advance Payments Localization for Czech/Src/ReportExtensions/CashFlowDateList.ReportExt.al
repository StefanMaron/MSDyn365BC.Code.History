reportextension 31006 "Cash Flow Date List CZZ" extends "Cash Flow Date List CZL"
{
    dataset
    {
        modify(EditionPeriod)
        {
            trigger OnAfterAfterGetRecord()
#if not CLEAN19
            var
                AdvancePaymentMgt: Codeunit "Advance Payments Mgt. CZZ";
#endif
            begin
#if not CLEAN19
                if AdvancePaymentMgt.IsEnabled() then begin
#endif
                    SalesAdvanceValue := CashFlow.CalcSourceTypeAmount(Enum::"Cash Flow Source Type"::"Sales Advance Letters CZZ");
                    PurchaseAdvanceValue := CashFlow.CalcSourceTypeAmount(Enum::"Cash Flow Source Type"::"Purchase Advance Letters CZZ");
                end;
#if not CLEAN19
            end;
#endif
        }
    }
}
