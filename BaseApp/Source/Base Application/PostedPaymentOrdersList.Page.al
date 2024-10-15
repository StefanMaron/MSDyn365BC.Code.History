page 7000055 "Posted Payment Orders List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Payment Orders';
    CardPageID = "Posted Payment Orders";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Posted Payment Order";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of this posted payment order.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank where the posted payment order was delivered.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the bank code or bank number where the posted payment order was delivered.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code associated with this posted payment order.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum total of the documents included in this posted payment order.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of all of the documents included in this posted payment order.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amounts left to pay for documents that are part of this posted payment order.';
                }
                field("Remaining Amount (LCY)"; "Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the pending amounts yet to be paid for the documents associated with this posted payment order.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901420407; "Post. PO Analysis LCY Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1903433407; "Post. PO Analysis Non LCY FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pmt. O&rd.")
            {
                Caption = 'Pmt. O&rd.';
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = "BG/PO No." = FIELD("No."),
                                  Type = FILTER(Payable);
                    ToolTip = 'View or create a comment.';
                }
                separator(Action21)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    RunObject = Page "Post. Payment Orders Analysis";
                    RunPageLink = "No." = FIELD("No."),
                                  "Due Date Filter" = FIELD("Due Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Category Filter" = FIELD("Category Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action24)
                {
                }
                action(Listing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Listing';
                    Ellipsis = true;
                    Image = List;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Find then begin
                            PostedPmtOrd.Copy(Rec);
                            PostedPmtOrd.SetRecFilter;
                            REPORT.Run(REPORT::"Posted Payment Order Listing", true, false, PostedPmtOrd);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            action("Page Posted Payment Orders Maturity Process")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Payment Orders Maturity';
                Image = DocumentsMaturity;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Posted Payment Orders Maturity";
                RunPageLink = "No." = FIELD("No."),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Category Filter" = FIELD("Category Filter");
                ToolTip = 'View the posted document lines that have matured. Maturity information can be viewed by period start date.';
            }
        }
    }

    var
        PostedPmtOrd: Record "Posted Payment Order";
}

