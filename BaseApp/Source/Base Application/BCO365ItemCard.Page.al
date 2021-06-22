page 2317 "BC O365 Item Card"
{
    Caption = 'Price';
    DataCaptionExpression = Description;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Item)
            {
                Caption = 'Product/Service';
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Importance = Promoted;
                    ToolTip = 'Specifies what you are selling.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price';
                    Importance = Promoted;
                    ToolTip = 'Specifies the price for one unit.';
                }
                field(UnitOfMeasureDescription; UnitOfMeasureDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price per';
                    Editable = false;
                    QuickEntry = false;
                    ToolTip = 'Specifies the price for one unit.';

                    trigger OnAssistEdit()
                    var
                        TempUnitOfMeasure: Record "Unit of Measure" temporary;
                        O365UnitsOfMeasureList: Page "O365 Units of Measure List";
                    begin
                        TempUnitOfMeasure.CreateListInCurrentLanguage(TempUnitOfMeasure);
                        if TempUnitOfMeasure.Get("Base Unit of Measure") then;

                        O365UnitsOfMeasureList.SetRecord(TempUnitOfMeasure);
                        O365UnitsOfMeasureList.LookupMode(true);
                        if O365UnitsOfMeasureList.RunModal = ACTION::LookupOK then begin
                            O365UnitsOfMeasureList.GetRecord(TempUnitOfMeasure);
                            Validate("Base Unit of Measure", TempUnitOfMeasure.Code);
                            UnitOfMeasureDescription := TempUnitOfMeasure.Description;
                        end;

                        CurrPage.Update(true);
                    end;
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Tax Group';
                    Editable = IsPageEditable;
                    NotBlank = true;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                    Visible = NOT IsUsingVAT;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT';
                    Editable = false;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT rate for this price.';
                    Visible = IsUsingVAT;

                    trigger OnAssistEdit()
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
        area(factboxes)
        {
            part(ItemPicture; "Item Picture")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Picture';
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Variant Filter" = FIELD("Variant Filter");
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
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed and DocumentNoVisibility.ItemNoSeriesIsDefault then
            NewMode := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CanExitAfterProcessingItem);
    end;

    var
        ProcessNewItemOptionQst: Label 'Keep editing,Discard';
        ProcessNewItemInstructionTxt: Label 'Description is missing. Keep the price?';
        VATProductPostingGroupDescription: Text[100];
        NewMode: Boolean;
        IsUsingVAT: Boolean;
        IsPageEditable: Boolean;
        Created: Boolean;
        UnitOfMeasureDescription: Text[50];

    local procedure CanExitAfterProcessingItem(): Boolean
    var
        Response: Option ,KeepEditing,Discard;
    begin
        if "No." = '' then
            exit(true);

        if NewMode and (Description = '') then begin
            if Delete(true) then;
            exit(true);
        end;

        if GuiAllowed and (Description = '') then
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
        if NewMode and (not Created) then
            if ItemTemplate.NewItemFromTemplate(Item) then begin
                O365SalesManagement.SetItemDefaultValues(Item);
                Copy(Item);
                Created := true;
                CurrPage.Update(true);
            end;
    end;
}

