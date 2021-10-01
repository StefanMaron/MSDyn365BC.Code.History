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
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the price list line is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                }
                field("Source Type"; Rec."Source Type")
                {
                    Caption = 'Applies-to Type';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideSourceControls;
                    ToolTip = 'Specifies the type of the source the price applies to.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                }
                field("Source No."; Rec."Source No.")
                {
                    Caption = 'Applies-to No.';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideSourceControls;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    Caption = 'Product Type';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideProductControls;
                    ToolTip = 'Specifies the type of the product.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                }
                field("Asset No."; Rec."Asset No.")
                {
                    Caption = 'Product No.';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = not HideProductControls;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the product.';
                    Style = Attention;
                    StyleExpr = LineToVerify;
                    trigger OnValidate()
                    begin
                        SetEditable();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = PriceEditable;
                    Visible = not HideProductControls;
                    ToolTip = 'Specifies the description of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Visible = ItemAsset;
                    Editable = ItemAsset and PriceEditable;
                    ToolTip = 'Specifies the item variant.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Visible = ResourceAsset;
                    Editable = ResourceAsset and PriceEditable;
                    ToolTip = 'Specifies the work type code for the resource.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Enabled = UOMEditable;
                    Editable = UOMEditable and PriceEditable;
                    ToolTip = 'Specifies the unit of measure for the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    Editable = PriceEditable;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = AmountTypeIsVisible;
                    Editable = AmountTypeIsEditable and PriceEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                    trigger OnValidate()
                    begin
                        SetMandatoryAmount();
                        CurrPage.Update(true);
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
                    Editable = AmountEditable and PriceEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and IsSalesPrice;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit price of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    ApplicationArea = All;
                    Editable = AmountEditable and PriceEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and IsSalesPrice;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost factor for job-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(DirectUnitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    ApplicationArea = All;
                    Editable = AmountEditable and PriceEditable;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and not IsSalesPrice;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = AmountEditable and PriceEditable and ResourceAsset;
                    Enabled = PriceMandatory;
                    Visible = PriceVisible and not IsSalesPrice and ResourceAsset;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies the unit cost of the resource.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
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
                    Editable = PriceMandatory and PriceEditable;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and IsSalesPrice;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory and PriceEditable;
                    Style = Attention;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(PurchLineDiscountPct; Rec."Line Discount %")
                {
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and not IsSalesPrice;
                    Enabled = DiscountMandatory;
                    Editable = DiscountMandatory and PriceEditable;
                    Style = Attention;
                    StyleExpr = not DiscountMandatory;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Visible = PriceVisible and IsSalesPrice;
                    Enabled = PriceMandatory;
                    Editable = PriceMandatory and PriceEditable;
                    Style = Attention;
                    StyleExpr = not PriceMandatory;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
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
                    PriceUXManagement.EditPriceList(Rec."Price List Code");
                end;
            }
            action(VerifyLines)
            {
                ApplicationArea = Basic, Suite;
                Ellipsis = true;
                Image = CheckDuplicates;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Verify Lines';
                ToolTip = 'Checks data consistency in the new and modified price list lines. Finds the duplicate price lines and suggests the resolution of the line conflicts.';

                trigger OnAction()
                var
                    PriceListLine: Record "Price List Line";
                    PriceListManagement: Codeunit "Price List Management";
                begin
                    PriceListLine.Copy(Rec);
                    PriceListManagement.ActivateDraftLines(PriceListLine);
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
        LineToVerify := Rec.IsLineToVerify();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable();
        SetMandatoryAmount();
        LineExists := Rec."Price List Code" <> '';
        LineToVerify := Rec.IsLineToVerify();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        if HasDraftLines() then begin
            PriceListManagement.SendVerifyLinesNotification();
            exit(false);
        end;
        exit(true)
    end;

    var
        PriceUXManagement: Codeunit "Price UX Management";
        AmountEditable: Boolean;
        UOMEditable: Boolean;
        ItemAsset: Boolean;
        ResourceAsset: Boolean;
        DiscountMandatory: Boolean;
        DiscountVisible: Boolean;
        PriceMandatory: Boolean;
        PriceVisible: Boolean;
        IsSalesPrice: Boolean;
        PriceEditable: Boolean;
        AmountTypeIsVisible: Boolean;
        AmountTypeIsEditable: Boolean;
        HideProductControls: Boolean;
        HideSourceControls: Boolean;
        LineExists: Boolean;
        LineToVerify: Boolean;
        DataCaptionSourceAssetTok: Label '%1 %2 - %3 %4 %5', Locked = true, Comment = '%1-%5 - Source Type, Source No., Product Type, Product No, Description';
        DataCaptionAssetTok: Label '%1 %2 %3', Locked = true, Comment = '%1 %2 %3 - Product Type, Product No, Description';

    protected var
        DataCaptionExpr: Text;
        PriceType: Enum "Price Type";
        ViewAmountType: Enum "Price Amount Type";

    local procedure HasDraftLines(): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.Copy(Rec);
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if PriceListLine.FindSet() then
            repeat
                if PriceListLine.IsHeaderActive() then
                    exit(true);
            until PriceListLine.Next() = 0;
        exit(false);
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
    begin
        PriceType := NewPriceType;
        ViewAmountType := NewAmountType;
        PriceSource."Price Type" := PriceType;
        PriceUXManagement.SetPriceListLineFilters(Rec, PriceSource, PriceAssetList, ViewAmountType);
        SetDataCaptionExpr(PriceAssetList);
        UpdateColumnVisibility();
    end;

    procedure Set(PriceSource: Record "Price Source"; PriceAssetList: Codeunit "Price Asset List"; NewAmountType: Enum "Price Amount Type")
    begin
        PriceType := PriceSource."Price Type";
        ViewAmountType := NewAmountType;
        PriceUXManagement.SetPriceListLineFilters(Rec, PriceSource, PriceAssetList, ViewAmountType);
        SetDataCaptionExpr(PriceSource, PriceAssetList);
        UpdateColumnVisibility();
    end;

    procedure Set(PriceSourceList: Codeunit "Price Source List"; NewAmountType: Enum "Price Amount Type")
    begin
        PriceType := PriceSourceList.GetPriceType();
        ViewAmountType := NewAmountType;
        PriceUXManagement.SetPriceListLineFilters(Rec, PriceSourceList, ViewAmountType);
        SetDataCaptionExpr(PriceSourceList);
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

    local procedure SetDataCaptionExpr(PriceSourceList: Codeunit "Price Source List")
    var
        TempPriceSource: Record "Price Source" temporary;
        FirstEntryNo: Integer;
    begin
        if PriceSourceList.GetList(TempPriceSource) then begin
            FirstEntryNo := TempPriceSource."Entry No.";
            if TempPriceSource.FindLast() then begin
                DataCaptionExpr :=
                    StrSubstNo(DataCaptionAssetTok,
                        TempPriceSource."Source Type", TempPriceSource."Source No.", TempPriceSource.Description);
                HideSourceControls := FirstEntryNo = TempPriceSource."Entry No.";
                HideProductControls := false;
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
        PriceEditable := Rec.IsEditable();
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