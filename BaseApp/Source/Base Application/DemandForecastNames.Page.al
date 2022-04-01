page 99000921 "Demand Forecast Names"
{
    ApplicationArea = Planning;
    Caption = 'Demand Forecasts';
    PageType = List;
    SourceTable = "Production Forecast Name";
    UsageCategory = Lists;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the demand forecast.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of the demand forecast.';
                }
                field("View By"; Rec."View By")
                {
                    ApplicationArea = Planning;
                    Caption = 'View By';
                    ToolTip = 'Specifies by which period amounts are displayed.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Quantity Type"; Rec."Quantity Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Forecast Type"; Rec."Forecast Type")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast Type';
                    ToolTip = 'Specifies one of the following two types when you create a demand forecast entry: sales item or component item.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Item Filter"; ItemFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies an item filter to see specific items on the demand forecast matrix. Use this to reduce the demand forecast matrix entries.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Forecast By Locations"; Rec."Forecast By Locations")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Locations';
                    ToolTip = 'Use this if you want to create a forecast entry including the locations.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Location Filter"; LocationFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Location Filter';
                    ToolTip = 'Specifies a location code if you want to create a forecast entry for a specific location.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Forecast By Variants"; Rec."Forecast By Variants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Forecast by Variants';
                    ToolTip = 'Use this if you want to create a forecast entry including the variants.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Variant Filter"; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies an item variant code if you want to create a forecast entry for a specific item variant.';
                    Importance = Additional;
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Planning;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                    Visible = false;
                    Editable = false;
#if not CLEAN20
                    Enabled = NewDemandForecastUIEnabled;
#endif
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
            action("Edit Demand Forecast")
            {
                ApplicationArea = Planning;
                Caption = 'Edit Demand Forecast';
                Image = EditForecast;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Return';
                ToolTip = 'Open the related demand forecast.';

                trigger OnAction()
                var
#if not CLEAN20
                    DemandForecast: Page "Demand Forecast";
#endif
                    DemandForecastCard: Page "Demand Forecast Card";
                begin
#if not CLEAN20
                    if NewDemandForecastUIEnabled then begin
#endif
                        DemandForecastCard.SetRecord(Rec);
                        DemandForecastCard.Run();
#if not CLEAN20
                    end else begin
                        DemandForecast.SetProductionForecastName(Name);
                        DemandForecast.Run();
                    end;
#endif
                end;
            }
            action("Copy Demand Forecast")
            {
                ApplicationArea = Planning;
                Caption = 'Copy Demand Forecast Entries';
                Ellipsis = true;
                Image = CopyForecast;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Copy Production Forecast";
                ToolTip = 'Copy an existing demand forecast to quickly create a similar forecast.';
            }
        }
        area(Navigation)
        {
            action("Demand Forecast Entries")
            {
                ApplicationArea = Planning;
                Caption = 'Demand Forecast Entries';
                Image = Forecast;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Demand Forecast Entries";
                RunPageMode = View;
                RunPageLink = "Production Forecast Name" = field(Name);
                ToolTip = 'Opens a page with the demand forecast entries for the specified production forecast.';
            }
        }
    }

    trigger OnInit()
#if not CLEAN20
    var
        FeatureManagement: Codeunit "Feature Management Facade";
        NewDemandForcastUILbl: Label 'NewDemandForcastUI', Locked = true;
#endif
    begin
#if not CLEAN20
        NewDemandForecastUIEnabled := FeatureManagement.IsEnabled(NewDemandForcastUILbl);
#endif
    end;

    trigger OnAfterGetRecord()
    begin
        ItemFilter := Rec.GetItemFilterAsDisplayText();
        LocationFilter := Rec.GetLocationFilterBlobAsText();
        VariantFilter := Rec.GetVariantFilterBlobAsText();
    end;

    var
#if not CLEAN20
        NewDemandForecastUIEnabled: Boolean;
#endif
        ItemFilter: Text;
        LocationFilter: Text;
        VariantFilter: Text;
}