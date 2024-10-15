page 14941 "G/L Corr. Analysis View Card"
{
    Caption = 'G/L Corr. Analysis View Card';
    PageType = Card;
    SourceTable = "G/L Corr. Analysis View";

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
                    ToolTip = 'Specifies the code that identifies the general ledger correspondence.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the code that identifies the general ledger correspondence.';
                }
                field("Debit Account Filter"; "Debit Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account filter that is included in the analysis view.';
                }
                field("Credit Account Filter"; "Credit Account Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account filter that is included in the analysis view.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Date Compression"; "Date Compression")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the program will combine entries for, in order to create a single entry for that time period.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("Last Entry No."; "Last Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the last item ledger entry you posted, prior to updating the analysis view.';
                }
                field("Update on G/L Corr. Creation"; "Update on G/L Corr. Creation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to update the general ledger correspondence information when the analysis view is created.';
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
                field("Debit Dimension 1 Code"; "Debit Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Debit Dimension 2 Code"; "Debit Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Debit Dimension 3 Code"; "Debit Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 1 Code"; "Credit Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 2 Code"; "Credit Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
                }
                field("Credit Dimension 3 Code"; "Credit Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit dimension code by which you want to group the general ledger correspondence.';
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
                    RunObject = Page "G/L Corr. Analysis View Filter";
                    RunPageLink = "G/L Corr. Analysis View Code" = FIELD(Code);
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
                PromotedIsBig = true;
                RunObject = Codeunit "Update G/L Corr. Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
    }
}

