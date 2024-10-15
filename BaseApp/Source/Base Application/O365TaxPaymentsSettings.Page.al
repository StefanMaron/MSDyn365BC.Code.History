#if not CLEAN21
page 2133 "O365 Tax Payments Settings"
{
    Caption = 'Tax & Payments';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
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
                field(Description; Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies a description of the tax payment setting.';
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

    trigger OnOpenPage()
    begin
        InsertMenuItems();
    end;

    var
        TaxTitleLbl: Label 'Tax';
        TaxDescriptionLbl: Label 'Set up your tax information.';
        PaymentTitleLbl: Label 'Payments';
        PaymentnDescriptionLbl: Label 'Set up your payment method and terms.';
        VATProdPostingGroupLbl: Label 'VAT Rates';
        VATProdPostingGroupDescriptionLbl: Label 'Set up the VAT rate and description.';
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";

    local procedure InsertMenuItems()
    begin
        InsertPageMenuItem(PAGE::"O365 Tax Settings List", TaxTitleLbl, TaxDescriptionLbl);
        InsertPageMenuItem(PAGE::"O365 Payments Settings", PaymentTitleLbl, PaymentnDescriptionLbl);
        if O365SalesInitialSetup.IsUsingVAT() then
            InsertPageMenuItem(PAGE::"O365 VAT Posting Setup List", VATProdPostingGroupLbl, VATProdPostingGroupDescriptionLbl);
    end;
}
#endif
