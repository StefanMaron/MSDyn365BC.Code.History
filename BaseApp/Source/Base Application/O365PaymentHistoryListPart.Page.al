#if not CLEAN21
page 2119 "O365 Payment History ListPart"
{
    Caption = 'Payment History';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "O365 Payment History Buffer";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Type; Type)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                    Visible = ShowTypeColumn;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the payment received.';
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the date the payment is received.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(MarkAsUnpaid)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Cancel payment registration';
                Gesture = RightSwipe;
                Image = Cancel;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                Scope = Repeater;
                ToolTip = 'Cancel this payment registration.';

                trigger OnAction()
                begin
                    MarkPaymentAsUnpaid();
                end;
            }
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Image = DocumentEdit;
                ShortCutKey = 'Return';
                Visible = false;

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"O365 Payment History Card", Rec);
                    FillPaymentHistory(SalesInvoiceDocNo);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OldO365PaymentHistoryBuffer := Rec;
        if Type <> Type::Payment then
            "Payment Method" := ''; // Affects FIND/NEXT if user sorted on this column
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if OldO365PaymentHistoryBuffer."Ledger Entry No." <> 0 then
            Rec := OldO365PaymentHistoryBuffer;
        exit(Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if OldO365PaymentHistoryBuffer."Ledger Entry No." <> 0 then
            Rec := OldO365PaymentHistoryBuffer;
        exit(Next(Steps));
    end;

    trigger OnOpenPage()
    begin
        SetRange(Type, Type::Payment, Type::Invoice);
    end;

    var
        OldO365PaymentHistoryBuffer: Record "O365 Payment History Buffer";
        SalesInvoiceDocNo: Code[20];
        ARecordHasBeenDeleted: Boolean;
        ShowTypeColumn: Boolean;

    procedure ShowHistoryFactbox(SalesInvoiceDocumentNo: Code[20])
    begin
        SalesInvoiceDocNo := SalesInvoiceDocumentNo;
        FillPaymentHistory(SalesInvoiceDocumentNo);
        ShowTypeColumn := false;
    end;

    procedure ShowHistory(SalesInvoiceDocumentNo: Code[20]): Boolean
    begin
        SalesInvoiceDocNo := SalesInvoiceDocumentNo;
        FillPaymentHistory(SalesInvoiceDocumentNo);
        ShowTypeColumn := true;
        exit(not IsEmpty)
    end;

    local procedure MarkPaymentAsUnpaid()
    begin
        if CancelPayment() then begin
            FillPaymentHistory(SalesInvoiceDocNo);
            ARecordHasBeenDeleted := true;
        end
    end;

    procedure RecordDeleted(): Boolean
    begin
        exit(ARecordHasBeenDeleted);
    end;
}
#endif
