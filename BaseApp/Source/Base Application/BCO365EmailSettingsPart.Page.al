page 2328 "BC O365 Email Settings Part"
{
    Caption = ' ';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "O365 Email Setup";
    SourceTableView = SORTING(Email)
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Email)
                {
                    ApplicationArea = Basic, Suite, Invoicing;

                    trigger OnValidate()
                    begin
                        if (Email = '') and (xRec.Email <> '') then
                            CurrPage.Update(false);
                    end;
                }
                field(RecipientType; RecipientType)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'CC/BCC';
                }
            }
            field(EditDefaultMessages; EditDefaultEmailMessageLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
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

