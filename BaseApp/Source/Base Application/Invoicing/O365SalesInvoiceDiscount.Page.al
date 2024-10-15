#if not CLEAN21
page 2155 "O365 Sales Invoice Discount"
{
    Caption = 'Edit Discount';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Sales Header";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field("Subtotal Amount"; SubTotalAmount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    Caption = 'Before Discount';
                    Editable = false;
                    ToolTip = 'Specifies the subtotal amount of invoice without discount';
                }
                group("Specify Discount")
                {
                    Caption = 'Specify Discount';
                    field("Invoice Disc. Pct."; InvoiceDiscountPct)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Discount %';
                        DecimalPlaces = 1 : 3;
                        ToolTip = 'Specifies a discount percentage that is applied to the invoice, based on sales lines where the Allow Invoice Disc. field is selected. The percentage and criteria are defined in the Customer Invoice Discounts page, but you can enter or change the percentage manually.';

                        trigger OnValidate()
                        begin
                            InvoiceDiscountPct := GetValueWithinBounds(InvoiceDiscountPct, 0, 100);
                            ValidateInvoiceDiscountPercent();
                        end;
                    }
                    field("Invoice Discount Amount"; InvoiceDiscountAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        Caption = 'Discount Amount';
                        ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on sales lines where the Allow Invoice Disc. field is selected. You can enter or change the amount manually.';

                        trigger OnValidate()
                        begin
                            InvoiceDiscountAmount := GetValueWithinBounds(InvoiceDiscountAmount, 0, SubTotalAmount);
                            if SubTotalAmount <> 0 then
                                InvoiceDiscountPct := InvoiceDiscountAmount / SubTotalAmount * 100
                            else
                                InvoiceDiscountPct := 0;
                            ValidateInvoiceDiscountPercent();
                        end;
                    }
                }
                group(Totals)
                {
                    Caption = 'Total After Discount';
                    field(TotalAmount; TotalAmount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = GetCaptionClass();
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';

                        trigger OnValidate()
                        begin
                            TotalAmount := GetValueWithinBounds(TotalAmount, 0, SubTotalAmount);
                            if SubTotalAmount <> 0 then
                                InvoiceDiscountPct := (SubTotalAmount - TotalAmount) / SubTotalAmount * 100
                            else
                                InvoiceDiscountAmount := 0;
                            ValidateInvoiceDiscountPercent();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalculateTotals();
        if not IsInitialized then begin
            IsInitialized := true;
            OriginalInvoiceDiscount := InvoiceDiscountPct;
            if OverrideInitialDiscountPercentage then begin
                InvoiceDiscountPct := InitialDiscountPercentage;
                ValidateInvoiceDiscountPercent();
                CalculateTotals();
            end;
        end;
    end;

    trigger OnInit()
    begin
        SalesSetup.Get();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRecFilter();
        CalculateTotals();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [ACTION::LookupOK, ACTION::OK]) then
            RestoreInvoiceDiscountPercent(OriginalInvoiceDiscount);

        if (CloseAction in [ACTION::LookupOK, ACTION::OK]) and (OriginalInvoiceDiscount <> InvoiceDiscountPct) then
            Session.LogMessage('000023Y', InvoiceDiscountAppliedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvoiceDiscountCategoryLbl);

        Rec.CalcInvDiscForHeader();
    end;

    var
        TotalSalesHeader: Record "Sales Header";
        TotalSalesLine: Record "Sales Line";
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        O365Discounts: Codeunit "O365 Discounts";
        InvoiceDiscountPct: Decimal;
        InvoiceDiscountAmount: Decimal;
        SubTotalAmount: Decimal;
        TotalAmount: Decimal;
        TotalTxt: Label 'Total';
        VATAmount: Decimal;
        AmountOutsideRangeMsg: Label 'We adjusted the discount to not exceed the line amount.';
        OriginalInvoiceDiscount: Decimal;
        InitialDiscountPercentage: Decimal;
        OverrideInitialDiscountPercentage: Boolean;
        IsInitialized: Boolean;
        AmountOutsideOfBoundsNotificationSend: Boolean;
        InvoiceDiscountCategoryLbl: Label 'AL Discount', Locked = true;
        InvoiceDiscountAppliedTelemetryTxt: Label 'Invoice discount applied.', Locked = true;

    procedure SetInitialDiscountPercentage(DiscountPercentage: Decimal)
    begin
        OverrideInitialDiscountPercentage := true;
        InitialDiscountPercentage := DiscountPercentage;
    end;

    local procedure CalculateTotals()
    var
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        GetTotalSalesHeader();
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."No.");
        if SalesLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

            DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);
            SubTotalAmount := TotalSalesLine."Line Amount";

            if Rec."Prices Including VAT" then
                TotalAmount := TotalSalesLine.Amount + VATAmount
            else
                TotalAmount := TotalSalesLine.Amount;

            InvoiceDiscountAmount := TotalSalesLine."Inv. Discount Amount";
            InvoiceDiscountPct := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine);
        end;

        if CustInvoiceDisc.Get(Rec."Invoice Disc. Code", Rec."Currency Code", 0) then;
        InvoiceDiscountPct := CustInvoiceDisc."Discount %";
    end;

    local procedure GetTotalSalesHeader()
    begin
        if not TotalSalesHeader.Get(Rec."Document Type", Rec."No.") then
            Clear(TotalSalesHeader);
        if Currency.Code <> TotalSalesHeader."Currency Code" then
            if not Currency.Get(TotalSalesHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure ValidateInvoiceDiscountPercent()
    begin
        O365Discounts.ApplyInvoiceDiscountPercentage(Rec, InvoiceDiscountPct);
        CurrPage.Update(true);
    end;

    local procedure GetCaptionClass(): Text
    begin
        if Rec."Prices Including VAT" then
            exit('2,1,' + TotalTxt);

        exit('2,0,' + TotalTxt);
    end;

    local procedure GetValueWithinBounds(Value: Decimal; MinValue: Decimal; MaxValue: Decimal): Decimal
    begin
        if Value < MinValue then begin
            SendOutsideRangeNotification();
            exit(MinValue);
        end;
        if Value > MaxValue then begin
            SendOutsideRangeNotification();
            exit(MaxValue);
        end;
        exit(Value);
    end;

    local procedure SendOutsideRangeNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AmountOutOfBoundsNotification: Notification;
    begin
        if AmountOutsideOfBoundsNotificationSend then
            exit;
        AmountOutOfBoundsNotification.Id := CreateGuid();
        AmountOutOfBoundsNotification.Message := AmountOutsideRangeMsg;
        AmountOutOfBoundsNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        GetTotalSalesHeader();
        NotificationLifecycleMgt.SendNotification(AmountOutOfBoundsNotification, TotalSalesHeader.RecordId);
        AmountOutsideOfBoundsNotificationSend := true;
    end;

    local procedure RestoreInvoiceDiscountPercent(OldInvoiceDiscountPercent: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        if CustInvoiceDisc.Get(Rec."Invoice Disc. Code", Rec."Currency Code", 0) then begin
            CustInvoiceDisc."Discount %" := OldInvoiceDiscountPercent;
            CustInvoiceDisc.Modify(true);
        end;
    end;
}
#endif
