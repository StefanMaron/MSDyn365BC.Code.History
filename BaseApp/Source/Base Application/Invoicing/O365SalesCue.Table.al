table 9069 "O365 Sales Cue"
{
    Caption = 'O365 Sales Cue';
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(3; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(4; "CM Date Filter"; Date)
        {
            Caption = 'CM Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "YTD Date Filter"; Date)
        {
            Caption = 'YTD Date Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(7; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(8; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Non-Applied Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(10; "Invoiced YTD"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Entity Aggregate"."Amount Including VAT" where("Document Date" = field("YTD Date Filter"),
                                                                                             Status = filter(Open | Paid)));
            Caption = 'Invoiced YTD';
            FieldClass = FlowField;
        }
        field(11; "Invoiced CM"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Entity Aggregate"."Amount Including VAT" where("Document Date" = field("CM Date Filter"),
                                                                                             Status = filter(Open | Paid)));
            Caption = 'Invoiced CM';
            FieldClass = FlowField;
        }
        field(12; "Sales Invoices Outstanding"; Decimal)
        {
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)");
            Caption = 'Sales Invoices Outstanding';
            FieldClass = FlowField;
        }
        field(13; "Sales Invoices Overdue"; Decimal)
        {
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Initial Entry Due Date" = field("Overdue Date Filter")));
            Caption = 'Sales Invoices Overdue';
            FieldClass = FlowField;
        }
        field(14; "No. of Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Quote)));
            Caption = 'No. of Quotes';
            FieldClass = FlowField;
        }
        field(15; "No. of Draft Invoices"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Invoice)));
            Caption = 'No. of Draft Invoices';
            FieldClass = FlowField;
        }
        field(16; "No. of Invoices YTD"; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Posting Date" = field("YTD Date Filter")));
            Caption = 'No. of Invoices YTD';
            FieldClass = FlowField;
        }
        field(17; "Requested DateTime"; DateTime)
        {
            Caption = 'Requested DateTime';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21
    var
        NoOutstandingMsg: Label 'There are no outstanding invoices.';
        NoOverdueMsg: Label 'There are no overdue invoices.';
        RequestedDateMustBeInAccountingPeriodErr: Label 'The requested date must be in the current fiscal year ''%1..%2''.', Comment = '%1 = The first date of the current fiscal year, %2 = The last date of the current fiscal year.';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure OnOpenActivitiesPage(var CurrencyFormatTxt: Text)
    begin
        OnOpenActivitiesPageForRequestedDate(CurrencyFormatTxt, 0DT);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure OnOpenActivitiesPageForRequestedDate(var CurrencyFormatTxt: Text; RequestedDateTime: DateTime)
    var
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        RequestedDate: Date;
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert();
        end;

        O365SalesStatistics.GetCurrentAccountingPeriod(AccountingPeriod);

        if RequestedDateTime <> 0DT then begin
            RequestedDate := DT2Date(RequestedDateTime);

            if (AccountingPeriod.GetFiscalYearStartDate(WorkDate()) > RequestedDate) or
               (AccountingPeriod.GetFiscalYearEndDate(WorkDate()) < RequestedDate)
            then
                Error(RequestedDateMustBeInAccountingPeriodErr,
                  AccountingPeriod.GetFiscalYearStartDate(WorkDate()),
                  AccountingPeriod.GetFiscalYearEndDate(WorkDate()));
        end else
            RequestedDate := WorkDate();

        SetFilter("Due Date Filter", '..%1', RequestedDate);
        SetFilter("Overdue Date Filter", '<%1', RequestedDate);
        SetFilter("CM Date Filter", '%1..%2', CalcDate('<CM+1D-1M>', RequestedDate), RequestedDate);
        SetFilter("YTD Date Filter", '%1..%2', AccountingPeriod."Starting Date", RequestedDate);

        GLSetup.Get();

        CurrencyFormatTxt := StrSubstNo('%1<precision, 0:0><standard format, 0>', GLSetup.GetCurrencySymbol());

        if GuiAllowed then begin
            RoleCenterNotificationMgt.ShowNotifications();
            ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();
        end
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowInvoices(OnlyOverdue: Boolean)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        Customer: Record Customer;
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
    begin
        SalesInvoiceEntityAggregate.SetRange(Status, SalesInvoiceEntityAggregate.Status::Open);
        if OnlyOverdue then
            SalesInvoiceEntityAggregate.SetFilter("Due Date", '<%1', WorkDate());

        if O365SalesStatistics.GetCustomersFromSalesInvoiceEntityAggregates(SalesInvoiceEntityAggregate, Customer) then
            PAGE.Run(PAGE::"BC O365 Customer List", Customer)
        else // no customers
            if OnlyOverdue then
                Message(NoOverdueMsg)
            else
                Message(NoOutstandingMsg);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowMonthlySalesOverview()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Month: Integer;
    begin
        Month := Date2DMY(WorkDate(), 2);
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := Month;
        TempNameValueBuffer.Insert();

        PAGE.Run(PAGE::"O365 Sales Month Summary", TempNameValueBuffer);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowYearlySalesOverview()
    var
        O365SalesStatistics: Codeunit "O365 Sales Statistics";
        O365SalesYearSummaryCard: Page "O365 Sales Year Summary Card";
    begin
        if O365SalesStatistics.GetRelativeMonthToFY() <> 1 then begin
            O365SalesYearSummaryCard.ShowMonthlyDataPart();
            O365SalesYearSummaryCard.Run();
        end else
            ShowMonthlySalesOverview(); // the current month is the first month in the FY
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowQuotes()
    begin
        ShowUnpostedDocuments(true);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowDraftInvoices()
    begin
        ShowUnpostedDocuments(false);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowUnpostedDocuments(FilterToQuotes: Boolean)
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        O365SalesDocument.SetRange(Posted, false);
        if FilterToQuotes then begin
            O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Quote);
            PAGE.Run(PAGE::"BC O365 Estimate List", O365SalesDocument);
        end else begin
            O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Invoice);
            PAGE.Run(PAGE::"BC O365 Invoice List", O365SalesDocument);
        end;
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ShowUnpaidInvoices()
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        O365SalesDocument.SetRange(Posted, true);
        O365SalesDocument.SetRange("Document Type", O365SalesDocument."Document Type"::Invoice);
        O365SalesDocument.SetFilter("Outstanding Amount", '>0');
        O365SalesDocument.SetSortByDueDate();
        PAGE.Run(PAGE::"BC O365 Invoice List", O365SalesDocument);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetNumberOfUnpaidInvoices() Number: Integer
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesInvoiceEntityAggregate.SetRange(Posted, true);
        SalesInvoiceEntityAggregate.SetRange(Status, SalesInvoiceEntityAggregate.Status::Open);
        Number := SalesInvoiceEntityAggregate.Count();
    end;
#endif
}

