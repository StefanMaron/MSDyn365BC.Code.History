#if not CLEAN21
page 2105 "O365 Monthly Customer Listpart"
{
    Caption = 'Customers invoiced this month';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = Customer;
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Caption = '';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the customer''s name.';
                    Width = 12;

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"BC O365 Sales Customer Card", Rec);
                    end;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';
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
                    ToolTip = 'Specifies if the customer is blocked so that you cannot create new invoices.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewInvoices)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'View Invoices';
                Image = View;
                ToolTip = 'See this month''s invoices for the customer.';

                trigger OnAction()
                var
                    O365SalesDocument: Record "O365 Sales Document";
                begin
                    O365SalesDocument.SetRange("Sell-to Customer Name", Name);
                    O365SalesDocument.SetRange(Posted, true);
                    O365SalesDocument.SetRange("Document Date", StartOfMonthDate, EndOfMonthDate);
                    PAGE.RunModal(PAGE::"BC O365 Invoice List", O365SalesDocument);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OverdueAmount := CalcOverdueBalance();
    end;

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 0D, WorkDate());
    end;

    var
        OverdueAmount: Decimal;
        BlockedStatus: Text;
        EndOfMonthDate: Date;
        StartOfMonthDate: Date;
        CurrentMonth: Integer;

    procedure InsertData(Month: Integer)
    var
        Customer: Record Customer;
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        CurrentMonthDateFormula: DateFormula;
    begin
        CurrentMonth := Month;
        if not O365SalesStatistics.GenerateMonthlyCustomers(Month, Customer) then
            exit;

        if not Customer.FindSet() then
            exit;
        StartOfMonthDate := DMY2Date(1, CurrentMonth, Date2DMY(WorkDate(), 3));
        Evaluate(CurrentMonthDateFormula, '<CM>');
        EndOfMonthDate := CalcDate(CurrentMonthDateFormula, StartOfMonthDate);
        Customer.SetRange("Date Filter", StartOfMonthDate, EndOfMonthDate);

        DeleteAll();

        repeat
            Customer.CalcFields("Net Change (LCY)");
            TransferFields(Customer, true);
            "Inv. Amounts (LCY)" := Customer."Net Change (LCY)";
            OnInsertDataOnBeforeInsert(Rec, Customer);
            Insert(true);
        until Customer.Next() = 0;

        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDataOnBeforeInsert(var CustomerRec: Record Customer; var Customer: Record Customer)
    begin
    end;
}
#endif
