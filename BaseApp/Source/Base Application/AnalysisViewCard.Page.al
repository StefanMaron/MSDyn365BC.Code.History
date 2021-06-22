page 555 "Analysis View Card"
{
    Caption = 'Analysis View Card';
    PageType = Card;
    SourceTable = "Analysis View";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for this card.';
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

                    trigger OnValidate()
                    begin
                        SetGLAccountSource;
                    end;
                }
                field("Account Filter"; "Account Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which accounts are shown in the analysis view.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                        CFAccList: Page "Cash Flow Account List";
                    begin
                        if "Account Source" = "Account Source"::"G/L Account" then begin
                            GLAccList.LookupMode(true);
                            if not (GLAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := GLAccList.GetSelectionFilter;
                        end else begin
                            CFAccList.LookupMode(true);
                            if not (CFAccList.RunModal = ACTION::LookupOK) then
                                exit(false);

                            Text := CFAccList.GetSelectionFilter;
                        end;

                        exit(true);
                    end;
                }
                field("Date Compression"; "Date Compression")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the starting date of the campaign analysis.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the analysis view was last updated.';
                }
                field("Last Entry No."; "Last Entry No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the last item ledger entry you posted, prior to updating the analysis view.';
                }
                field("Last Budget Entry No."; "Last Budget Entry No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the last item budget entry you entered prior to updating the analysis view.';
                }
                field("Update on Posting"; "Update on Posting")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the analysis view is updated every time that you post an item ledger entry.';
                }
                field("Include Budgets"; "Include Budgets")
                {
                    ApplicationArea = Suite;
                    Editable = GLAccountSource;
                    ToolTip = 'Specifies whether to include an update of analysis view budget entries, when updating an analysis view.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Suite;
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
        area(navigation)
        {
            group("&Analysis")
            {
                Caption = '&Analysis';
                Image = AnalysisView;
                action("Filter")
                {
                    ApplicationArea = Suite;
                    Caption = 'Filter';
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Analysis View Filter";
                    RunPageLink = "Analysis View Code" = FIELD(Code);
                    ToolTip = 'Apply the filter.';
                }
            }
        }
        area(processing)
        {
            action("&Update")
            {
                ApplicationArea = Suite;
                Caption = '&Update';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Codeunit "Update Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
            action("Enable Update on Posting")
            {
                ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
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

    trigger OnAfterGetRecord()
    begin
        SetGLAccountSource;
    end;

    trigger OnOpenPage()
    begin
        GLAccountSource := true;
    end;

    var
        GLAccountSource: Boolean;

    local procedure SetGLAccountSource()
    begin
        GLAccountSource := "Account Source" = "Account Source"::"G/L Account";
    end;
}

