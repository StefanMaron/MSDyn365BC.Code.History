#if not CLEAN21
page 2170 "O365 Default Invoice Email Msg"
{
    Caption = 'Default message for invoice';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    Permissions =;
    SourceTable = "O365 Default Email Message";
    SourceTableView = sorting("Document Type")
                      where("Document Type" = filter(Invoice));
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(DefaultEmailMessage; EmailMessage)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Email message';
                MultiLine = true;
                ToolTip = 'Specifies your default email message when sending an invoice.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        EmailMessage := Rec.GetMessage(Rec."Document Type"::Invoice);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;

        Rec."Document Type" := Rec."Document Type"::Invoice;
        Rec.SetMessage(EmailMessage);
    end;

    var
        EmailMessage: Text;
}
#endif
