#if not CLEAN19
page 11717 "Payment Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Payment Order Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220038)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of partner (customer, vendor, bank account, employee).';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of partner (customer, vendor, bank account, employee).';
                }
                field("Cust./Vendor Bank Account Code"; "Cust./Vendor Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor bank account code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the payment order line.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of partner (customer, vendor, bank account).';
                    Visible = false;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = IBANMissing;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions;
                    end;
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the detail information for payment.';
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Skip Payment"; "Skip Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount must be skipped.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Amount to Pay"; "Amount to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies payment order amount.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount of the original entry.';
                    Visible = false;
                }
                field("Amount (LCY) to Pay"; "Amount (LCY) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies payment order amount in local currency.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Amount(Pay.Order Curr.) to Pay"; "Amount(Pay.Order Curr.) to Pay")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies payment order amount in payment order currency.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Payment Order Currency Code"; "Payment Order Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order currency code.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        PaymentOrderHeader: Record "Payment Order Header";
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        PaymentOrderHeader.Get("Payment Order No.");
                        ChangeExchangeRate.SetParameter("Payment Order Currency Code",
                          "Payment Order Currency Factor", PaymentOrderHeader."Document Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Payment Order Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update();
                        end;
                    end;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment is due.';
                    Visible = false;
                }
                field("Original Due Date"; "Original Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment was due.';
                    Visible = false;
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payment discount date.';
                    Visible = false;
                }
                field("Pmt. Discount Possible"; "Pmt. Discount Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the discount is possible.';
                    Visible = false;
                }
                field("Remaining Pmt. Disc. Possible"; "Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies possible remaining payment discount.';
                    Visible = false;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = AccountNoMissing;
                    ToolTip = 'Specifies the bank account''s international bank account number.';

                    trigger OnValidate()
                    begin
                        SetShowMandatoryConditions;
                    end;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment will be applied to an already-posted document. The field is used only if the account type is a customer or vendor account.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment will be applied to an already-posted document.';
                    Visible = false;
                }
                field("Applies-to C/V/E Entry No."; "Applies-to C/V/E Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment will be applied to an already-posted document.';
                }
                field("Amt. on Issued Payment Orders"; IssuedPaymentOrderLine.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Amt. on Issued Payment Orders';
                    Editable = false;
                    ToolTip = 'Specifies the amount on issued payment orders.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        if "Applies-to C/V/E Entry No." <> 0 then begin
                            Clear(IssuedPaymentOrderLine);
                            IssuedPaymentOrderLine.SetCurrentKey(Type, "Applies-to C/V/E Entry No.", Status);
                            if Type = Type::Customer then
                                IssuedPaymentOrderLine.SetRange(Type, Type::Customer);
                            if Type = Type::Vendor then
                                IssuedPaymentOrderLine.SetRange(Type, Type::Vendor);
                            IssuedPaymentOrderLine.SetRange("Applies-to C/V/E Entry No.", "Applies-to C/V/E Entry No.");
                            IssuedPaymentOrderLine.SetRange(Status, IssuedPaymentOrderLine.Status::" ");
                            PAGE.RunModal(0, IssuedPaymentOrderLine);
                            CurrPage.Update(false);
                        end else
                            FieldError(Type);
                    end;
                }
                field("Amt. on Iss. Pay. Orders (LCY)"; IssuedPaymentOrderLine."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Amt. on Issued Payment Orders (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount on issued payment orders. The amount is in the local currency.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        if "Applies-to C/V/E Entry No." <> 0 then begin
                            Clear(IssuedPaymentOrderLine);
                            IssuedPaymentOrderLine.SetCurrentKey(Type, "Applies-to C/V/E Entry No.", Status);
                            if Type = Type::Customer then
                                IssuedPaymentOrderLine.SetRange(Type, Type::Customer);
                            if Type = Type::Vendor then
                                IssuedPaymentOrderLine.SetRange(Type, Type::Vendor);
                            IssuedPaymentOrderLine.SetRange("Applies-to C/V/E Entry No.", "Applies-to C/V/E Entry No.");
                            IssuedPaymentOrderLine.SetRange(Status, IssuedPaymentOrderLine.Status::" ");
                            PAGE.RunModal(0, IssuedPaymentOrderLine);
                            CurrPage.Update(false);
                        end else
                            FieldError(Type);
                    end;
                }
                field("Amount Must Be Checked"; "Amount Must Be Checked")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies if the amount must be checked.';
                }
                field("Letter Type"; "Letter Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the letter type is a sales (Sales) or a purchase (Purchase).';
                    Visible = false;
                }
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of letter.';
                    Visible = false;
                }
                field("Letter Line No."; "Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies letter line number.';
                    Visible = false;
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the customer must advance pay.';
                    Visible = false;
                }
            }
            group(Control1220001)
            {
                ShowCaption = false;
                field("TotalPaymentOrderHeader.""Amount (Pay.Order Curr.)"""; TotalPaymentOrderHeader."Amount (Pay.Order Curr.)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = TotalPaymentOrderHeader."Payment Order Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalCaption(TotalPaymentOrderHeader."Payment Order Currency Code");
                    Caption = 'Total Amount';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies total amount of payment order';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocumentTotals.CalculatePaymentOrderTotals(TotalPaymentOrderHeader, Rec);
        SetShowMandatoryConditions;
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(IssuedPaymentOrderLine);
        if "Applies-to C/V/E Entry No." <> 0 then begin
            IssuedPaymentOrderLine.SetCurrentKey(Type, "Applies-to C/V/E Entry No.", Status);
            if Type = Type::Customer then
                IssuedPaymentOrderLine.SetRange(Type, Type::Customer);
            if Type = Type::Vendor then
                IssuedPaymentOrderLine.SetRange(Type, Type::Vendor);
            IssuedPaymentOrderLine.SetRange("Applies-to C/V/E Entry No.", "Applies-to C/V/E Entry No.");
            IssuedPaymentOrderLine.SetRange(Status, IssuedPaymentOrderLine.Status::" ");
            IssuedPaymentOrderLine.CalcSums(Amount, "Amount (LCY)");
        end
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        PaymentOrderHeader: Record "Payment Order Header";
        BankAccount: Record "Bank Account";
    begin
        if PaymentOrderHeader.Get("Payment Order No.") then begin
            BankAccount.Get(PaymentOrderHeader."Bank Account No.");
            "Constant Symbol" := BankAccount."Default Constant Symbol";
            "Specific Symbol" := BankAccount."Default Specific Symbol";
            "Currency Code" := PaymentOrderHeader."Currency Code";
            "Payment Order Currency Code" := PaymentOrderHeader."Payment Order Currency Code";
            "Payment Order Currency Factor" := PaymentOrderHeader."Payment Order Currency Factor";
        end else
            if BankAccount.Get(BankAccountNo) then begin
                "Constant Symbol" := BankAccount."Default Constant Symbol";
                "Specific Symbol" := BankAccount."Default Specific Symbol";
                "Currency Code" := BankAccount."Currency Code";
                "Payment Order Currency Code" := BankAccount."Currency Code";
            end;
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm;
    end;

    var
        TotalPaymentOrderHeader: Record "Payment Order Header";
        IssuedPaymentOrderLine: Record "Issued Payment Order Line";
        DocumentTotals: Codeunit "Document Totals";
        BankAccountNo: Code[20];
        IBANMissing: Boolean;
        AccountNoMissing: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(NewBankAccountNo: Code[20])
    begin
        BankAccountNo := NewBankAccountNo;
    end;

    local procedure OnActivateForm()
    var
        PaymentOrderHeader: Record "Payment Order Header";
    begin
        if "Line No." = 0 then
            if PaymentOrderHeader.Get("Payment Order No.") then begin
                Validate("Payment Order Currency Code", PaymentOrderHeader."Payment Order Currency Code");
                "Payment Order Currency Factor" := PaymentOrderHeader."Payment Order Currency Factor";
                CurrPage.Update();
            end;
    end;

    local procedure SetShowMandatoryConditions()
    begin
        IBANMissing := IBAN = '';
        AccountNoMissing := "Account No." = '';
    end;
}
#endif