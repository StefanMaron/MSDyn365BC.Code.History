page 2154 "O365 Payment Method List"
{
    Caption = 'Payment Methods';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    ShowFilter = false;
    SourceTable = "O365 Payment Method";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Short name';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the payment method.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunPageMode = Create;
                ToolTip = 'Create a new payment method.';

                trigger OnAction()
                begin
                    if PAGE.RunModal(PAGE::"BC O365 Payment Method Card") = ACTION::LookupOK then;
                end;
            }
            action(EditPaymentMethod)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Edit this payment term';

                trigger OnAction()
                var
                    PaymentMethod: Record "Payment Method";
                    BCO365PaymentMethodCard: Page "BC O365 Payment Method Card";
                begin
                    if PaymentMethod.Get(Code) then begin
                        BCO365PaymentMethodCard.SetPaymentMethod(PaymentMethod);
                        BCO365PaymentMethodCard.LookupMode(true);
                        if BCO365PaymentMethodCard.RunModal = ACTION::LookupOK then;
                    end;
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshRecords;

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        RefreshRecords;
    end;
}

