page 12176 "Subform Customer Bill Line"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Customer Bill Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the identification number of the customer from the posted invoice.';
                }
                field("Customer Name"; "Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the customer from the posted invoice.';
                }
                field("Temporary Cust. Bill No."; "Temporary Cust. Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary identification number for the customer bill.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that is the source of the customer bill.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a unique identification number that refers to the source document that generated the customer bill entry.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the transaction date of the source document that generated the customer bill entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the customer''s amount due for payment.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is due for payment.';
                }
                field("Customer Bank Acc. No."; "Customer Bank Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the bank that is managing the customer''s bills.';
                }
                field("Cumulative Bank Receipts"; "Cumulative Bank Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer bill entry is included in a cumulative bank receipt.';
                }
                field("Recalled by"; "Recalled by")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if a customer bill has been recalled.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mandate.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SelectBillToRecall)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Bill to Recall';
                    ShortCutKey = 'F7';
                    ToolTip = 'Specify the customer bill to recall.';

                    trigger OnAction()
                    begin
                        RecallBill;
                    end;
                }
            }
        }
    }

    var
        Text1130000: Label 'You can run this function only when field %1 in table %2 is %3.';

    [Scope('OnPrem')]
    procedure RecallBill()
    var
        PaymentMethod: Record "Payment Method";
        CustBillHeader: Record "Customer Bill Header";
        Bill: Record Bill;
    begin
        CustBillHeader.Get("Customer Bill No.");
        PaymentMethod.Get(CustBillHeader."Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");

        if not Bill."Allow Issue" then
            Error(Text1130000,
              Bill.FieldCaption("Allow Issue"),
              Bill.TableCaption,
              true);

        if "Line No." <> 0 then begin
            if "Recalled by" <> '' then
                "Recalled by" := ''
            else
                if UserId <> '' then
                    "Recalled by" := UserId
                else
                    "Recalled by" := '***';
            Modify;
        end;
    end;
}

