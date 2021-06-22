page 2153 "O365 Payment Terms List"
{
    Caption = 'Payment Terms';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "O365 Payment Terms";
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
                    ToolTip = 'Specifies the short name of the payment term';
                }
                field(Days; Days)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Days';
                    ToolTip = 'Specifies the number of days until payments are due when this payment term is used.';
                }
                field(DummyText; DummyText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    ShowCaption = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the payment term.';
                    Visible = false;
                }
                field("Due Date Calculation"; "Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(creation)
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
                ToolTip = 'Create new payment term';

                trigger OnAction()
                begin
                    if PAGE.RunModal(PAGE::"BC O365 Payment Terms Card") = ACTION::LookupOK then;
                end;
            }
            action(EditPaymentTerms)
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
                    PaymentTerms: Record "Payment Terms";
                    BCO365PaymentTermsCard: Page "BC O365 Payment Terms Card";
                begin
                    if PaymentTerms.Get(Code) then begin
                        BCO365PaymentTermsCard.SetPaymentTerms(PaymentTerms);
                        BCO365PaymentTermsCard.LookupMode(true);
                        if BCO365PaymentTermsCard.RunModal = ACTION::LookupOK then;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Days := CalcDate("Due Date Calculation", Today) - Today;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshRecords;

        exit(Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Days);
    end;

    var
        Days: Integer;
        DummyText: Code[10];
}

