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

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Email; Email)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
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
                ApplicationArea = Basic, Suite, Invoicing;
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
                    CurrPage.Update;
                end;
            }
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
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

