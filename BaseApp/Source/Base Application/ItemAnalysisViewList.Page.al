page 7151 "Item Analysis View List"
{
    Caption = 'Analysis View List';
    DataCaptionFields = "Analysis Area";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies a code for the analysis view.';
                }
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    ToolTip = 'Specifies the name of the analysis view.';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
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
                action(Card)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
                action(PageItemAnalysisViewFilter)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
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
            action("&Update")
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
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

