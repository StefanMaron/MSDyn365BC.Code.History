page 7150 "Invt. Analysis View Card"
{
    Caption = 'Invt. Analysis View Card';
    PageType = Card;
    SourceTable = "Item Analysis View";
    SourceTableView = WHERE("Analysis Area" = CONST(Inventory));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the analysis view.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the analysis view.';
                }
                field("Item Filter"; "Item Filter")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which item ledger entries will be included in an analysis view.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Last Entry No."; "Last Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the last item ledger entry you posted, prior to updating the analysis view.';
                }
                field("Last Budget Entry No."; "Last Budget Entry No.")
                {
                    ApplicationArea = ItemBudget;
                    ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
                }
                field("Update on Posting"; "Update on Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the analysis view is updated every time that you post an item ledger entry, for example from a sales invoice.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = '&Update';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Update Item Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enable Update on Posting';
                Image = Apply;
                ToolTip = 'Ensure that the analysis view is updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    SetUpdateOnPosting(true);
                end;
            }
            action("Disable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Update on Posting';
                Image = UnApply;
                ToolTip = 'Ensure that the analysis view is not updated when new ledger entries are posted.';

                trigger OnAction()
                begin
                    SetUpdateOnPosting(false);
                end;
            }
        }
    }
}

