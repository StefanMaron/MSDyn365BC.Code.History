page 1342 "Item Template Card"
{
    Caption = 'Item Template';
    CardPageID = "Item Template Card";
    DataCaptionExpression = "Template Name";
    PageType = Card;
    PromotedActionCategories = 'New,Process,Reports,Master Data';
    SourceTable = "Item Template";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality will be replaced by other templates.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Template Name"; "Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the template.';

                    trigger OnValidate()
                    begin
                        SetDimensionsEnabled;
                    end;
                }
                field(TemplateEnabled; TemplateEnabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies if the template is ready to be used';

                    trigger OnValidate()
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                    begin
                        if ConfigTemplateHeader.Get(Code) then
                            ConfigTemplateHeader.SetTemplateEnabled(TemplateEnabled);
                    end;
                }
                field(NoSeries; NoSeries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. Series';
                    TableRelation = "No. Series";
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to items.';

                    trigger OnValidate()
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                    begin
                        if ConfigTemplateHeader.Get(Code) then
                            ConfigTemplateHeader.SetNoSeries(NoSeries);
                    end;
                }
            }
            group("Item Setup")
            {
                Caption = 'Item Setup';
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item card represents a physical item (Inventory) or a service (Service).';

                    trigger OnValidate()
                    begin
                        SetInventoryPostingGroupEditable;
                    end;
                }
                field("Automatic Ext. Texts"; "Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that an extended text will be added on sales or purchase documents for this item.';
                }
            }
            group(Price)
            {
                Caption = 'Price';
                field("Price Includes VAT"; "Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on sales document lines for this item should be shown with or without VAT.';
                }
                field("Price/Profit Calculation"; "Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this item.';
                }
                field("Profit %"; "Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item should be included in the calculation of an invoice discount on documents where the item is traded.';
                }
                field("Item Disc. Group"; "Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an item group code that can be used as a criterion to grant a discount when the item is sold to a certain customer.';
                }
            }
            group(Cost)
            {
                Caption = 'Cost';
                field("Costing Method"; "Costing Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies links between business transactions made for this item and the general ledger, to account for VAT amounts that result from trade with the item.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                }
            }
            group("Financial Details")
            {
                Caption = 'Financial Details';
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
                }
                field("Inventory Posting Group"; "Inventory Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = InventoryPostingGroupEditable;
                    ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax group code for the tax-detail entry.';
                }
            }
            group(Categorization)
            {
                Caption = 'Categorization';
                field("Item Category Code"; "Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category that the item belongs to. Item categories also contain any assigned item attributes.';
                }
                field("Service Item Group"; "Service Item Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group that the item belongs to.';
                }
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code for the item.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Master Data")
            {
                Caption = 'Master Data';
                action("Default Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = DimensionsEnabled;
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Dimensions Template List";
                    RunPageLink = "Table Id" = CONST(27),
                                  "Master Record Template Code" = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetInventoryPostingGroupEditable;
        SetDimensionsEnabled;
        SetTemplateEnabled;
        SetCostingMethodDefault;
        SetNoSeries;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CheckTemplateNameProvided
    end;

    trigger OnOpenPage()
    begin
        if Item."No." <> '' then
            CreateConfigTemplateFromExistingItem(Item, Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        case CloseAction of
            ACTION::LookupOK:
                if Code <> '' then
                    CheckTemplateNameProvided;
            ACTION::LookupCancel:
                if Delete(true) then
                    ;
        end;
    end;

    var
        Item: Record Item;
        NoSeries: Code[20];
        [InDataSet]
        InventoryPostingGroupEditable: Boolean;
        [InDataSet]
        DimensionsEnabled: Boolean;
        ProvideTemplateNameErr: Label 'You must enter a %1.', Comment = '%1 Template Name';
        TemplateEnabled: Boolean;

    procedure SetInventoryPostingGroupEditable()
    begin
        InventoryPostingGroupEditable := Type = Type::Inventory;
    end;

    local procedure SetDimensionsEnabled()
    begin
        DimensionsEnabled := "Template Name" <> '';
    end;

    local procedure SetTemplateEnabled()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        TemplateEnabled := ConfigTemplateHeader.Get(Code) and ConfigTemplateHeader.Enabled;
    end;

    local procedure CheckTemplateNameProvided()
    begin
        if "Template Name" = '' then
            Error(ProvideTemplateNameErr, FieldCaption("Template Name"));
    end;

    procedure CreateFromItem(FromItem: Record Item)
    begin
        Item := FromItem;
    end;

    local procedure SetCostingMethodDefault()
    var
        ConfigTemplateLine: Record "Config. Template Line";
        InventorySetup: Record "Inventory Setup";
    begin
        if Item."No." <> '' then
            exit;

        ConfigTemplateLine.SetRange("Data Template Code", Code);
        ConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateLine.SetRange("Field ID", Item.FieldNo("Costing Method"));
        if ConfigTemplateLine.IsEmpty and InventorySetup.Get then
            "Costing Method" := InventorySetup."Default Costing Method";
    end;

    local procedure SetNoSeries()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        NoSeries := '';
        if ConfigTemplateHeader.Get(Code) then
            NoSeries := ConfigTemplateHeader."Instance No. Series";
    end;
}

