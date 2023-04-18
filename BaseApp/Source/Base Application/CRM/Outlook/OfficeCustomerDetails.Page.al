page 1611 "Office Customer Details"
{
    Caption = 'Details';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                trigger OnDrillDown()
                begin
                    OpenCustomerLedgerEntries(false);
                end;
            }
            field("Past Due"; PastDue)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Past Due';
                Style = Unfavorable;
                StyleExpr = PastDue > 0;
                ToolTip = 'Specifies the amount of the customer''s balance that is overdue for payment.';
            }
            field("LTD Sales"; GetTotalSales())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'LTD Sales';
                ToolTip = 'Specifies the total life-to-date sales for the customer.';
            }
            field("YTD Sales"; GetYTDSales())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'YTD Sales';
                Editable = false;
                ToolTip = 'Specifies the total year-to-date sales for the customer.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        PastDue := CalcOverdueBalance();
    end;

    var
        CustomerMgt: Codeunit "Customer Mgt.";
        PastDue: Decimal;

    local procedure GetTotalSales(): Decimal
    begin
        exit(CustomerMgt.GetTotalSales("No."));
    end;

    local procedure GetYTDSales(): Decimal
    begin
        exit(CustomerMgt.GetYTDSales("No."));
    end;
}

