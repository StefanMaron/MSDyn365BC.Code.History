page 7177 "Available Credit"
{
    Caption = 'Available Credit';
    Editable = false;
    PageType = Card;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                    trigger OnDrillDown()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        DtldCustLedgEntry.SetRange("Customer No.", "No.");
                        CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                        CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                        CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                        CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
                    end;
                }
                field("Outstanding Orders (LCY)"; "Outstanding Orders (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on ongoing sales orders.';
                }
                field("Shipped Not Invoiced (LCY)"; "Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipped Not Invd. (LCY)';
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on ongoing sales orders where items have been shipped.';
                }
                field(GetReturnRcdNotInvAmountLCY; GetReturnRcdNotInvAmountLCY)
                {
                    ApplicationArea = Suite;
                    Caption = 'Ret. Rcd. Not Inv. (LCY)';
                    ToolTip = 'Specifies the amount on sales returns from the customer that are not yet refunded.';
                }
                field("Outstanding Invoices (LCY)"; "Outstanding Invoices (LCY)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Outstanding Invoices (LCY)';
                    ToolTip = 'Specifies your expected sales income from the customer in LCY based on unpaid sales invoices.';
                }
                field("Outstanding Serv. Orders (LCY)"; "Outstanding Serv. Orders (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on ongoing service orders.';
                }
                field("Serv Shipped Not Invoiced(LCY)"; "Serv Shipped Not Invoiced(LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on service orders that are shipped but not invoiced.';
                }
                field("Outstanding Serv.Invoices(LCY)"; "Outstanding Serv.Invoices(LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies your expected service income from the customer in LCY based on unpaid service invoices.';
                }
                field(GetTotalAmountLCYUI; GetTotalAmountLCYUI)
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Total (LCY)';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases plus purchases that are still ongoing.';
                }
                field("Credit Limit (LCY)"; "Credit Limit (LCY)")
                {
                    ApplicationArea = Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
                }
                field(CalcAvailableCreditUI; CalcAvailableCreditUI)
                {
                    ApplicationArea = Suite;
                    Caption = 'Available Credit (LCY)';
                    ToolTip = 'Specifies a customer''s available credit. If the available credit is 0 and the customer''s credit limit is also 0, then the customer has unlimited credit because no credit limit has been defined.';
                }
                field("Balance Due (LCY)"; CalcOverdueBalance)
                {
                    ApplicationArea = Suite;
                    CaptionClass = Format(StrSubstNo(Text000, Format(WorkDate)));

                    trigger OnDrillDown()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        DtldCustLedgEntry.SetFilter("Customer No.", "No.");
                        CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                        CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                        CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                        CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                    end;
                }
                field(GetInvoicedPrepmtAmountLCY; GetInvoicedPrepmtAmountLCY)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced Prepayment Amount (LCY)';
                    ToolTip = 'Specifies your sales income from the customer based on invoiced prepayments.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetRange("Date Filter", 0D, WorkDate);
        StyleTxt := SetStyle;
    end;

    var
        Text000: Label 'Overdue Amounts (LCY) as of %1';
        StyleTxt: Text;
}

