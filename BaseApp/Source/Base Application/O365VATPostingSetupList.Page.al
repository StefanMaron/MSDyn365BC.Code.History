page 2146 "O365 VAT Posting Setup List"
{
    Caption = 'VAT Rates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "VAT Product Posting Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = false;
                    StyleExpr = StyleExpr;
                    ToolTip = 'Specifies the VAT rate used to calculate VAT on what you buy or sell.';
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
                Visible = false;

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"O365 VAT Posting Setup Card", Rec);
                    DefaultVATProductPostingGroupCode := O365TemplateManagement.GetDefaultVATProdPostingGroup;
                    CurrPage.Update;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Code = DefaultVATProductPostingGroupCode then
            StyleExpr := 'Strong'
        else
            StyleExpr := 'Standard';
    end;

    trigger OnOpenPage()
    begin
        DefaultVATProductPostingGroupCode := O365TemplateManagement.GetDefaultVATProdPostingGroup;
    end;

    var
        O365TemplateManagement: Codeunit "O365 Template Management";
        StyleExpr: Text;
        DefaultVATProductPostingGroupCode: Code[20];
}

