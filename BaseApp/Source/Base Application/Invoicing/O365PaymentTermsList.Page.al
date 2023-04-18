#if not CLEAN21
page 2153 "O365 Payment Terms List"
{
    Caption = 'Payment Terms';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "O365 Payment Terms";
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
                    ToolTip = 'Specifies the short name of the payment term';
                }
                field(Days; Days)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Days';
                    ToolTip = 'Specifies the number of days until payments are due when this payment term is used.';
                }
                field(DummyText; DummyText)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the payment term.';
                    Visible = false;
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                RunPageMode = Create;
                ToolTip = 'Create new payment term';

                trigger OnAction()
                begin
                    if PAGE.RunModal(PAGE::"BC O365 Payment Terms Card") = ACTION::LookupOK then;
                end;
            }
            action(EditPaymentTerms)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
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
                        if BCO365PaymentTermsCard.RunModal() = ACTION::LookupOK then;
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
                actionref(EditPaymentTerms_Promoted; EditPaymentTerms)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Days := CalcDate("Due Date Calculation", Today) - Today;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshRecords();

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
#endif
