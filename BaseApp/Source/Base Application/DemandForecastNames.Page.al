page 99000921 "Demand Forecast Names"
{
    ApplicationArea = Planning;
    Caption = 'Demand Forecasts';
    PageType = List;
    SourceTable = "Production Forecast Name";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the demand forecast.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of the demand forecast.';
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
                    DemandForecast: Page "Demand Forecast";
                begin
                    DemandForecast.SetProductionForecastName(Name);
                    DemandForecast.Run;
                end;
            }
            action("Copy Demand Forecast")
            {
                ApplicationArea = Planning;
                Caption = 'Copy Demand Forecast';
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
}

