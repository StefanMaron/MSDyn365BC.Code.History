#if not CLEAN21
page 2316 "BC O365 Customer List"
{
    // NB! The name of the 'New' action has to be "_NEW_TEMP_" in order for the phone client to show the '+' sign in the list.

    Caption = 'Customers';
    CardPageID = "BC O365 Sales Customer Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Customer;
    SourceTableView = SORTING(Name);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control3)
            {
                Caption = '';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the customer''s name.';
                    Width = 12;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the customer''s email address.';
                    Width = 12;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Outstanding';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the customer''s balance.';
                }
                field(OverdueAmount; OverdueAmount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    BlankZero = true;
                    Caption = 'Overdue';
                    DrillDown = false;
                    Editable = false;
                    Lookup = false;
                    Style = Unfavorable;
                    StyleExpr = OverdueAmount > 0;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';
                }
                field(BlockedStatus; BlockedStatus)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Status';
                    Editable = false;
                    ToolTip = 'Specifies whether the customer is blocked.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Edit';
                RunObject = Page "BC O365 Sales Customer Card";
                RunPageOnRec = true;
                ShortCutKey = 'Return';
                ToolTip = 'Opens the customer card.';
                Visible = false;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OverdueAmount := CalcOverdueBalance();
        O365SalesInvoiceMgmt.GetCustomerStatus(Rec, BlockedStatus);
    end;

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 0D, WorkDate());
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        OverdueAmount: Decimal;
        BlockedStatus: Text;
}
#endif
