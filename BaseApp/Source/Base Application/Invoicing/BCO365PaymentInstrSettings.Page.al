#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Short name';
                    Width = 2;
                }
                field(GetPaymentInstructionsInCurrentLanguage; Rec.GetPaymentInstructionsInCurrentLanguage())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Payment instructions';
                }
                field(DeleteLineControl; DeleteLbl)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Enabled = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        if Confirm(DeleteConfirmQst) then
                            if Rec.Find() then
                                Rec.Delete(true);
                    end;
                }
            }
            field(AddNewPaymentInstructions; NewPaymentInstructionsLbl)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = TRUE;

                trigger OnDrillDown()
                begin
                    O365SalesInvoiceMgmt.OpenNewPaymentInstructionsCard();
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                    if BCO365PaymentInstrCard.RunModal() = ACTION::OK then;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Default then
            NameText := StrSubstNo(DefaultTxt, Rec.GetNameInCurrentLanguage())
        else
            NameText := Rec.GetNameInCurrentLanguage();
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        NameText: Text;
        DefaultTxt: Label '%1 (default)', Comment = '%1: the description of the payment instructions';
        NewPaymentInstructionsLbl: Label 'Add new payment instructions';
        DeleteLbl: Label 'Delete';
        DeleteConfirmQst: Label 'Do you want to delete the payment instructions?';
}
#endif
