#if not CLEAN21
page 2328 "BC O365 Email Settings Part"
{
    Caption = ' ';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "O365 Email Setup";
    SourceTableView = sorting(Email)
                      order(Ascending);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Rec.Email)
                {
                    ApplicationArea = Invoicing, Basic, Suite;

                    trigger OnValidate()
                    begin
                        if (Rec.Email = '') and (xRec.Email <> '') then
                            CurrPage.Update(false);
                    end;
                }
                field(RecipientType; Rec.RecipientType)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'CC/BCC';
                }
            }
            field(EditDefaultMessages; EditDefaultEmailMessageLbl)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = TRUE;

                trigger OnDrillDown()
                begin
                    PAGE.RunModal(PAGE::"BC O365 Default Email Messages");
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.RecipientType := Rec.RecipientType::CC;
    end;

    var
        EditDefaultEmailMessageLbl: Label 'Change default email messages';
}
#endif
