#if not CLEAN21
page 2171 "O365 Default Quote Email Msg"
{
    Caption = 'Default message for estimates';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "O365 Default Email Message";
    SourceTableView = sorting("Document Type")
                      where("Document Type" = filter(Quote));
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(DefaultQuoteMessage; EmailMessage)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Email message';
                MultiLine = true;
                ToolTip = 'Specifies your default email message when sending an estimate.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        EmailMessage := Rec.GetMessage(Rec."Document Type"::Quote);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;

        Rec."Document Type" := Rec."Document Type"::Quote;
        Rec.SetMessage(EmailMessage);
    end;

    var
        EmailMessage: Text;
}
#endif
