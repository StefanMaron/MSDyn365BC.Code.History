page 441 "Issued Reminder Statistics"
{
    Caption = 'Issued Reminder Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Issued Reminder Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the remaining amounts on the reminder lines.';
                }
                field(Interest; Interest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the amount of interest for the issued reminder.';
                }
                field("Additional Fee"; "Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the additional fee amounts on the reminder lines.';
                }
                field(VatAmount; VatAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Amount';
                    DrillDown = false;
                    ToolTip = 'Specifies the VAT amount that has been calculated, on the issued reminder amount.';
                }
                field("Add. Fee per Line"; "Add. Fee per Line")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
                }
                field(ReminderTotal; ReminderTotal)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount due on the issued reminder, including interest, VAT, and additional fee.';
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
        ReminderLevel: Record "Reminder Level";
        VATInterest: Decimal;
    begin
        CalcFields("Interest Amount", "VAT Amount", "Add. Fee per Line");
        ReminderTotal := "Remaining Amount" + "Additional Fee" + "Interest Amount" + "VAT Amount" + "Add. Fee per Line";
        VatAmount := "VAT Amount";
        CustPostingGr.Get("Customer Posting Group");
        if ReminderLevel.Get("Reminder Terms Code", "Reminder Level") then
            if ReminderLevel."Calculate Interest" and ("VAT Amount" <> 0) then begin
                GLAcc.Get(CustPostingGr."Interest Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                OnAfterGetVATPostingSetup(VATPostingSetup);
                VATInterest := VATPostingSetup."VAT %";
                if GLAcc.Get(CustPostingGr."Additional Fee Account") then begin
                    VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                    OnAfterGetVATPostingSetup(VATPostingSetup);
                end;
                Interest :=
                  (ReminderTotal -
                   "Remaining Amount" - ("Additional Fee" + "Add. Fee per Line") * (VATPostingSetup."VAT %" / 100 + 1)) /
                  (VATInterest / 100 + 1);
                VatAmount := Interest * VATInterest / 100 + "Additional Fee" * VATPostingSetup."VAT %" / 100 + CalculateLineFeeVATAmount;
            end else
                Interest := "Interest Amount";

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
        ReminderTotal: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        Interest: Decimal;
        VatAmount: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
}

