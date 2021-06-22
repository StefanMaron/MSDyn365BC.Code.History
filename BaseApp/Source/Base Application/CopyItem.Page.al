page 729 "Copy Item"
{
    Caption = 'Copy Item';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Copy Item Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(SourceItemNo; "Source Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Item No.';
                    Editable = false;
                    Lookup = true;
                    TableRelation = Item;
                    ToolTip = 'Specifies the number of the item that you want to copy the data from.';
                }
                field(TargetItemNo; "Target Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Target Item No.';
                    ToolTip = 'Specifies the number of the new item that you want to copy the data to. \\To generate the new item number from a number series, fill in the Target No. Series field instead.';

                    trigger OnValidate()
                    begin
                        if "Target Item No." <> '' then
                            "Target No. Series" := '';
                    end;
                }
                field(TargetNoSeries; "Target No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Target No. Series';
                    Editable = false;
                    ToolTip = 'Specifies the number series that is used to assign a number to the new item.';

                    trigger OnAssistEdit()
                    begin
                        InventorySetup.Get();
                        InventorySetup.TestField("Item Nos.");
                        NoSeriesMgt.SelectSeries(InventorySetup."Item Nos.", SourceItem."No. Series", "Target No. Series");
                        "Target Item No." := '';
                    end;
                }
                field(NumberOfCopies; "Number of Copies")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of Copies';
                    MinValue = 1;
                    ToolTip = 'Specifies the number of new items that you want to create.';
                }
            }
            group(General)
            {
                Caption = 'General';
                field(GeneralItemInformation; "General Item Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Item Information';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(UnitsOfMeasure; "Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Units of measure';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(Dimensions; Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(Picture; Picture)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Picture';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(Comments; Comments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comments';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                field(SalesPrices; "Sales Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(SalesLineDisc; "Sales Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Disc.';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                field(PurchasePrices; "Purchase Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(PurchaseLineDisc; "Purchase Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Line Disc.';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field(Troubleshooting; Troubleshooting)
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(ResourceSkills; "Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
            }
            group(Extended)
            {
                Caption = 'Extended';
                field(ItemVariants; "Item Variants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Variants';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(Translations; Translations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(ExtendedTexts; "Extended Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extended Texts';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(BOMComponents; "BOM Components")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    Caption = 'BOM Components';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(ItemVendors; "Item Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Vendors';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(Attributes; Attributes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attributes';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
                field(ItemCrossReferences; "Item Cross References")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Cross References';
                    ToolTip = 'Specifies if the selected data type if also copied to the new item.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        InitCopyItemBuffer();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateUserInput;
    end;

    var
        SourceItem: Record Item;
        TempItem: Record Item temporary;
        InventorySetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        SpecifyTargetItemNoErr: Label 'You must specify the target item number.';
        TargetItemDoesNotExistErr: Label 'Target item number %1 already exists.', Comment = '%1 - item number.';
        TargetItemNoTxt: Label 'Target Item No.';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';

    procedure GetParameters(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
        CopyItemBuffer := Rec;
    end;

    local procedure InitCopyItemBuffer()
    begin
        Init;
        "Number of Copies" := 1;
        "Source Item No." := TempItem."No.";
        InventorySetup.Get();
        "Target No. Series" := InventorySetup."Item Nos.";
        Insert;

        OnAfterInitCopyItemBuffer(Rec);
    end;

    local procedure ValidateUserInput()
    var
        Item: Record Item;
    begin
        CheckTargetItemNo;

        if ("Target Item No." = '') and ("Target No. Series" = '') then
            Error(SpecifyTargetItemNoErr);

        OnAfterValidateUserInput(Rec);
    end;

    procedure SetItem(var Item2: Record Item)
    begin
        TempItem := Item2;
    end;

    local procedure CheckTargetItemNo()
    begin
        if ("Number of Copies" > 1) and ("Target Item No." <> '') then
            if INCSTR("Target Item No.") = '' then
                Error(StrSubstNo(UnincrementableStringErr, TargetItemNoTxt));
    end;

    local procedure CheckExistingItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            Error(TargetItemDoesNotExistErr, ItemNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCopyItemBuffer(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateUserInput(var CopyItemBuffer: Record "Copy Item Buffer")
    begin
    end;
}