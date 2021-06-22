page 2132 "O365 Invoice Send Settings"
{
    Caption = 'Invoice Send Options';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the invoice send setting.';
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
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenPage;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        GraphMail: Codeunit "Graph Mail";
        O365SetupEmail: Codeunit "O365 Setup Email";
    begin
        if Title = EmailAccountTitleTxt then begin
            if (O365SetupEmail.SMTPEmailIsSetUp and (not GraphMail.IsEnabled)) or (not GraphMail.HasConfiguration) then
                "Page ID" := PAGE::"O365 Email Account Settings"
            else
                "Page ID" := PAGE::"Graph Mail Setup";

            Description := GetEmailAccountDescription;
        end;
    end;

    trigger OnOpenPage()
    begin
        InsertMenuItems;
    end;

    var
        EmailAccountTitleTxt: Label 'Email account';
        EmailAccountDescriptionTxt: Label 'Set up your email account.';
        CCAndBCCTitleTxt: Label 'CC and BCC';
        CCAndBCCDescriptionTxt: Label 'Add CC and BCC recipients on all new invoices.';
        InvoiceEmailMessageTxt: Label 'Default message for invoices';
        InvoiceEmailMessageDescriptionTxt: Label 'Change your default email message for invoices';
        QuoteEmailMessageTxt: Label 'Default message for estimates';
        QuoteEmailMessageDescriptionTxt: Label 'Change your default email message for estimates';

    local procedure InsertMenuItems()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMail: Codeunit "Graph Mail";
    begin
        if (O365SetupEmail.SMTPEmailIsSetUp and (not GraphMail.IsEnabled)) or (not GraphMail.HasConfiguration) then
            InsertPageMenuItem(PAGE::"O365 Email Account Settings", EmailAccountTitleTxt, GetEmailAccountDescription)
        else
            InsertPageMenuItem(PAGE::"Graph Mail Setup", EmailAccountTitleTxt, GetEmailAccountDescription);

        InsertPageMenuItem(PAGE::"O365 Email CC and BCC Settings", CCAndBCCTitleTxt, CCAndBCCDescriptionTxt);
        InsertPageMenuItem(PAGE::"O365 Default Invoice Email Msg", InvoiceEmailMessageTxt, InvoiceEmailMessageDescriptionTxt);
        InsertPageMenuItem(PAGE::"O365 Default Quote Email Msg", QuoteEmailMessageTxt, QuoteEmailMessageDescriptionTxt);
    end;

    local procedure GetEmailAccountDescription(): Text[80]
    var
        GraphMailSetup: Record "Graph Mail Setup";
        SMTPMailSetup: Record "SMTP Mail Setup";
        O365SetupEmail: Codeunit "O365 Setup Email";
        GraphMail: Codeunit "Graph Mail";
    begin
        if GraphMail.IsEnabled and GraphMail.HasConfiguration then
            if GraphMailSetup.Get then
                if GraphMailSetup."Sender Email" <> '' then
                    exit(CopyStr(GraphMailSetup."Sender Email", 1, MaxStrLen(Description)));

        if O365SetupEmail.SMTPEmailIsSetUp then
            if SMTPMailSetup.GetSetup then
                if SMTPMailSetup."User ID" <> '' then
                    exit(CopyStr(SMTPMailSetup."User ID", 1, MaxStrLen(Description)));

        exit(EmailAccountDescriptionTxt);
    end;
}

