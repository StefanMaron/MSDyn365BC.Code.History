#if not CLEAN21
page 2125 "O365 Payment History Card"
{
    Caption = 'Payment History';
    DataCaptionExpression = Format(Type);
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
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
            group(Group)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
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
                Image = Cancel;
                ToolTip = 'Cancel this payment registration.';

                trigger OnAction()
                begin
                    MarkPaymentAsUnpaid();
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

    local procedure MarkPaymentAsUnpaid()
    begin
        if CancelPayment() then
            CurrPage.Close();
    end;
}
#endif
