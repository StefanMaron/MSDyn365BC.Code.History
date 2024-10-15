#if not CLEAN21
page 2346 "BC O365 VAT Posting Setup List"
{
    Caption = ' ';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "VAT Product Posting Group";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(LongDescription; LongDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"O365 VAT Posting Setup Card", Rec);
                    DefaultVATProductPostingGroupCode := O365TemplateManagement.GetDefaultVATProdPostingGroup();
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Code = DefaultVATProductPostingGroupCode then
            LongDescription := StrSubstNo(DefaultVATRateTxt, Rec.Description)
        else
            LongDescription := Rec.Description;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        DefaultVATProductPostingGroupCode := O365TemplateManagement.GetDefaultVATProdPostingGroup();
        Rec.SetCurrentKey(Code);
        exit(Rec.Find(Which));
    end;

    var
        O365TemplateManagement: Codeunit "O365 Template Management";
        DefaultVATProductPostingGroupCode: Code[20];
        DefaultVATRateTxt: Label '%1 (Default)', Comment = '%1 = a VAT rate name, such as "Reduced VAT"';
        LongDescription: Text;
}
#endif
