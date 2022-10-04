#if not CLEAN21
page 2398 "BC O365 Graph Mail Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = CardPart;
    SourceTable = "Graph Mail Setup";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Your invoices will be sent from the following email account.';
                ShowCaption = false;
            }
            field("Sender Name"; Rec."Sender Name")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field("Sender Email"; Rec."Sender Email")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            field(ModifyMailLbl; ModifyMailLbl)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
    begin
        if not IsEnabled() then
            if GraphMail.HasConfiguration() then
                Initialize(false);
    end;

    trigger OnOpenPage()
    begin
        if not Get() then
            Insert(true);
    end;

    var
        ModifyMailLbl: Label 'Change account settings';
}
#endif
