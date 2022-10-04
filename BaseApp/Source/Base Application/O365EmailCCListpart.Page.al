#if not CLEAN21
page 2126 "O365 Email CC Listpart"
{
    Caption = 'CC';
    CardPageID = "O365 Email CC/BCC Card";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "O365 Email Setup";
    SourceTableView = WHERE(RecipientType = CONST(CC));
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
                    ToolTip = 'Specifies the CC recipient address on all new invoices';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
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
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        RecipientType := RecipientType::CC;
    end;

    var
        DeleteQst: Label 'Are you sure?';
}
#endif
