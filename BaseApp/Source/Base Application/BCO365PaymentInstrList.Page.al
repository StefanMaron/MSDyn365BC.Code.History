page 2342 "BC O365 Payment Instr. List"
{
    Caption = 'Payment Instructions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    ShowFilter = false;
    SourceTable = "O365 Payment Instructions";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(NameText; NameText)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Short name';
                    Width = 10;
                }
                field(GetPaymentInstructionsInCurrentLanguage; GetPaymentInstructionsInCurrentLanguage)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Payment instructions';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(_NEW_TEMP_)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'New';
                Image = New;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create new payment instructions for your customers.';

                trigger OnAction()
                begin
                    if O365SalesInvoiceMgmt.OpenNewPaymentInstructionsCard and CurrPage.LookupMode then
                        CurrPage.Close;
                end;
            }
            action(Edit)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Open these payment instructions in an editable way.';

                trigger OnAction()
                var
                    BCO365PaymentInstrCard: Page "BC O365 Payment Instr. Card";
                    OldDefaultState: Boolean;
                begin
                    OldDefaultState := Default;
                    BCO365PaymentInstrCard.SetPaymentInstructionsOnPage(Rec);
                    BCO365PaymentInstrCard.LookupMode(true);
                    if BCO365PaymentInstrCard.RunModal = ACTION::OK then;

                    // Check if the default was changed, if we are in lookup mode close the page
                    Find;
                    if CurrPage.LookupMode and (Default <> OldDefaultState) then
                        CurrPage.Close;
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Delete these payment instructions.';

                trigger OnAction()
                begin
                    if Find then
                        Delete(true);
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
}

