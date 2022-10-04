#if not CLEAN21
page 2342 "BC O365 Payment Instr. List"
{
    Caption = 'Payment Instructions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "O365 Payment Instructions";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(NameText; NameText)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Short name';
                    Width = 10;
                }
                field(GetPaymentInstructionsInCurrentLanguage; GetPaymentInstructionsInCurrentLanguage())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'New';
                Image = New;
                ToolTip = 'Create new payment instructions for your customers.';

                trigger OnAction()
                begin
                    if O365SalesInvoiceMgmt.OpenNewPaymentInstructionsCard() and CurrPage.LookupMode then
                        CurrPage.Close();
                end;
            }
            action(Edit)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
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
                    if BCO365PaymentInstrCard.RunModal() = ACTION::OK then;

                    // Check if the default was changed, if we are in lookup mode close the page
                    Find();
                    if CurrPage.LookupMode and (Default <> OldDefaultState) then
                        CurrPage.Close();
                end;
            }
            action(Delete)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                Scope = Repeater;
                ToolTip = 'Delete these payment instructions.';

                trigger OnAction()
                begin
                    if Find() then
                        Delete(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(_NEW_TEMP__Promoted; _NEW_TEMP_)
                {
                }
                actionref(Edit_Promoted; Edit)
                {
                }
                actionref(Delete_Promoted; Delete)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Default then
            NameText := StrSubstNo(DefaultTxt, GetNameInCurrentLanguage())
        else
            NameText := GetNameInCurrentLanguage();
    end;

    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        NameText: Text;
        DefaultTxt: Label '%1 (default)', Comment = '%1: the description of the payment instructions';
}
#endif
