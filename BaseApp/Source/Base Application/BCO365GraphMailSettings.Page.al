page 2398 "BC O365 Graph Mail Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = CardPart;
    SourceTable = "Graph Mail Setup";

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Your invoices will be sent from the following email account.';
                ShowCaption = false;
            }
            field("Sender Name"; "Sender Name")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field("Sender Email"; "Sender Email")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field(ModifyMailLbl; ModifyMailLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    PAGE.RunModal(PAGE::"Graph Mail Setup");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        GraphMail: Codeunit "Graph Mail";
        O365SetupEmail: Codeunit "O365 Setup Email";
    begin
        if not IsEnabled then
            if not O365SetupEmail.SMTPEmailIsSetUp then
                if GraphMail.HasConfiguration then
                    Initialize(false);
    end;

    trigger OnOpenPage()
    begin
        if not Get then
            Insert(true);
    end;

    var
        ModifyMailLbl: Label 'Change account settings';
}

