#if not CLEAN21
page 2145 "O365 VAT Posting Setup Card"
{
    Caption = 'VAT Rate';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Product Posting Group";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field(Description; Rec.Description)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                NotBlank = true;
            }
            field("VAT Percentage"; VATPercentage)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'VAT Percentage';
                MinValue = 0;
                ToolTip = 'Specifies the relevant VAT rate as a percentage (%). For example, if the VAT rate is 25%, enter 25 in this field.';
            }
            field("VAT Regulation Reference"; VATRegulationReference)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'VAT Regulation Reference';
                ToolTip = 'Specifies the VAT Regulation Reference for the VAT rate. VAT Regulation Reference describe the VAT that is being reported on a sales document, and are displayed on printed documents alongside the VAT identifier and VAT rate.';
            }
            field(DefaultVATGroupTxt; DefaultVATGroupTxt)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Editable = false;
                Enabled = NOT DefaultGroup;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    O365TemplateManagement.SetDefaultVATProdPostingGroup(Code);
                    DefaultVATGroupTxt := DefaultGroupTxt;
                    DefaultGroup := true;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not VATPostingSetup.Get(O365TemplateManagement.GetDefaultVATBusinessPostingGroup(), Code) then
            exit;

        VATPercentage := VATPostingSetup."VAT %";
        DefaultGroup := Code = O365TemplateManagement.GetDefaultVATProdPostingGroup();

        // VAT Regulation Reference = Vat clause
        if not VATClause.Get(VATPostingSetup."VAT Clause Code") then begin
            VATClause.Init();
            VATClause.Code := Code;
            VATClause.Insert();
            VATPostingSetup.Validate("VAT Clause Code", Code);
            VATPostingSetup.Modify(true);
        end;
        VATRegulationReference := VATClause.Description;
        if DefaultGroup then
            DefaultVATGroupTxt := DefaultGroupTxt
        else
            DefaultVATGroupTxt := SetAsDefaultTxt;
    end;

    trigger OnClosePage()
    begin
        UpdateVATClause();
        UpdateVATPercentage();
    end;

    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        O365TemplateManagement: Codeunit "O365 Template Management";
        VATPercentage: Decimal;
        DefaultGroup: Boolean;
        VATRegulationReference: Text[250];
        DefaultVATGroupTxt: Text;
        DefaultGroupTxt: Label 'This is the default VAT Rate';
        SetAsDefaultTxt: Label 'Set as default VAT Rate';

    local procedure UpdateVATClause()
    begin
        if Description = VATRegulationReference then
            exit;

        VATClause.Validate(Description, VATRegulationReference);
        VATClause.Modify(true);
    end;

    local procedure UpdateVATPercentage()
    var
        SalesLine: Record "Sales Line";
    begin
        if VATPercentage = VATPostingSetup."VAT %" then
            exit;
        VATPostingSetup.Validate("VAT %", VATPercentage);
        VATPostingSetup.Modify(true);
        SalesLine.SetRange("VAT Prod. Posting Group", Code);
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("VAT Prod. Posting Group");
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    end;
}
#endif
