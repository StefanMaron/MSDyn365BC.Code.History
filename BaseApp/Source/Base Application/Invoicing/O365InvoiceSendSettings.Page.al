#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenPage();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Title = EmailAccountTitleTxt then begin
            "Page ID" := PAGE::"Graph Mail Setup";
            Description := GetEmailAccountDescription();
        end;
    end;

    trigger OnOpenPage()
    begin
        InsertMenuItems();
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
    begin
        InsertPageMenuItem(PAGE::"Graph Mail Setup", EmailAccountTitleTxt, GetEmailAccountDescription());
        InsertPageMenuItem(PAGE::"O365 Email CC and BCC Settings", CCAndBCCTitleTxt, CCAndBCCDescriptionTxt);
        InsertPageMenuItem(PAGE::"O365 Default Invoice Email Msg", InvoiceEmailMessageTxt, InvoiceEmailMessageDescriptionTxt);
        InsertPageMenuItem(PAGE::"O365 Default Quote Email Msg", QuoteEmailMessageTxt, QuoteEmailMessageDescriptionTxt);
    end;

    local procedure GetEmailAccountDescription(): Text[80]
    var
        EmailAccount: Record "Email Account";
        GraphMailSetup: Record "Graph Mail Setup";
        EmailScenario: Codeunit "Email Scenario";
        GraphMail: Codeunit "Graph Mail";
    begin
        if EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, EmailAccount) then
            exit(CopyStr(EmailAccount."Email Address", 1, MaxStrLen(Description)));

        if GraphMail.IsEnabled() and GraphMail.HasConfiguration() then
            if GraphMailSetup.Get() then
                if GraphMailSetup."Sender Email" <> '' then
                    exit(CopyStr(GraphMailSetup."Sender Email", 1, MaxStrLen(Description)));

        exit(EmailAccountDescriptionTxt);
    end;
}
#endif
