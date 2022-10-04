#if not CLEAN21
page 2127 "O365 Email BCC Listpart"
{
    Caption = 'BCC';
    CardPageID = "O365 Email CC/BCC Card";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "O365 Email Setup";
    SourceTableView = WHERE(RecipientType = CONST(BCC));
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
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the BCC recipient address on all new invoices';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteLine)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete Line';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete(true);
                    CurrPage.Update();
                end;
            }
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                RunObject = Page "O365 Email CC/BCC Card";
                RunPageOnRec = true;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        RecipientType := RecipientType::BCC;
    end;

    var
        DeleteQst: Label 'Are you sure?';
}
#endif
