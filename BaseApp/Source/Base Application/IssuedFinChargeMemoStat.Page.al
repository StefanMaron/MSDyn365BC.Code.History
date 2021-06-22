page 453 "Issued Fin. Charge Memo Stat."
{
    Caption = 'Issued Fin. Charge Memo Stat.';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Issued Fin. Charge Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Interest; Interest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the interest amount that has been calculated on the finance charge memo that has been issued.';
                }
                field("Additional Fee"; "Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the additional fee amounts on the finance charge memo lines.';
                }
                field(VatAmount; VatAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT amount that has been calculated on the finance charge memo that has been issued.';
                }
                field(FinChrgMemoTotal; FinChrgMemoTotal)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount that has been calculated on the issued finance charge memo.';
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies the credit limit in LCY on the customer''s account.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATInterest: Decimal;
    begin
        CalcFields("Interest Amount", "VAT Amount");
        FinChrgMemoTotal := "Additional Fee" + "Interest Amount" + "VAT Amount";
        CustPostingGr.Get("Customer Posting Group");
        GLAcc.Get(CustPostingGr.GetInterestAccount);
        VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
        OnAfterGetVATPostingSetup(VATPostingSetup);
        VATInterest := VATPostingSetup."VAT %";
        GLAcc.Get(CustPostingGr.GetAdditionalFeeAccount);
        VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
        OnAfterGetVATPostingSetup(VATPostingSetup);
        Interest := (FinChrgMemoTotal - "Additional Fee" * (VATPostingSetup."VAT %" / 100 + 1)) /
          (VATInterest / 100 + 1);
        VatAmount := Interest * VATInterest / 100 +
          "Additional Fee" * VATPostingSetup."VAT %" / 100;

        if Cust.Get("Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);
        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
    end;

    var
        Cust: Record Customer;
        FinChrgMemoTotal: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        Interest: Decimal;
        VatAmount: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}

