page 2170 "O365 Default Invoice Email Msg"
{
    Caption = 'Default message for invoice';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    Permissions =;
    SourceTable = "O365 Default Email Message";
    SourceTableView = SORTING("Document Type")
                      WHERE("Document Type" = FILTER(Invoice));

    layout
    {
        area(content)
        {
            field(DefaultEmailMessage; EmailMessage)
            {
                ApplicationArea = Basic, Suite, Invoicing;
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
        EmailMessage := GetMessage("Document Type"::Invoice);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;

        "Document Type" := "Document Type"::Invoice;
        SetMessage(EmailMessage);
    end;

    var
        EmailMessage: Text;
}

