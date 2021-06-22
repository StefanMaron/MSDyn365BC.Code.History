page 2106 "O365 Item Card"
{
    Caption = 'Price';
    DataCaptionExpression = Description;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Item,History,Special Prices & Discounts,Approve,Request Approval,Details';
    RefreshOnActivate = true;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Item)
            {
                Caption = 'Price';
                field(Description2; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies what you are selling.';
                    Visible = NOT IsPhoneApp;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ShowCaption = false;
                    ToolTip = 'Specifies what you are selling.';
                    Visible = IsPhoneApp;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field(UnitOfMeasureDescription; UnitOfMeasureDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price is per';
                    Editable = IsPageEditable;
                    QuickEntry = false;
                    ToolTip = 'Specifies the price for one unit.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempUnitOfMeasure: Record "Unit of Measure" temporary;
                    begin
                        TempUnitOfMeasure.CreateListInCurrentLanguage(TempUnitOfMeasure);
                        if PAGE.RunModal(PAGE::"O365 Units of Measure List", TempUnitOfMeasure) = ACTION::LookupOK then begin
                            Validate("Base Unit of Measure", TempUnitOfMeasure.Code);
                            UnitOfMeasureDescription := TempUnitOfMeasure.Description;
                        end;
                    end;
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Tax Group';
                    NotBlank = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                    Visible = NOT IsUsingVAT;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT';
                    Editable = IsPageEditable;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT rate for this price.';
                    Visible = IsUsingVAT;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VATProductPostingGroup: Record "VAT Product Posting Group";
                    begin
                        if PAGE.RunModal(PAGE::"O365 VAT Product Posting Gr.", VATProductPostingGroup) = ACTION::LookupOK then begin
                            Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                            VATProductPostingGroupDescription := VATProductPostingGroup.Description;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateItemFromTemplate;
        if VATProductPostingGroup.Get("VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description;
        if UnitOfMeasure.Get("Base Unit of Measure") then
            UnitOfMeasureDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage;
        IsPageEditable := CurrPage.Editable;
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        IsPhoneApp := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Description = '' then
            ItemCardStatus := ItemCardStatus::Delete
        else
            ItemCardStatus := ItemCardStatus::Keep;

        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Description = '' then
            ItemCardStatus := ItemCardStatus::Prompt
        else
            ItemCardStatus := ItemCardStatus::Keep;

        exit(true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec;
    end;

    trigger OnOpenPage()
    begin
        if Description = '' then
            ItemCardStatus := ItemCardStatus::Delete
        else
            ItemCardStatus := ItemCardStatus::Keep;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CanExitAfterProcessingItem);
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ItemCardStatus: Option Keep,Delete,Prompt;
        ProcessNewItemOptionQst: Label 'Keep editing,Discard';
        ProcessNewItemInstructionTxt: Label 'Description is missing. Keep the price?';
        VATProductPostingGroupDescription: Text[100];
        NewMode: Boolean;
        IsUsingVAT: Boolean;
        IsPageEditable: Boolean;
        UnitOfMeasureDescription: Text[50];
        IsPhoneApp: Boolean;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed and DocumentNoVisibility.ItemNoSeriesIsDefault then
            NewMode := true;
    end;

    local procedure CanExitAfterProcessingItem(): Boolean
    var
        Response: Option ,KeepEditing,Discard;
    begin
        if "No." = '' then
            exit(true);

        if ItemCardStatus = ItemCardStatus::Delete then begin
            // workaround for bug: delete for new empty record returns false
            if Delete(true) then;
            exit(true);
        end;

        if GuiAllowed and (ItemCardStatus = ItemCardStatus::Prompt) then
            case StrMenu(ProcessNewItemOptionQst, Response::KeepEditing, ProcessNewItemInstructionTxt) of
                Response::Discard:
                    exit(Delete(true));
                else
                    exit(false);
            end;

        exit(true);
    end;

    local procedure CreateItemFromTemplate()
    var
        ItemTemplate: Record "Item Template";
        Item: Record Item;
        O365SalesManagement: Codeunit "O365 Sales Management";
    begin
        if NewMode then begin
            if ItemTemplate.NewItemFromTemplate(Item) then begin
                Copy(Item);
                O365SalesManagement.SetItemDefaultValues(Item);
                CurrPage.Update;
            end;
            ItemCardStatus := ItemCardStatus::Delete;
            NewMode := false;
        end;
    end;
}

