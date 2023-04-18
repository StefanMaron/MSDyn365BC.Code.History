#if not CLEAN21
page 2171 "O365 Default Quote Email Msg"
{
    Caption = 'Default message for estimates';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "O365 Default Email Message";
    SourceTableView = SORTING("Document Type")
                      WHERE("Document Type" = FILTER(Quote));
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
        EmailMessage := GetMessage("Document Type"::Quote);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;

        "Document Type" := "Document Type"::Quote;
        SetMessage(EmailMessage);
    end;

    var
        EmailMessage: Text;
}
#endif
