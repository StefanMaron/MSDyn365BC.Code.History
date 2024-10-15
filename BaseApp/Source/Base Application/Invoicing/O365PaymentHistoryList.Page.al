#if not CLEAN21
page 2118 "O365 Payment History List"
{
    Caption = 'Payment History';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
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
                field(Type; Rec.Type)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                    Visible = ShowTypeColumn;
                }
                field(Amount; Rec.Amount)
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
                    Rec.FillPaymentHistory(SalesInvoiceDocNo);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(MarkAsUnpaid_Promoted; MarkAsUnpaid)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OldO365PaymentHistoryBuffer := Rec;
        if Rec.Type <> Rec.Type::Payment then
            Rec."Payment Method" := ''; // Affects FIND/NEXT if user sorted on this column
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if OldO365PaymentHistoryBuffer."Ledger Entry No." <> 0 then
            Rec := OldO365PaymentHistoryBuffer;
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if OldO365PaymentHistoryBuffer."Ledger Entry No." <> 0 then
            Rec := OldO365PaymentHistoryBuffer;
        exit(Rec.Next(Steps));
    end;

    var
        OldO365PaymentHistoryBuffer: Record "O365 Payment History Buffer";
        SalesInvoiceDocNo: Code[20];
        ARecordHasBeenDeleted: Boolean;
        ShowTypeColumn: Boolean;

    procedure ShowHistoryFactbox(SalesInvoiceDocumentNo: Code[20])
    begin
        SalesInvoiceDocNo := SalesInvoiceDocumentNo;
        Rec.FillPaymentHistory(SalesInvoiceDocumentNo);
        ShowTypeColumn := false;
    end;

    procedure ShowHistory(SalesInvoiceDocumentNo: Code[20]): Boolean
    begin
        SalesInvoiceDocNo := SalesInvoiceDocumentNo;
        Rec.FillPaymentHistory(SalesInvoiceDocumentNo);
        ShowTypeColumn := true;
        exit(not Rec.IsEmpty)
    end;

    local procedure MarkPaymentAsUnpaid()
    begin
        if Rec.CancelPayment() then begin
            Rec.FillPaymentHistory(SalesInvoiceDocNo);
            ARecordHasBeenDeleted := true;
        end
    end;

    procedure RecordDeleted(): Boolean
    begin
        exit(ARecordHasBeenDeleted);
    end;
}
#endif
