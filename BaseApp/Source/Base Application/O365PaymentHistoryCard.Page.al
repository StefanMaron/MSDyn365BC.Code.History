page 2125 "O365 Payment History Card"
{
    Caption = 'Payment History';
    DataCaptionExpression = Format(Type);
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Manage';
    ShowFilter = false;
    SourceTable = "O365 Payment History Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Group)
            {
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the payment received.';
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the date the payment is received.';
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Cancel payment registration';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ToolTip = 'Cancel this payment registration.';

                trigger OnAction()
                begin
                    MarkPaymentAsUnpaid;
                end;
            }
        }
    }

    local procedure MarkPaymentAsUnpaid()
    begin
        if CancelPayment then
            CurrPage.Close;
    end;
}

