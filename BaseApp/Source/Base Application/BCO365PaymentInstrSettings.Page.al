page 2344 "BC O365 Payment Instr Settings"
{
    Caption = ' ';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "O365 Payment Instructions";

    layout
    {
        area(content)
        {
            group(Control12)
            {
                InstructionalText = 'The payment instructions will show up on the bottom of your invoices. You can edit the existing ones or create a new one.';
                ShowCaption = false;
            }
            repeater(Group)
            {
                field(NameText; NameText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Short name';
                    Width = 2;
                }
                field(GetPaymentInstructionsInCurrentLanguage; GetPaymentInstructionsInCurrentLanguage)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment instructions';
                }
                field(DeleteLineControl; DeleteLbl)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        if Confirm(DeleteConfirmQst) then
                            if Find then
                                Delete(true);
                    end;
                }
            }
            field(AddNewPaymentInstructions; NewPaymentInstructionsLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = TRUE;

                trigger OnDrillDown()
                begin
                    O365SalesInvoiceMgmt.OpenNewPaymentInstructionsCard;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Category4;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open these payment instructions in an editable way.';
                Visible = false;

                trigger OnAction()
                var
                    BCO365PaymentInstrCard: Page "BC O365 Payment Instr. Card";
                begin
                    BCO365PaymentInstrCard.SetPaymentInstructionsOnPage(Rec);
                    BCO365PaymentInstrCard.LookupMode(true);
                    if BCO365PaymentInstrCard.RunModal = ACTION::OK then;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Default then
            NameText := StrSubstNo(DefaultTxt, GetNameInCurrentLanguage)
        else
            NameText := GetNameInCurrentLanguage;
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        NameText: Text;
        DefaultTxt: Label '%1 (default)', Comment = '%1: the description of the payment instructions';
        NewPaymentInstructionsLbl: Label 'Add new payment instructions';
        DeleteLbl: Label 'Delete';
        DeleteConfirmQst: Label 'Do you want to delete the payment instructions?';
}

