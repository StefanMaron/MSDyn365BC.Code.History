page 12172 "Posted Payments"
{
    Caption = 'Posted Payments';
    DataCaptionFields = "Sales/Purchase", Type, "Code";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Payment Lines";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment %"; "Payment %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the transaction amount that is issued as an installment payment.';
                }
                field("Due Date Calculation"; "Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made for a purchase or sales invoice.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment is due.';
                }
                field("Discount Date Calculation"; "Discount Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made in order to obtain a discount.';
                }
                field("Discount %"; "Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is applied for early payment of an invoice amount.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when early payment of an invoice is due in order to get a discount on the amount.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = false;
                    ToolTip = 'Specifies the amount due.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RecalcAmount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalc. Amount';
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Recalculate amounts based on the current information.';

                trigger OnAction()
                begin
                    UpdateAmount
                end;
            }
        }
    }

    var
        Currency: Record Currency;
        PostedPaymentLines2: Record "Posted Payment Lines";
        DocumentAmount: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[20];
        LastRec: Boolean;
        ResidualTotal: Decimal;

    [Scope('OnPrem')]
    procedure UpdateAmount()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ClearAll;
        if Find('-') then
            repeat
                DocumentAmount := 0;
                case "Sales/Purchase" of
                    "Sales/Purchase"::Sales:
                        case Type of
                            Type::Invoice:
                                if SalesInvoiceHeader.Get(Code) then begin
                                    SalesInvoiceHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := SalesInvoiceHeader."Amount Including VAT";
                                    CurrencyCode := SalesInvoiceHeader."Currency Code";
                                end;
                            Type::"Credit Memo":
                                if SalesCrMemoHeader.Get(Code) then begin
                                    CurrencyCode := SalesCrMemoHeader."Currency Code";
                                    SalesCrMemoHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := SalesCrMemoHeader."Amount Including VAT";
                                end;
                        end;
                    "Sales/Purchase"::Purchase:
                        case Type of
                            Type::Invoice:
                                if PurchInvHeader.Get(Code) then begin
                                    PurchInvHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := PurchInvHeader."Amount Including VAT";
                                    CurrencyCode := PurchInvHeader."Currency Code";
                                end;
                            Type::"Credit Memo":
                                if PurchCrMemoHdr.Get(Code) then begin
                                    CurrencyCode := PurchCrMemoHdr."Currency Code";
                                    PurchCrMemoHdr.CalcFields("Amount Including VAT");
                                    DocumentAmount := PurchCrMemoHdr."Amount Including VAT";
                                end;
                        end;
                    "Sales/Purchase"::Service:
                        if ServiceInvoiceHeader.Get(Code) then begin
                            CurrencyCode := ServiceInvoiceHeader."Currency Code";
                            ServiceInvoiceLine.Reset();
                            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
                            if ServiceInvoiceLine.FindSet then
                                repeat
                                    DocumentAmount := DocumentAmount + ServiceInvoiceLine."Amount Including VAT";
                                until ServiceInvoiceLine.Next() = 0;
                        end else
                            if ServiceCrMemoHeader.Get(Code) then begin
                                CurrencyCode := ServiceCrMemoHeader."Currency Code";
                                ServiceCrMemoLine.Reset();
                                ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
                                if ServiceCrMemoLine.FindSet then
                                    repeat
                                        DocumentAmount := DocumentAmount + ServiceCrMemoLine."Amount Including VAT";
                                    until ServiceCrMemoLine.Next() = 0;
                            end;
                end;

                if CurrencyCode = '' then
                    Currency.InitRoundingPrecision
                else begin
                    Currency.Get(CurrencyCode);
                    Currency.TestField("Amount Rounding Precision");
                end;

                Amount := "Payment %" * DocumentAmount / 100;
                PostedPaymentLines2.Copy(Rec);
                LastRec := PostedPaymentLines2.Next() = 0;
                if LastRec then
                    Amount := DocumentAmount - ResidualTotal
                else begin
                    Amount := Round("Payment %" * DocumentAmount / 100, Currency."Amount Rounding Precision");
                    ResidualTotal := ResidualTotal + Amount;
                end;
                Modify;
            until Next() = 0;
    end;
}

