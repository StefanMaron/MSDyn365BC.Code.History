page 7155 "Sales Analysis View Card"
{
    Caption = 'Sales Analysis View Card';
    PageType = Card;
    SourceTable = "Item Analysis View";
    SourceTableView = WHERE("Analysis Area" = CONST(Sales));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                field("Item Filter"; "Item Filter")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies a filter to specify the items that will be included in an analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode(true);
                        if ItemList.RunModal = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;
                }
                field("Location Filter"; "Location Filter")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location filter to specify that only entries posted to a particular location are to be included in an analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LocList: Page "Location List";
                    begin
                        LocList.LookupMode(true);
                        if LocList.RunModal = ACTION::LookupOK then begin
                            Text := LocList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;
                }
                field("Date Compression"; "Date Compression")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the date from which item ledger entries will be included in an analysis view.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Last Entry No."; "Last Entry No.")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies the number of the last item ledger entry you posted, prior to updating the analysis view.';
                }
                field("Last Budget Entry No."; "Last Budget Entry No.")
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
                }
                field("Update on Posting"; "Update on Posting")
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies if the analysis view is updated every time that you post an item ledger entry, for example from a sales invoice.';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = SalesBudget;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = SalesAnalysis;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
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
                action("Filter")
                {
                    ApplicationArea = SalesAnalysis;
                    Caption = 'Filter';
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
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
                ApplicationArea = SalesAnalysis;
                Caption = '&Update';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = SalesAnalysis;
                Caption = 'Enable Update on Posting';
                Image = Apply;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Ensure that the analysis view is updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    SetUpdateOnPosting(true);
                end;
            }
            action("Disable Update on Posting")
            {
                ApplicationArea = SalesAnalysis;
                Caption = 'Disable Update on Posting';
                Image = UnApply;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Ensure that the analysis view is not updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    SetUpdateOnPosting(false);
                end;
            }
        }
    }
}

