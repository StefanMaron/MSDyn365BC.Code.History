#if not CLEAN21
page 2306 "BC O365 Cust. Stats FactBox"
{
    Caption = 'Customer statistics';
    PageType = CardPart;
    SourceTable = Customer;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Customer name';
                ToolTip = 'Specifies the name of the customer that the FactBox refers to.';

                trigger OnDrillDown()
                begin
                    PAGE.Run(PAGE::"BC O365 Sales Customer Card", Rec);
                end;
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Outstanding';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the balance in the customer''s payments.';
                }
                field(OverdueBalance; OverdueBalance)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Overdue';
                    DrillDown = false;
                    Editable = false;
                    Lookup = false;
                    Style = Unfavorable;
                    StyleExpr = OverdueBalance > 0;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';
                }
                field("Sales (LCY)"; Rec."Sales (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Total Sales (Excl. VAT)';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the total net amount of sales to the customer.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        OverdueBalance := CalcOverdueBalance();
    end;

    var
        OverdueBalance: Decimal;
}
#endif
