#if not CLEAN21
page 2328 "BC O365 Email Settings Part"
{
    Caption = ' ';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "O365 Email Setup";
    SourceTableView = SORTING(Email)
                      ORDER(Ascending);
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Email)
                {
                    ApplicationArea = Invoicing, Basic, Suite;

                    trigger OnValidate()
                    begin
                        if (Email = '') and (xRec.Email <> '') then
                            CurrPage.Update(false);
                    end;
                }
                field(RecipientType; RecipientType)
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
        RecipientType := RecipientType::CC;
    end;

    var
        EditDefaultEmailMessageLbl: Label 'Change default email messages';
}
#endif
