page 9371 "Analysis View List Sales"
{
    ApplicationArea = Dimensions, SalesAnalysis;
    Caption = 'Sales Analysis Views';
    CardPageID = "Sales Analysis View Card";
    DataCaptionFields = "Analysis Area";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View";
    SourceTableView = WHERE("Analysis Area" = CONST(Sales));
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies a code for the analysis view.';
                }
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the name of the analysis view.';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = SalesAnalysis;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Dimension 1 Code"; "Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; "Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; "Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
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
        area(navigation)
        {
            group("&Analysis")
            {
                Caption = '&Analysis';
                Image = AnalysisView;
                action(PageItemAnalysisViewFilter)
                {
                    ApplicationArea = SalesAnalysis;
                    Caption = 'Filter';
                    Image = "Filter";
                    RunObject = Page "Item Analysis View Filter";
                    RunPageLink = "Analysis Area" = FIELD("Analysis Area"),
                                  "Analysis View Code" = FIELD(Code);
                    ToolTip = 'Apply the filter.';
                }
            }
        }
        area(processing)
        {
            action(EditAnalysisView)
            {
                ApplicationArea = SalesAnalysis;
                Caption = 'Edit Analysis View';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Edit the settings for the analysis view such as a column or line.';

                trigger OnAction()
                var
                    SalesAnalysisbyDim: Page "Sales Analysis by Dimensions";
                begin
                    SalesAnalysisbyDim.SetCurrentAnalysisViewCode(Code);
                    SalesAnalysisbyDim.Run;
                end;
            }
            action("&Update")
            {
                ApplicationArea = SalesAnalysis;
                Caption = '&Update';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
    }
}

