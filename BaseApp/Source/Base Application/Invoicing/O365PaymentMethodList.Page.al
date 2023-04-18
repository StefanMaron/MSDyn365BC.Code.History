#if not CLEAN21
page 2154 "O365 Payment Method List"
{
    Caption = 'Payment Methods';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "O365 Payment Method";
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
                field("Code"; Code)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Short name';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                RunPageMode = Create;
                ToolTip = 'Create a new payment method.';

                trigger OnAction()
                begin
                    if PAGE.RunModal(PAGE::"BC O365 Payment Method Card") = ACTION::LookupOK then;
                end;
            }
            action(EditPaymentMethod)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
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
                        if BCO365PaymentMethodCard.RunModal() = ACTION::LookupOK then;
                    end;
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

                actionref(_NEW_TEMP__Promoted; _NEW_TEMP_)
                {
                }
                actionref(EditPaymentMethod_Promoted; EditPaymentMethod)
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshRecords();

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        RefreshRecords();
    end;
}
#endif
