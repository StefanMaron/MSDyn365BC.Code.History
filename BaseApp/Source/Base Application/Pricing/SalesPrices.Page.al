#if not CLEAN21
page 7002 "Sales Prices"
{
    Caption = 'Sales Prices';
    DataCaptionExpression = PageCaption;
    DelayedInsert = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Sales Price";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Visible = NOT IsOnMobile;
                field(SalesTypeFilter; SalesTypeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Type Filter';
                    OptionCaption = 'Customer,Customer Price Group,All Customers,Campaign,None';
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnValidate()
                    begin
                        SalesTypeFilterOnAfterValidate();
                    end;
                }
                field(SalesCodeFilterCtrl; SalesCodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Code Filter';
                    Enabled = SalesCodeFilterCtrlEnable;
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        CustPriceGrList: Page "Customer Price Groups";
                        CampaignList: Page "Campaign List";
                    begin
                        if SalesTypeFilter = SalesTypeFilter::"All Customers" then
                            exit;

                        case SalesTypeFilter of
                            SalesTypeFilter::Customer:
                                begin
                                    CustList.LookupMode := true;
                                    if CustList.RunModal() = ACTION::LookupOK then
                                        Text := CustList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                            SalesTypeFilter::"Customer Price Group":
                                begin
                                    CustPriceGrList.LookupMode := true;
                                    if CustPriceGrList.RunModal() = ACTION::LookupOK then
                                        Text := CustPriceGrList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                            SalesTypeFilter::Campaign:
                                begin
                                    CampaignList.LookupMode := true;
                                    if CampaignList.RunModal() = ACTION::LookupOK then
                                        Text := CampaignList.GetSelectionFilter()
                                    else
                                        exit(false);
                                end;
                        end;

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        SalesCodeFilterOnAfterValidate();
                    end;
                }
                field(ItemNoFilterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode := true;
                        if ItemList.RunModal() = ACTION::LookupOK then
                            Text := ItemList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ItemNoFilterOnAfterValidate();
                    end;
                }
                field(StartingDateFilter; StartingDateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(StartingDateFilter);
                        StartingDateFilterOnAfterValid();
                    end;
                }
                field(CurrencyCodeFilterCtrl; CurrencyCodeFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code Filter';
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CurrencyList: Page Currencies;
                    begin
                        CurrencyList.LookupMode := true;
                        if CurrencyList.RunModal() = ACTION::LookupOK then
                            Text := CurrencyList.GetSelectionFilter()
                        else
                            exit(false);

                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        CurrencyCodeFilterOnAfterValid();
                    end;
                }
                field(SystemId; SystemId)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies system id to provide OData capabilities.';
                    Visible = false;
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                Visible = IsOnMobile;
                field(FilterDescription; GetFilterDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a filter for which sales prices to display.';

                    trigger OnAssistEdit()
                    begin
                        FilterLines();
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesTypeControlEditable;
                    ToolTip = 'Specifies the sales price type, which defines whether the price is for an individual, group, all customers, or a campaign.';

                    trigger OnValidate()
                    begin
                        SalesCodeControlEditable := SetSalesCodeEditable("Sales Type");
                    end;
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = SalesCodeControlEditable;
                    ToolTip = 'Specifies the code that belongs to the Sales Type.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which the sales price is valid.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the currency of the sales price.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum sales quantity required to warrant the sales price.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the sales price is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calendar date when the sales price agreement ends.';
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the sales price includes VAT.';
                    Visible = false;
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a line discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the sales price (which includes VAT) to apply.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SalesPricesFilter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Filter';
                Image = "Filter";
                ToolTip = 'Apply the filter.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FilterLines();
                end;
            }
            action(ClearFilter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Clear Filter';
                Image = ClearFilter;
                ToolTip = 'Clear filter.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    Reset();
                    UpdateBasicRecFilters();
                    Evaluate(StartingDateFilter, GetFilter("Starting Date"));
                    SetEditableFields();
                end;
            }
            action(CopyPrices)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Prices';
                Image = Copy;
                ToolTip = 'Select prices and press OK to copy them to Customer No.';
                Visible = NOT IsLookupMode;

                trigger OnAction()
                begin
                    CopyPricesToCustomer();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SalesPricesFilter_Promoted; SalesPricesFilter)
                {
                }
                actionref(ClearFilter_Promoted; ClearFilter)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SalesCodeControlEditable := SetSalesCodeEditable("Sales Type");
        OnAfterGetCurrRecordOnAfterCalcSalesCodeControlEditable(Rec, SalesCodeControlEditable);
    end;

    trigger OnInit()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
        SalesCodeFilterCtrlEnable := true;
        SalesCodeControlEditable := true;
        IsLookupMode := CurrPage.LookupMode;
    end;

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;

        IsHandled := false;
        OnOpenPageOnBeforeGetRecFilters(Rec, IsHandled);
        if IsHandled then
            exit;
        GetRecFilters();
        SetRecFilters();
        SetCaption();
    end;

    var
        Cust: Record Customer;
        CustPriceGr: Record "Customer Price Group";
        Campaign: Record Campaign;
        ClientTypeManagement: Codeunit "Client Type Management";
        StartingDateFilter: Text;
        CurrencyCodeFilter: Text;
        PageCaption: Text;
        Text000: Label 'All Customers';
        Text001: Label 'No %1 within the filter %2.';
        [InDataSet]
        SalesCodeFilterCtrlEnable: Boolean;
        IsOnMobile: Boolean;
        IsLookupMode: Boolean;
        SalesTypeControlEditable: Boolean;
        SalesCodeControlEditable: Boolean;
        MultipleCustomersSelectedErr: Label 'More than one customer uses these sales prices. To copy prices, the Sales Code Filter field must contain one customer only.';
        IncorrectSalesTypeToCopyPricesErr: Label 'To copy sales prices, The Sales Type Filter field must contain Customer.';

    protected var
        SalesTypeFilter: Option Customer,"Customer Price Group","All Customers",Campaign,"None";
        SalesCodeFilter: Text;
        ItemNoFilter: Text;

    local procedure GetRecFilters()
    begin
        if GetFilters <> '' then
            UpdateBasicRecFilters();

        Evaluate(StartingDateFilter, GetFilter("Starting Date"));
    end;

    local procedure UpdateBasicRecFilters()
    begin
        if GetFilter("Sales Type") <> '' then
            SalesTypeFilter := GetSalesTypeFilter()
        else
            SalesTypeFilter := SalesTypeFilter::None;

        SalesCodeFilter := GetFilter("Sales Code");
        ItemNoFilter := GetFilter("Item No.");
        CurrencyCodeFilter := GetFilter("Currency Code");
    end;

    procedure SetRecFilters()
    begin
        SalesCodeFilterCtrlEnable := true;

        if SalesTypeFilter <> SalesTypeFilter::None then
            SetRange("Sales Type", SalesTypeFilter)
        else
            SetRange("Sales Type");

        if SalesTypeFilter in [SalesTypeFilter::"All Customers", SalesTypeFilter::None] then begin
            SalesCodeFilterCtrlEnable := false;
            SalesCodeFilter := '';
        end;

        if SalesCodeFilter <> '' then
            SetFilter("Sales Code", SalesCodeFilter)
        else
            SetRange("Sales Code");

        if StartingDateFilter <> '' then
            SetFilter("Starting Date", StartingDateFilter)
        else
            SetRange("Starting Date");

        if ItemNoFilter <> '' then
            SetFilter("Item No.", ItemNoFilter)
        else
            SetRange("Item No.");

        if CurrencyCodeFilter <> '' then
            SetFilter("Currency Code", CurrencyCodeFilter)
        else
            SetRange("Currency Code");

        case SalesTypeFilter of
            SalesTypeFilter::Customer:
                CheckFilters(DATABASE::Customer, SalesCodeFilter);
            SalesTypeFilter::"Customer Price Group":
                CheckFilters(DATABASE::"Customer Price Group", SalesCodeFilter);
            SalesTypeFilter::Campaign:
                CheckFilters(DATABASE::Campaign, SalesCodeFilter);
        end;
        CheckFilters(DATABASE::Item, ItemNoFilter);
        CheckFilters(DATABASE::Currency, CurrencyCodeFilter);

        SetEditableFields();
        CurrPage.Update(false);
    end;

    local procedure SetCaption()
    begin
        if IsOnMobile then
            PageCaption := ''
        else
            PageCaption := GetFilterDescription();
    end;

    local procedure GetFilterDescription(): Text
    var
        ObjTranslation: Record "Object Translation";
        SourceTableName: Text;
        SalesSrcTableName: Text;
        Description: Text;
    begin
        GetRecFilters();

        SourceTableName := '';
        if ItemNoFilter <> '' then
            SourceTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 27);

        SalesSrcTableName := '';
        Description := '';
        case SalesTypeFilter of
            SalesTypeFilter::Customer:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 18);
                    Cust."No." := CopyStr(SalesCodeFilter, 1, MaxStrLen(Cust."No."));
                    if Cust.Find() then
                        Description := Cust.Name;
                end;
            SalesTypeFilter::"Customer Price Group":
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 6);
                    CustPriceGr.Code := CopyStr(SalesCodeFilter, 1, MaxStrLen(CustPriceGr.Code));
                    if CustPriceGr.Find() then
                        Description := CustPriceGr.Description;
                end;
            SalesTypeFilter::Campaign:
                begin
                    SalesSrcTableName := ObjTranslation.TranslateObject(ObjTranslation."Object Type"::Table, 5071);
                    Campaign."No." := CopyStr(SalesCodeFilter, 1, MaxStrLen(Campaign."No."));
                    if Campaign.Find() then
                        Description := Campaign.Description;
                end;
            SalesTypeFilter::"All Customers":
                SalesSrcTableName := Text000;
        end;

        if SalesSrcTableName = Text000 then
            exit(StrSubstNo('%1 %2 %3', SalesSrcTableName, SourceTableName, ItemNoFilter));
        exit(StrSubstNo('%1 %2 %3 %4 %5', SalesSrcTableName, SalesCodeFilter, Description, SourceTableName, ItemNoFilter));
    end;

    local procedure CheckFilters(TableNo: Integer; FilterTxt: Text)
    var
        FilterRecordRef: RecordRef;
        FilterFieldRef: FieldRef;
    begin
        if FilterTxt = '' then
            exit;
        Clear(FilterRecordRef);
        Clear(FilterFieldRef);
        FilterRecordRef.Open(TableNo);
        FilterFieldRef := FilterRecordRef.Field(1);
        FilterFieldRef.SetFilter(FilterTxt);
        if FilterRecordRef.IsEmpty() then
            Error(Text001, FilterRecordRef.Caption, FilterTxt);
    end;

    local procedure SalesCodeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
        SetCaption();
    end;

    local procedure SalesTypeFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SalesCodeFilter := '';
        SetRecFilters();
        SetCaption();
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure ItemNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
        SetCaption();
    end;

    local procedure CurrencyCodeFilterOnAfterValid()
    begin
        CurrPage.SaveRecord();
        SetRecFilters();
    end;

    local procedure GetSalesTypeFilter(): Integer
    begin
        case GetFilter("Sales Type") of
            Format("Sales Type"::Customer):
                exit(0);
            Format("Sales Type"::"Customer Price Group"):
                exit(1);
            Format("Sales Type"::"All Customers"):
                exit(2);
            Format("Sales Type"::Campaign):
                exit(3);
        end;
    end;

    local procedure SetSalesCodeEditable(SalesType: Enum "Sales Price Type"): Boolean
    begin
        exit(SalesType <> "Sales Type"::"All Customers");
    end;

    local procedure SetEditableFields()
    begin
        SalesTypeControlEditable := GetFilter("Sales Type") = '';
        SalesCodeControlEditable :=
          SalesCodeControlEditable and (GetFilter("Sales Code") = '');
    end;

    local procedure FilterLines()
    var
        FilterPageBuilder: FilterPageBuilder;
    begin
        FilterPageBuilder.AddTable(TableCaption, DATABASE::"Sales Price");

        FilterPageBuilder.SetView(TableCaption, GetView());
        if GetFilter("Sales Type") = '' then
            FilterPageBuilder.AddFieldNo(TableCaption, FieldNo("Sales Type"));
        if GetFilter("Sales Code") = '' then
            FilterPageBuilder.AddFieldNo(TableCaption, FieldNo("Sales Code"));
        if GetFilter("Item No.") = '' then
            FilterPageBuilder.AddFieldNo(TableCaption, FieldNo("Item No."));
        if GetFilter("Starting Date") = '' then
            FilterPageBuilder.AddFieldNo(TableCaption, FieldNo("Starting Date"));
        if GetFilter("Currency Code") = '' then
            FilterPageBuilder.AddFieldNo(TableCaption, FieldNo("Currency Code"));

        if FilterPageBuilder.RunModal() then
            SetView(FilterPageBuilder.GetView(TableCaption));

        UpdateBasicRecFilters();
        Evaluate(StartingDateFilter, GetFilter("Starting Date"));
        SetEditableFields();
    end;

    local procedure CopyPricesToCustomer()
    var
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SelectedSalesPrice: Record "Sales Price";
        SalesPrices: Page "Sales Prices";
        CopyToCustomerNo: Code[20];
    begin
        if SalesTypeFilter <> SalesTypeFilter::Customer then
            Error(IncorrectSalesTypeToCopyPricesErr);
        Customer.SetFilter("No.", SalesCodeFilter);
        if Customer.Count <> 1 then
            Error(MultipleCustomersSelectedErr);
        CopyToCustomerNo := CopyStr(SalesCodeFilter, 1, MaxStrLen(CopyToCustomerNo));
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetFilter("Sales Code", '<>%1', SalesCodeFilter);
        SalesPrices.LookupMode(true);
        SalesPrices.SetTableView(SalesPrice);
        if SalesPrices.RunModal() = ACTION::LookupOK then begin
            SalesPrices.GetSelectionFilter(SelectedSalesPrice);
            CopySalesPriceToCustomersSalesPrice(SelectedSalesPrice, CopyToCustomerNo);
        end;
    end;

    procedure GetSelectionFilter(var SalesPrice: Record "Sales Price")
    begin
        CurrPage.SetSelectionFilter(SalesPrice);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCurrRecordOnAfterCalcSalesCodeControlEditable(var SalesPrice: Record "Sales Price"; var SalesCodeControlEditable: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOpenPageOnBeforeGetRecFilters(var SalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;
}
#endif
