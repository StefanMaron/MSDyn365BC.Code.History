page 7005 "Price List Line Review"
{
    Caption = 'Price List Lines';
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Price List Line";
    DataCaptionExpression = DataCaptionExpr;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    begin
                        EditPriceList();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the price list line is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    Caption = 'Applies-to Type';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideSourceControls;
                    ToolTip = 'Specifies the type of the source the price applies to.';
                }
                field("Source No."; Rec."Source No.")
                {
                    Caption = 'Applies-to No.';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideSourceControls;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    Caption = 'Product Type';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideProductControls;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    Caption = 'Product No.';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideProductControls;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the product.';
                    trigger OnValidate()
                    begin
                        SetEditable();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = IsDraft;
                    Visible = not HideProductControls;
                    ToolTip = 'Specifies the description of the product.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Visible = ItemAsset;
                    Editable = ItemAsset and IsDraft;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Visible = ResourceAsset;
                    Editable = ResourceAsset and IsDraft;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable and IsDraft;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    Editable = IsDraft;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable and IsDraft;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = AmountEditable and IsDraft;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and IsSalesPrice;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    ApplicationArea = All;
                    Editable = AmountEditable and IsDraft;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and IsSalesPrice;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost factor, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field(DirectUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    ApplicationArea = All;
                    Editable = AmountEditable and IsDraft;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and not IsSalesPrice;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = AmountEditable and IsDraft and ResourceAsset;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and not IsSalesPrice and ResourceAsset;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory and IsDraft;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and IsSalesPrice;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory and IsDraft;
                    Style = Subordinate;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field(PurchLineDiscountPct; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and not IsSalesPrice;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory and IsDraft;
                    Style = Subordinate;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible and IsSalesPrice;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory and IsDraft;
                    Style = Subordinate;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenPriceList)
            {
                ApplicationArea = All;
                Caption = 'Open Price List';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                Visible = LineExists;
                ToolTip = 'View or edit the price list.';

                trigger OnAction()
                begin
                    EditPriceList();
                end;
            }
            group(New)
            {
                Image = New;
                Caption = 'New';
                action(PriceLists)
                {
                    ApplicationArea = All;
                    Caption = 'New Price List';
                    Image = NewOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Review the existing price lists and create a new price list or add a line to the existing one.';

                    trigger OnAction()
                    begin
                        ShowPriceLists();
                    end;
                }
                action(JobPriceLists)
                {
                    ApplicationArea = Jobs;
                    Caption = 'New Job Price List';
                    Image = NewResource;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Review the existing price lists that apply to all jobs, to one job, or to a job task and create a new price list or add a line to the existing one.';

                    trigger OnAction()
                    begin
                        ShowJobPriceLists();
                    end;
                }
            }
            action(SalesPriceLists)
            {
                ApplicationArea = All;
                Caption = 'Sales Price Lists';
                Image = Sales;
                Promoted = true;
                PromotedCategory = Process;
                Visible = IsSalesPrice;
                ToolTip = 'View the list of all sales price lists.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Sales Price Lists");
                end;
            }
            action(SalesJobPriceLists)
            {
                ApplicationArea = All;
                Caption = 'Sales Job Price Lists';
                Image = Sales;
                Promoted = true;
                PromotedCategory = Process;
                Visible = IsSalesPrice;
                ToolTip = 'View the list of all sales job price lists.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Sales Job Price Lists");
                end;
            }
            action(PurchPriceLists)
            {
                ApplicationArea = All;
                Caption = 'Purchase Price Lists';
                Image = Purchase;
                Promoted = true;
                PromotedCategory = Process;
                Visible = not IsSalesPrice;
                ToolTip = 'View the list of all purchase price lists.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Purchase Price Lists");
                end;
            }
            action(PurchJobPriceLists)
            {
                ApplicationArea = All;
                Caption = 'Purchase Job Price Lists';
                Image = Purchase;
                Promoted = true;
                PromotedCategory = Process;
                Visible = not IsSalesPrice;
                ToolTip = 'View the list of all purchase job price lists.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Purchase Job Price Lists");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetEditable();
        SetMandatoryAmount();
        LineExists := false;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
        SetMandatoryAmount();
        LineExists := Rec."Price List Code" <> '';
    end;

    var
        AmountEditable: Boolean;
        UOMEditable: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        DiscountMandatory: Boolean;
        DiscountVisible: Boolean;
        PriceMandatory: Boolean;
        PriceVisible: Boolean;
        IsSalesPrice: Boolean;
        IsDraft: Boolean;
        AmountTypeIsVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        HideProductControls: Boolean;
        HideSourceControls: Boolean;
        LineExists: Boolean;
        DataCaptionSourceAssetTok: Label '%1 %2 - %3 %4 %5', Locked = true, Comment = '%1-%5 - Source Type, Source No., Product Type, Product No, Description';
        DataCaptionAssetTok: Label '%1 %2 %3', Locked = true, Comment = '%1 %2 %3 - Product Type, Product No, Description';

    protected var
        DataCaptionExpr: Text;
        PriceType: Enum "Price Type";
        ViewAmountType: Enum "Price Amount Type";

    local procedure EditPriceList()
    var
        PriceListHeader: Record "Price List Header";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        if Rec."Price List Code" = '' then
            exit;

        PriceListHeader.Get(Rec."Price List Code");
        PriceUXManagement.SetPriceListsFilters(PriceListHeader, PriceListHeader."Price Type", PriceListHeader."Amount Type");

        case PriceListHeader."Price Type" of
            PriceListHeader."Price Type"::Sale:
                Page.RunModal(Page::"Sales Price List", PriceListHeader);
            PriceListHeader."Price Type"::Purchase:
                Page.RunModal(Page::"Purchase Price List", PriceListHeader);
        end;
    end;

    local procedure ShowPriceLists()
    begin
        case PriceType of
            PriceType::Sale:
                PAGE.RunModal(PAGE::"Sales Price Lists");
            PriceType::Purchase:
                PAGE.RunModal(PAGE::"Purchase Price Lists");
        end;
    end;

    local procedure ShowJobPriceLists()
    begin
        case PriceType of
            PriceType::Sale:
                PAGE.RunModal(PAGE::"Sales Job Price Lists");
            PriceType::Purchase:
                PAGE.RunModal(PAGE::"Purchase Job Price Lists");
        end;
    end;

    procedure Set(PriceAssetList: Codeunit "Price Asset List"; NewPriceType: Enum "Price Type"; NewAmountType: Enum "Price Amount Type")
    var
        PriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceType := NewPriceType;
        ViewAmountType := NewAmountType;
        PriceSource."Price Type" := PriceType;
        PriceUXManagement.SetPriceListLineFilters(Rec, PriceSource, PriceAssetList, ViewAmountType);
        SetDataCaptionExpr(PriceAssetList);
        UpdateColumnVisibility();
    end;

    procedure Set(PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List"; NewAmountType: Enum "Price Amount Type")
    var
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceType := PriceSource."Price Type";
        ViewAmountType := NewAmountType;
        PriceUXManagement.SetPriceListLineFilters(Rec, PriceSource, PriceAssetList, ViewAmountType);
        SetDataCaptionExpr(PriceSource, PriceAssetList);
        UpdateColumnVisibility();
    end;

    local procedure SetDataCaptionExpr(PriceAssetList: Codeunit "Price Asset List")
    var
        TempPriceAsset: Record "Price Asset" temporary;
        FirstEntryNo: Integer;
    begin
        if PriceAssetList.GetList(TempPriceAsset) then begin
            FirstEntryNo := TempPriceAsset."Entry No.";
            if TempPriceAsset.FindLast() then begin
                TempPriceAsset.ValidateAssetNo();
                DataCaptionExpr :=
                    StrSubstNo(DataCaptionAssetTok,
                        TempPriceAsset."Asset Type", TempPriceAsset."Asset No.", TempPriceAsset.Description);
                HideProductControls := FirstEntryNo = TempPriceAsset."Entry No.";
            end;
        end;
    end;

    local procedure SetDataCaptionExpr(PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List")
    var
        TempPriceAsset: Record "Price Asset" temporary;
        FirstEntryNo: Integer;
    begin
        if PriceSource."Source No." <> '' then
            if PriceAssetList.GetList(TempPriceAsset) then begin
                FirstEntryNo := TempPriceAsset."Entry No.";
                if TempPriceAsset.FindLast() then begin
                    TempPriceAsset.ValidateAssetNo();
                    DataCaptionExpr :=
                        StrSubstNo(DataCaptionSourceAssetTok,
                            PriceSource."Source Type", PriceSource."Source No.",
                            TempPriceAsset."Asset Type", TempPriceAsset."Asset No.", TempPriceAsset.Description);
                    HideProductControls := FirstEntryNo = TempPriceAsset."Entry No.";
                    HideSourceControls := true;
                end;
            end;
    end;

    local procedure SetEditable()
    begin
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group";
        AmountEditable := Rec.IsAmountSupported();
        UOMEditable := Rec.IsUOMSupported();
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
        IsDraft := Rec.Status = Rec.Status::Draft;
    end;

    local procedure SetMandatoryAmount()
    begin
        DiscountMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Discount);
        PriceMandatory := Rec.IsAmountMandatory(Rec."Amount Type"::Price);
    end;

    local procedure UpdateColumnVisibility()
    begin
        AmountTypeIsVisible := ViewAmountType = ViewAmountType::Any;
        DiscountVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Discount];
        PriceVisible := ViewAmountType in [ViewAmountType::Any, ViewAmountType::Price];
        IsSalesPrice := PriceType = PriceType::Sale;
    end;
}
