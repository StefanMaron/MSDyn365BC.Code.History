page 2116 "O365 Customer Lookup"
{
    Caption = 'Customers';
    CardPageID = "O365 Sales Customer Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Customer;
    SourceTableView = SORTING(Name)
                      WHERE(Blocked = CONST(" "));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Caption = '';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the customer''s name. This name will appear on all sales documents for the customer.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the customer''s telephone number.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';
                }
                field("Balance Due (LCY)"; "Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = OverdueBalanceAutoFormatExpr;
                    AutoFormatType = 10;
                    BlankZero = true;
                    Style = Attention;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';

                    trigger OnDrillDown()
                    begin
                        OpenCustomerLedgerEntries(true);
                    end;
                }
                field("Sales (LCY)"; "Sales (LCY)")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the total net amount of sales to the customer in LCY.';
                }
            }
        }
        area(factboxes)
        {
            part(Control3; "O365 Sales Hist.Sell-toFactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Balance Due (LCY)" := CalcOverdueBalance;
    end;

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 0D, WorkDate);
        OverdueBalanceAutoFormatExpr := StrSubstNo(AutoFormatExprWithPrefixTxt, OverdueTxt);
    end;

    var
        AutoFormatExprWithPrefixTxt: Label '1,,%1', Locked = true;
        OverdueTxt: Label 'Overdue:';
        OverdueBalanceAutoFormatExpr: Text;
}

