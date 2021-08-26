page 7022 "Price Worksheet"
{
    Caption = 'Price Worksheet';
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Page';
    DelayedInsert = true;
    SaveValues = true;
    SourceTable = "Price Worksheet Line";
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PriceTypeFilter; PriceType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Type';
                    ToolTip = 'Specifies a filter for which prices to display: sale or purchase.';

                    trigger OnValidate()
                    begin
                        InitSourceGroup();
                        SetRecFilters();
                    end;
                }
                field(Defaults; Defaults)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Defaults';
                    ToolTip = 'Specifies the fields of the price list header that is used as defaults for new lines created in the worksheet.';
                    trigger OnDrillDown()
                    begin
                        ShowPriceListFilters();
                    end;
                }
                field(SourceGroupFilter; SourceGroup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Group';
                    ToolTip = 'Specifies a filter for which group the prices apply to: customer, vendor, or job.';

                    trigger OnValidate()
                    begin
                        InitSourceGroup();
                        SetRecFilters();
                    end;
                }
                field(ModifyExistingLines; UpdateMultiplePriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update multiple price lists';
                    ToolTip = 'Specifies if the worksheet is in the mode when user can add new lines and modify the existing lines suggested by the copy lines action.';
                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Lines)
            {
                ShowCaption = false;
                field("Price List Code"; Rec."Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UpdateMultiplePriceLists;
                    Editable = false;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field("Existing Line"; Rec."Existing Line")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = UpdateMultiplePriceLists;
                    Editable = false;
                    ToolTip = 'Specifies if the current line is a copy of the existing price list line.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = ModifiedLine;
                    ToolTip = 'Specifies whether the price list line is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field(CustomerSourceType; CustomerSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    //Editable = PriceListIsEditable;
                    Visible = SourceGroup = SourceGroup::Customer;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the customer or customer price group.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(CustomerSourceType.AsInteger());
                    end;
                }
                field(VendorSourceType; VendorSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    //Editable = PriceListIsEditable;
                    Visible = SourceGroup = SourceGroup::Vendor;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the vendor.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(VendorSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    //Editable = PriceListIsEditable;
                    Visible = SourceGroup = SourceGroup::Job;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the job or job task.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field("Parent Source No."; Rec."Parent Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = SourceGroup = SourceGroup::Job;
                    Editable = PriceLineEditable and ParentSourceNoEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the job on the price list line.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and SourceNoEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Asset Type"; Rec."Asset Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AssetTypeEditable;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the number of the product.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ItemAssetVisible;
                    Editable = PriceLineEditable and ItemAsset;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    Visible = ResourceAssetVisible;
                    Editable = PriceLineEditable and ResourceAsset;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the currency code of the price list line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = ItemAssetVisible or ResourceAssetVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AmountTypeIsVisible;
                    Editable = PriceLineEditable and AmountTypeIsEditable;
                    ToolTip = 'Specifies whether the price list line defines prices, discounts, or both.';
                }
                field("Existing Unit Price"; Rec."Existing Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and SalesVisible;
                    ToolTip = 'Specifies the current unit price of the product.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    Caption = 'New Unit Price';
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and SalesVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = ModifiedUnitPrice and SalesPriceLine and PriceEditable;
                    ToolTip = 'Specifies the new unit price of the product.';
                }
                field("Cost Factor"; Rec."Cost Factor")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and SalesVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    ToolTip = 'Specifies the unit cost factor for job-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Existing Direct Unit Cost"; Rec."Existing Direct Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible;
                    ToolTip = 'Specifies the current direct unit cost of the product.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    Caption = 'New Direct Unit Cost';
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = ModifiedDirectUnitCost and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the new direct unit cost of the product.';
                }
                field("Existing Unit Cost"; Rec."Existing Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible;
                    ToolTip = 'Specifies the current unit cost of the product.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible and PurchVisible;
                    Editable = PriceLineEditable and PriceEditable;
                    Style = Attention;
                    StyleExpr = ModifiedUnitCost and PurchPriceLine and PriceEditable;
                    ToolTip = 'Specifies the unit cost of the resource.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DiscountVisible;
                    Editable = PriceLineEditable and DiscountEditable;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceLineEditable and AllowUpdatingDefaults;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = PriceVisible;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the price (which includes VAT) to apply.';
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = PriceLineEditable;
                    ToolTip = 'Specifies if the price includes VAT.';
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
                var
                    PriceUXManagement: Codeunit "Price UX Management";
                begin
                    PriceUXManagement.EditPriceList(Rec."Price List Code");
                end;
            }

        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = SuggestItemPrice;
                    Promoted = true;
                    PromotedCategory = Process;
                    Caption = 'Suggest Lines';
                    ToolTip = 'Creates the sales price list lines based on the unit price in the product cards, like item or resource. Change the price list status to ''Draft'' to run this action.';

                    trigger OnAction()
                    begin
                        if DefaultPriceListCode = '' then
                            Error(DefinePriceListCodeErr);
                        PriceListManagement.AddLines(TempWorksheetPriceListHeader);
                        Defaults := GetDefaults();
                        CurrPage.Update(false);
                    end;
                }
                action(CopyLines)
                {
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = CopyWorksheet;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = CopyLinesEnabled;
                    Caption = 'Copy Lines';
                    ToolTip = 'Copies the lines from the existing price list. New prices can be adjusted by a factor and rounded differently. Change the price list status to ''Draft'' to run this action.';

                    trigger OnAction()
                    begin
                        if DefaultPriceListCode = '' then
                            Error(DefinePriceListCodeErr);
                        PriceListManagement.CopyLines(TempWorksheetPriceListHeader, UpdateMultiplePriceLists);
                        Defaults := GetDefaults();
                        CurrPage.Update(false);
                    end;
                }
                action(ImplementPriceChange)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I&mplement Price Change';
                    Ellipsis = true;
                    Image = ImplementPriceChange;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'Update the alternate prices with the ones in the Price Worksheet window.';

                    trigger OnAction()
                    var
                        PriceWorksheetLine: Record "Price Worksheet Line";
                    begin
                        CurrPage.SetSelectionFilter(PriceWorksheetLine);
                        if PriceWorksheetLine.Count() = 1 then begin
                            PriceWorksheetLine.Reset();
                            PriceWorksheetLine.SetRange("Price Type", PriceType);
                            PriceWorksheetLine.SetRange("Source Group", SourceGroup);
                        end;
                        PriceListManagement.ImplementNewPrices(PriceWorksheetLine);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Send the data in the worksheet to an Excel file for analysis or editing.';
                    Visible = false; //IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                        FilterValue: Text;
                    begin
                        FilterValue := StrSubstNo(WorksheetFilterLbl, Rec."Price Type", Rec."Source Group");
                        ODataUtility.EditWorksheetInExcel(CopyStr(CurrPage.Caption, 1, 240), CurrPage.ObjectId(false), FilterValue);
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureDisabled();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetNewRecord(true);
        Rec.TransferFields(TempWorksheetPriceListLine);
        Rec.Validate("Asset Type", xRec."Asset Type");
        Rec."Line No." := 0;
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        CopyLinesEnabled := PriceListManagement.VerifySourceGroupInLines();
        InitSourceGroup();
        UpdateSourceType();
        SetRecFilters();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateSourceType();
        SetFieldsStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateSourceType();
        SetEditableFields();
        LineExists := Rec."Price List Code" <> '';
    end;

    var
        CurrPriceListHeader: Record "Price List Header";
        TempWorksheetPriceListHeader: Record "Price List Header" temporary;
        TempWorksheetPriceListLine: Record "Price List Line" temporary;
        PriceListManagement: Codeunit "Price List Management";
        CustomerSourceType: Enum "Sales Price Source Type";
        VendorSourceType: Enum "Purchase Price Source Type";
        JobSourceType: Enum "Job Price Source Type";
        PriceType: Enum "Price Type";
        SourceGroup: Enum "Price Source Group";
        AllowEditingActivePrice: Boolean;
        AllowUpdatingDefaults: Boolean;
        AmountTypeIsEditable: Boolean;
        AmountTypeIsVisible: Boolean;
        AssetTypeEditable: Boolean;
        DiscountEditable: Boolean;
        DiscountVisible: Boolean;
        ItemAsset: Boolean;
        ItemAssetVisible: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        LineExists: Boolean;
        ModifiedLine: Boolean;
        ModifiedUnitPrice: Boolean;
        ModifiedUnitCost: Boolean;
        ModifiedDirectUnitCost: Boolean;
        ParentSourceNoEditable: Boolean;
        PriceEditable: Boolean;
        PriceLineEditable: Boolean;
        PriceVisible: Boolean;
        PurchPriceLine: Boolean;
        PurchVisible: Boolean;
        ResourceAsset: Boolean;
        ResourceAssetVisible: Boolean;
        SalesPriceLine: Boolean;
        SalesVisible: Boolean;
        SourceNoEditable: Boolean;
        SourceTypeEditable: Boolean;
        DefaultPriceListCode: Code[20];
        DefaultPriceListCodeLbl: Text;
        Defaults: Text;
        DefinePriceListCodeErr: Label 'Define the default price list.';
        DefinePriceListCodeLbl: Label 'Define the price list...';
        UpdateMultiplePriceLists: Boolean;
        DefaultsLbl: Label '%1 = %2; ', Locked = true;
        CopyLinesEnabled: Boolean;
        WorksheetFilterLbl: Label 'Price_Type eq ''%1'' and Source_Group eq ''%2''', Locked = true;

    procedure SetPriceType(NewPriceType: Enum "Price Type")
    begin
        PriceType := NewPriceType;
    end;

    local procedure CalcSourceNoEditable()
    begin
        SourceNoEditable := Rec.IsSourceNoAllowed();
    end;

    local procedure GetDefaults() Result: Text
    begin
        InitDefaultsLine(TempWorksheetPriceListHeader);

        Result := GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Source Type"), Format(TempWorksheetPriceListHeader."Source Type"), true);
        Result += GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Parent Source No."), TempWorksheetPriceListHeader."Parent Source No.", false);
        Result += GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Source No."), TempWorksheetPriceListHeader."Source No.", false);
        Result += GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Currency Code"), TempWorksheetPriceListHeader."Currency Code", false);
        Result += GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Starting Date"), format(TempWorksheetPriceListHeader."Starting Date"), false);
        Result += GetDefaults(TempWorksheetPriceListHeader.FieldCaption("Ending Date"), format(TempWorksheetPriceListHeader."Ending Date"), false);
    end;

    local procedure GetDefaults(FldName: Text; FldValue: Text; ShowBlank: Boolean): Text;
    begin
        if ShowBlank or (FldValue <> '') then
            exit(StrSubstNo(DefaultsLbl, FldName, FldValue))
    end;

    local procedure GetDefaultSourceType() DefaultSourceType: Enum "Price Source Type";
    begin
        case SourceGroup of
            SourceGroup::Customer:
                DefaultSourceType := Rec."Source Type"::"All Customers";
            SourceGroup::Vendor:
                DefaultSourceType := Rec."Source Type"::"All Vendors";
            SourceGroup::Job:
                DefaultSourceType := Rec."Source Type"::"All Jobs";
        end;
    end;

    local procedure InitDefaultsLine(TempWorksheetPriceListHeader: Record "Price List Header")
    begin
        TempWorksheetPriceListHeader."Allow Updating Defaults" := false;
        TempWorksheetPriceListLine.CopyFrom(TempWorksheetPriceListHeader);
        TempWorksheetPriceListLine."Amount Type" := TempWorksheetPriceListHeader."Amount Type";
    end;

    local procedure InitPriceType()
    begin
        if PriceType = PriceType::Any then
            PriceType := PriceType::Sale;
    end;

    local procedure InitSourceGroup()
    begin
        CurrPage.SaveRecord();

        InitPriceType();
        if SourceGroup = SourceGroup::All then
            SourceGroup := SourceGroup::Customer;
        case SourceGroup of
            SourceGroup::Customer:
                if PriceType = PriceType::Purchase then
                    SourceGroup := SourceGroup::Vendor;
            SourceGroup::Vendor:
                if PriceType = PriceType::Sale then
                    SourceGroup := SourceGroup::Customer;
        end;
        SetDefaultPriceListCode();
    end;

    local procedure SetDefaultPriceListCode()
    var
        xDefaultPriceListCode: Code[20];
    begin
        xDefaultPriceListCode := DefaultPriceListCode;
        DefaultPriceListCode := PriceListManagement.GetDefaultPriceListCode(PriceType, SourceGroup, false);
        UpdateDefaults(xDefaultPriceListCode);
        SetPriceListCodeInWorksheetLines();

        if DefaultPriceListCode = '' then
            DefaultPriceListCodeLbl := DefinePriceListCodeLbl
        else
            DefaultPriceListCodeLbl := DefaultPriceListCode;
        AllowEditingActivePrice := PriceListManagement.IsAllowedEditingActivePrice(PriceType);
    end;

    local procedure SetEditableFields()
    var
        PriceSource: Record "Price Source";
    begin
        if Rec."Price List Code" = '' then
            AllowUpdatingDefaults := true
        else
            if Rec."Price List Code" <> CurrPriceListHeader.Code then begin
                AllowUpdatingDefaults := true;
                if CurrPriceListHeader.Get(Rec."Price List Code") then
                    AllowUpdatingDefaults := CurrPriceListHeader."Allow Updating Defaults";
            end;

        PriceSource."Source Type" := Rec."Source Type";
        ParentSourceNoEditable := PriceSource.IsParentSourceAllowed();
        AmountTypeIsEditable := Rec."Asset Type" <> Rec."Asset Type"::"Item Discount Group";
        ItemAsset := Rec.IsAssetItem();
        ResourceAsset := Rec.IsAssetResource();
        PriceLineEditable := Rec.IsEditable();
        CalcSourceNoEditable();
        SetFieldsStyle();
    end;

    local procedure SetFieldsStyle()
    begin
        ModifiedUnitPrice := Rec."Existing Unit Price" <> Rec."Unit Price";
        ModifiedDirectUnitCost := Rec."Existing Direct Unit Cost" <> Rec."Direct Unit Cost";
        ModifiedUnitCost := Rec."Existing Unit Cost" <> Rec."Unit Cost";
        ModifiedLine := ModifiedUnitPrice or ModifiedDirectUnitCost or ModifiedUnitCost;
        SalesPriceLine := Rec."Price Type" = Rec."Price Type"::Sale;
        PurchPriceLine := Rec."Price Type" = Rec."Price Type"::Purchase;
        PriceEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Price];
        DiscountEditable := Rec."Amount Type" in [Rec."Amount Type"::Any, Rec."Amount Type"::Discount];
    end;

    local procedure SetFilters()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Price Type", PriceType);
        Rec.SetRange("Source Group", SourceGroup);
        Rec.FilterGroup(0);
    end;

    local procedure SetPriceListCodeInWorksheetLines()
    var
        PriceWorksheetLine: Record "Price Worksheet Line";
        NewPriceWorksheetLine: Record "Price Worksheet Line";
    begin
        if DefaultPriceListCode = '' then
            exit;
        PriceWorksheetLine.SetRange("Price Type", PriceType);
        PriceWorksheetLine.SetRange("Source Group", SourceGroup);
        PriceWorksheetLine.SetRange("Price List Code", '');
        if PriceWorksheetLine.FindSet(true) then
            repeat
                PriceWorksheetLine.Delete(true);
                NewPriceWorksheetLine := PriceWorksheetLine;
                NewPriceWorksheetLine."Price List Code" := DefaultPriceListCode;
                NewPriceWorksheetLine."Line No." := 0;
                NewPriceWorksheetLine.Insert(true);
            until PriceWorksheetLine.Next() = 0;
    end;

    local procedure SetRecFilters()
    begin
        SetFilters();
        SetVisibleFields();

        CurrPage.Update(false);
    end;

    local procedure SetVisibleFields()
    begin
        SalesVisible := PriceType = PriceType::Sale;
        PurchVisible := PriceType = PriceType::Purchase;

        AmountTypeIsVisible := true;//AmountTypeFilter = AmountTypeFilter::Any;
        PriceVisible := true;//AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Price];
        DiscountVisible := true;//AmountTypeFilter in [AmountTypeFilter::Any, AmountTypeFilter::Discount];

        //PriceListLine."Asset Type" := PriceAsset."Asset Type";
        ItemAssetVisible := true;//(PriceAsset."Asset Type" = "Price Asset Type"::" ") or PriceListLine.IsAssetItem();
        ResourceAssetVisible := true;//(PriceAsset."Asset Type" = "Price Asset Type"::" ") or PriceListLine.IsAssetResource();

        SourceTypeEditable := true;//PriceSource."Source Type" = PriceSource."Source Type"::All;
        AssetTypeEditable := true;//PriceAsset."Asset Type" = PriceAsset."Asset Type"::" ";
    end;

    local procedure ShowPriceListFilters()
    var
        PriceListFilters: Page "Price List Filters";
    begin
        PriceListFilters.Set(TempWorksheetPriceListHeader);
        PriceListFilters.LookupMode(true);
        if PriceListFilters.RunModal() = Action::LookupOK then begin
            PriceListFilters.GetRecord(TempWorksheetPriceListHeader);
            Defaults := GetDefaults();
            CurrPage.Update(false);
        end;
    end;

    local procedure UpdateDefaults(xDefaultPriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
    begin
        if DefaultPriceListCode = '' then begin
            Clear(TempWorksheetPriceListHeader);
            TempWorksheetPriceListHeader."Price Type" := PriceType;
            TempWorksheetPriceListHeader."Source Group" := SourceGroup;
            TempWorksheetPriceListHeader.Validate("Source Type", GetDefaultSourceType());
        end else
            if xDefaultPriceListCode <> DefaultPriceListCode then
                if PriceListHeader.Get(DefaultPriceListCode) then begin
                    TempWorksheetPriceListHeader := PriceListHeader;
                    TempWorksheetPriceListHeader.Status := "Price Status"::Draft;
                end;
        Defaults := GetDefaults();
    end;

    local procedure UpdateSourceType()
    begin
        case SourceGroup of
            SourceGroup::Customer:
                CustomerSourceType := "Sales Price Source Type".FromInteger(Rec."Source Type".AsInteger());
            SourceGroup::Vendor:
                VendorSourceType := "Purchase Price Source Type".FromInteger(Rec."Source Type".AsInteger());
            SourceGroup::Job:
                JobSourceType := "Job Price Source Type".FromInteger(Rec."Source Type".AsInteger());
        end;
        CalcSourceNoEditable();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Source Type", SourceType);
        CalcSourceNoEditable();
        CurrPage.SaveRecord();
    end;
}
