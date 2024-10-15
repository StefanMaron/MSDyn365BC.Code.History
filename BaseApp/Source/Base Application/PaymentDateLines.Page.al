page 12171 "Payment Date Lines"
{
    AutoSplitKey = true;
    Caption = 'Payment Date Lines';
    DataCaptionFields = "Sales/Purchase", Type, "Code", "Journal Line No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Lines";

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
                    Editable = false;
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
                    Editable = false;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made in order to obtain a discount.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when early payment of an invoice is due in order to get a discount on the amount.';
                }
                field("Discount %"; "Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is applied for early payment of an invoice amount.';
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
                    UpdateAmount;
                end;
            }
        }
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PaymentLines2: Record "Payment Lines";
        Amount: Decimal;
        DocumentAmount: Decimal;
        ResidualTotal: Decimal;
        CurrencyCode: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        LastRec: Boolean;

    [Scope('OnPrem')]
    procedure UpdateAmount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ClearAll;
        if Find('-') then
            repeat
                if Type <> Type::"Blanket Order" then
                    DocType := Type
                else
                    DocType := DocType::"Blanket Order";

                case "Sales/Purchase" of
                    "Sales/Purchase"::" ":
                        if GenJnlLine.Get("Journal Template Name", Code, "Journal Line No.") then begin
                            if GenJnlLine."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else
                                Currency.Get(GenJnlLine."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := GenJnlLine.Amount;
                        end;
                    "Sales/Purchase"::Sales:
                        if SalesHeader.Get(DocType, Code) then begin
                            SalesHeader.CalcFields("Amount Including VAT");
                            if SalesHeader."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else
                                Currency.Get(SalesHeader."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := SalesHeader."Amount Including VAT";
                        end;
                    "Sales/Purchase"::Purchase:
                        if PurchaseHeader.Get(DocType, Code) then begin
                            PurchaseHeader.CalcFields("Amount Including VAT");
                            if PurchaseHeader."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else
                                Currency.Get(PurchaseHeader."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := PurchaseHeader."Amount Including VAT";
                        end;
                    "Sales/Purchase"::Service:
                        if ServiceHeader.Get(DocType, Code) then begin
                            if ServiceHeader."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else
                                Currency.Get(ServiceHeader."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := 0;
                            ServiceLine.Reset;
                            ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                            ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                            if ServiceLine.FindSet then
                                repeat
                                    DocumentAmount := DocumentAmount + ServiceLine."Amount Including VAT";
                                until ServiceLine.Next = 0;
                        end;
                end;

                PaymentLines2.Copy(Rec);
                LastRec := PaymentLines2.Next = 0;
                if LastRec then
                    Amount := DocumentAmount - ResidualTotal
                else begin
                    Amount := Round("Payment %" * DocumentAmount / 100, Currency."Amount Rounding Precision");
                    ResidualTotal := ResidualTotal + Amount;
                end;
                Modify;
            until Next = 0;
    end;
}

