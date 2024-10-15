page 10351 "BC O365 Tax Settings List"
{
    Caption = 'Tax Rates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Tax Area";

    layout
    {
        area(content)
        {
            repeater(Control1020001)
            {
                ShowCaption = false;
                field(TaxAreaDescription; TaxAreaDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Tax rate';
                    Editable = false;
                    ToolTip = 'Specifies the tax rate used to calculate tax on what you buy or sell.';
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
                ToolTip = 'Create a new tax rate.';
                Visible = NOT IsCanada;

                trigger OnAction()
                var
                    TempTaxArea: Record "Tax Area" temporary;
                begin
                    TempTaxArea.Insert();
                    PAGE.RunModal(PAGE::"BC O365 Tax Settings Card", TempTaxArea);
                    CurrPage.Update();
                end;
            }
            action(Edit)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Edit';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                var
                    TempTaxArea: Record "Tax Area" temporary;
                begin
                    TempTaxArea := Rec;
                    TempTaxArea.Insert();
                    PAGE.RunModal(PAGE::"BC O365 Tax Settings Card", TempTaxArea);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Code = O365TaxSettingsManagement.GetDefaultTaxArea then
            TaxAreaDescription := StrSubstNo(DefaultTaxDescriptionTxt, GetDescriptionInCurrentLanguage)
        else
            TaxAreaDescription := GetDescriptionInCurrentLanguage;
    end;

    trigger OnInit()
    var
        CompanyInformation: Record "Company Information";
    begin
        IsCanada := CompanyInformation.IsCanada;
    end;

    var
        O365TaxSettingsManagement: Codeunit "O365 Tax Settings Management";
        IsCanada: Boolean;
        DefaultTaxDescriptionTxt: Label '%1 (Default)', Comment = '%1 = a VAT rate name, such as "Reduced VAT"';
        TaxAreaDescription: Text;
}

