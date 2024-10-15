#if not CLEAN21
page 2106 "O365 Item Card"
{
    Caption = 'Price';
    DataCaptionExpression = Description;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Item;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Item)
            {
                Caption = 'Price';
                field(Description2; Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies what you are selling.';
                    Visible = NOT IsPhoneApp;
                }
                field(Description; Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies what you are selling.';
                    Visible = IsPhoneApp;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Price';
                    ToolTip = 'Specifies the price for one unit.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field(UnitOfMeasureDescription; UnitOfMeasureDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'Tax Group';
                    NotBlank = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                    Visible = NOT IsUsingVAT;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'History', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Special Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category7)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category8)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 7.';
            }
            group(Category_Category9)
            {
                Caption = 'Details', Comment = 'Generated from the PromotedActionCategories property index 8.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateItemFromTemplate();
        if VATProductPostingGroup.Get("VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description;
        if UnitOfMeasure.Get("Base Unit of Measure") then
            UnitOfMeasureDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage();
        IsPageEditable := CurrPage.Editable;
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
        IsPhoneApp := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
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
        OnNewRec();
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
        exit(CanExitAfterProcessingItem());
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
        if GuiAllowed and DocumentNoVisibility.ItemNoSeriesIsDefault() then
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
        Item: Record Item;
        O365SalesManagement: Codeunit "O365 Sales Management";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        if NewMode then begin
            if ItemTemplMgt.InsertItemFromTemplate(Item) then begin
                Copy(Item);
                O365SalesManagement.SetItemDefaultValues(Item);
                CurrPage.Update();
            end;
            ItemCardStatus := ItemCardStatus::Delete;
            NewMode := false;
        end;
    end;
}
#endif
