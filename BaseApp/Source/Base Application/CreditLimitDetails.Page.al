page 1871 "Credit Limit Details"
{
    Caption = 'Details';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the customer''s name.';
            }
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                trigger OnDrillDown()
                begin
                    OpenCustomerLedgerEntries(false);
                end;
            }
            field(OutstandingAmtLCY; OrderAmountTotalLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Outstanding Amt. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales to the customer that remains to be shipped. The amount is calculated as Amount x Outstanding Quantity / Quantity.';
            }
            field(ShippedRetRcdNotIndLCY; ShippedRetRcdNotIndLCY)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Shipped/Ret. Rcd. Not Invd. (LCY)';
                Editable = false;
                ToolTip = 'Specifies the amount on sales returns from the customer that are not yet refunded';
            }
            field(OrderAmountThisOrderLCY; OrderAmountThisOrderLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Current Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies the total amount the whole sales document.';
            }
            field(TotalAmountLCY; CustCreditAmountLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies the sum of the amounts in all of the preceding fields in the window.';
            }
            field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
            }
            field(OverdueBalance; CalcOverdueBalance())
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = OverdueAmountsTxt;
                Editable = false;
                ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';

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
            field(GetInvoicedPrepmtAmountLCY; GetInvoicedPrepmtAmountLCY())
            {
                ApplicationArea = Prepayments;
                Caption = 'Invoiced Prepayment Amount (LCY)';
                Editable = false;
                ToolTip = 'Specifies your sales income from the customer based on invoiced prepayments.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if GetFilter("Date Filter") = '' then
            SetFilter("Date Filter", '..%1', WorkDate());
        CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)", "Serv Shipped Not Invoiced(LCY)");
    end;

    var
        OrderAmountTotalLCY: Decimal;
        ShippedRetRcdNotIndLCY: Decimal;
        OrderAmountThisOrderLCY: Decimal;
        CustCreditAmountLCY: Decimal;
#if not CLEAN20
        ExtensionAmounts: List of [Decimal];
#endif
        ExtensionAmountsDic: Dictionary of [Guid, Decimal];
        OverdueAmountsTxt: Label 'Overdue Amounts (LCY)';

    procedure PopulateDataOnNotification(var CreditLimitNotification: Notification)
    begin
        CreditLimitNotification.SetData(FieldName("No."), Format("No."));
        CreditLimitNotification.SetData('OrderAmountTotalLCY', Format(OrderAmountTotalLCY));
        CreditLimitNotification.SetData('ShippedRetRcdNotIndLCY', Format(ShippedRetRcdNotIndLCY));
        CreditLimitNotification.SetData('OrderAmountThisOrderLCY', Format(OrderAmountThisOrderLCY));
        CreditLimitNotification.SetData('CustCreditAmountLCY', Format(CustCreditAmountLCY));

#if not CLEAN20
        OnAfterPopulateDataOnNotification(CreditLimitNotification, ExtensionAmounts);
#endif
        OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification, ExtensionAmountsDic);
    end;

    procedure InitializeFromNotificationVar(CreditLimitNotification: Notification)
    var
        Customer: Record Customer;
    begin
        Get(CreditLimitNotification.GetData(Customer.FieldName("No.")));
        SetRange("No.", "No.");

        if GetFilter("Date Filter") = '' then
            SetFilter("Date Filter", '..%1', WorkDate());
        CalcFields("Balance (LCY)", "Shipped Not Invoiced (LCY)", "Serv Shipped Not Invoiced(LCY)");

        Evaluate(OrderAmountTotalLCY, CreditLimitNotification.GetData('OrderAmountTotalLCY'));
        Evaluate(ShippedRetRcdNotIndLCY, CreditLimitNotification.GetData('ShippedRetRcdNotIndLCY'));
        Evaluate(OrderAmountThisOrderLCY, CreditLimitNotification.GetData('OrderAmountThisOrderLCY'));
        Evaluate(CustCreditAmountLCY, CreditLimitNotification.GetData('CustCreditAmountLCY'));

#if not CLEAN20
        OnAfterInitializeFromNotificationVar(CreditLimitNotification, ExtensionAmounts);
#endif
        OnAfterInitializeFromNotificationVarProcedure(CreditLimitNotification, ExtensionAmountsDic);
    end;

    procedure SetCustomerNumber(Value: Code[20])
    begin
        Get(Value);
    end;

    procedure SetOrderAmountTotalLCY(Value: Decimal)
    begin
        OrderAmountTotalLCY := Value;
    end;

    procedure SetShippedRetRcdNotIndLCY(Value: Decimal)
    begin
        ShippedRetRcdNotIndLCY := Value;
    end;

    procedure SetOrderAmountThisOrderLCY(Value: Decimal)
    begin
        OrderAmountThisOrderLCY := Value;
    end;

    procedure SetCustCreditAmountLCY(Value: Decimal)
    begin
        CustCreditAmountLCY := Value;
    end;

#if not CLEAN20
    [Obsolete('Replaced by SetExtensionAmounts(FromExtensionAmounts: Dictionary of [Guid, Decimal])', '20.0')]
    procedure SetExtensionAmounts(FromExtensionAmounts: List of [Decimal])
    begin
        ExtensionAmounts := FromExtensionAmounts;
    end;

    [Obsolete('Replaced by GetExtensionAmounts(var ToExtensionAmounts: Dictionary of [Guid, Decimal])', '20.0')]
    procedure GetExtensionAmounts(var ToExtensionAmounts: List of [Decimal])
    begin
        ToExtensionAmounts := ExtensionAmounts;
    end;
#endif

    procedure SetExtensionAmounts(FromExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ExtensionAmountsDic := FromExtensionAmounts;
    end;

    procedure GetExtensionAmounts(var ToExtensionAmounts: Dictionary of [Guid, Decimal])
    begin
        ToExtensionAmounts := ExtensionAmountsDic;
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnAfterPopulateDataOnNotificationProcedure()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateDataOnNotification(var CreditLimitNotification: Notification; var ExtensionAmounts: List of [Decimal])
    begin
    end;

    [Obsolete('Replaced by OnAfterInitializeFromNotificationVarProcedure()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeFromNotificationVar(CreditLimitNotification: Notification; var ExtensionAmounts: List of [Decimal])
    begin
    end;
#endif    

    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateDataOnNotificationProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeFromNotificationVarProcedure(CreditLimitNotification: Notification; var ExtensionAmountsDic: Dictionary of [Guid, Decimal])
    begin
    end;
}

