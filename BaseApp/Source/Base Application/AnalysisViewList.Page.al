page 556 "Analysis View List"
{
    ApplicationArea = Dimensions;
    Caption = 'Analysis Views';
    CardPageID = "Analysis View Card";
    Editable = false;
    PageType = List;
    SourceTable = "Analysis View";
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for this entry.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Account Source"; "Account Source")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies an account that you can use as a filter to define what is displayed in the Analysis by Dimensions window. ';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                    Visible = GLAccountSource;
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = Suite;
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
                field("Dimension 4 Code"; "Dimension 4 Code")
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
        area(processing)
        {
            action(EditAnalysis)
            {
                ApplicationArea = Dimensions;
                Caption = 'Analysis by Dimensions';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'View amounts in G/L accounts by their dimension values and other filters that you define in an analysis view and then show in a matrix window.';

                trigger OnAction()
                begin
                    RunAnalysisByDimensionPage();
                end;
            }
            action("&Update")
            {
                ApplicationArea = Suite;
                Caption = '&Update';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = Codeunit "Update Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        GLAccountSource := "Account Source" = "Account Source"::"G/L Account";
    end;

    var
        GLAccountSource: Boolean;
}

