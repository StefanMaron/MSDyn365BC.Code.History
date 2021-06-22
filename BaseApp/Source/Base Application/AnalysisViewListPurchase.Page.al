page 9370 "Analysis View List Purchase"
{
    ApplicationArea = Dimensions, PurchaseAnalysis;
    Caption = 'Purchase Analysis Views';
    CardPageID = "Purchase Analysis View Card";
    DataCaptionFields = "Analysis Area";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View";
    SourceTableView = WHERE("Analysis Area" = CONST(Purchase));
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
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies a code for the analysis view.';
                }
                field(Name; Name)
                {
                    ApplicationArea = PurchaseAnalysis;
                    ToolTip = 'Specifies the name of the analysis view.';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = PurchaseBudget;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = PurchaseAnalysis;
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
                    ApplicationArea = PurchaseAnalysis;
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
                ApplicationArea = PurchaseAnalysis;
                Caption = 'Edit Analysis View';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Edit the settings for the analysis view such as a column or line.';

                trigger OnAction()
                var
                    PurchAnalysisbyDim: Page "Purch. Analysis by Dimensions";
                begin
                    PurchAnalysisbyDim.SetCurrentAnalysisViewCode(Code);
                    PurchAnalysisbyDim.Run;
                end;
            }
            action("&Update")
            {
                ApplicationArea = PurchaseAnalysis;
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

