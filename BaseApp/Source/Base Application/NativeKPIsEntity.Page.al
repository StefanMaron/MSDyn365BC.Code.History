#if not CLEAN20
page 2800 "Native - KPIs Entity"
{
    Caption = 'nativeInvoicingRoleCenterKpi', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Description = 'ENU=Activites';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "O365 Sales Cue";
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control7)
            {
                ShowCaption = false;
                field(primaryKey; "Primary Key")
                {
                    ApplicationArea = All;
                    Caption = 'primaryKey', Locked = true;
                }
                field(invoicedYearToDate; invoicedYTD)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'invoicedYearToDate', Locked = true;
                    ToolTip = 'Specifies the total invoiced amount for this year.';
                }
                field(numberOfInvoicesYearToDate; "No. of Invoices YTD")
                {
                    ApplicationArea = All;
                    Caption = 'numberOfInvoicesYearToDate', Locked = true;
                    ToolTip = 'Specifies the total number of invoices for this year.';
                }
                field(invoicedCurrentMonth; invoicedCM)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'invoicedCurrentMonth', Locked = true;
                    ToolTip = 'Specifies the total amount invoiced for the current month.';
                }
                field(salesInvoicesOutsdanding; salesInvoicesOutstanding)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'salesInvoicesOutstanding', Locked = true;
                    ToolTip = 'Specifies the total amount that has not yet been paid.';
                }
                field(salesInvoicesOverdue; salesInvoicesOverdue)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyFormatTxt;
                    AutoFormatType = 11;
                    Caption = 'salesInvoicesOverdue', Locked = true;
                    ToolTip = 'Specifies the total amount that has not been paid and is after the due date.';
                }
                field(numberOfQuotes; "No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'numberOfQuotes', Locked = true;
                    ToolTip = 'Specifies the number of estimates.';
                }
                field(numberOfDraftInvoices; "No. of Draft Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'numberOfDraftInvoices', Locked = true;
                    ToolTip = 'Specifies the number of draft invoices.';
                }
                field(requestedDateTime; "Requested DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'requestedDateTime';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Invoiced CM", "Invoiced YTD", "Sales Invoices Outstanding", "Sales Invoices Overdue");
        invoicedCM := "Invoiced CM";
        invoicedYTD := "Invoiced YTD";
        salesInvoicesOutstanding := "Sales Invoices Outstanding";
        salesInvoicesOverdue := "Sales Invoices Overdue";
        "Requested DateTime" := RequestedDateTime;
    end;

    trigger OnOpenPage()
    begin
        if not Evaluate(RequestedDateTime, GetFilter("Requested DateTime")) then
            Error(OnlySupportForEqualFilterErr);

        OnOpenActivitiesPageForRequestedDate(CurrencyFormatTxt, RequestedDateTime);
    end;

    var
        CurrencyFormatTxt: Text;
        invoicedYTD: Decimal;
        invoicedCM: Decimal;
        salesInvoicesOutstanding: Decimal;
        salesInvoicesOverdue: Decimal;
        OnlySupportForEqualFilterErr: Label 'We only support the equals filter on the requestedDateTime field.';
        RequestedDateTime: DateTime;
}
#endif
