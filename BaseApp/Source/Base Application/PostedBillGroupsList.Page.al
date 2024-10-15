page 7000014 "Posted Bill Groups List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Bill Groups';
    CardPageID = "Posted Bill Groups";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Posted Bill Group";
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
                    ToolTip = 'Specifies the number of the posted bill group, which is assigned when you create the bill group.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank to which you submitted this posted bill group.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number associated with the code or number of the bank, to which the bill group was submitted.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the posted bill group.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total for all of the documents included in this bill group.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total for all of the documents included in this posted bill group.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for payment for the documents included in this posted bill group.';
                }
                field("Remaining Amount (LCY)"; "Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for collection, of the documents included in this bill group posted.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901420907; "Post. BG Analysis LCY Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1901421007; "Post. BG Analysis Non LCY FB")
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
            group("Bill &Group")
            {
                Caption = 'Bill &Group';
                Image = VoucherGroup;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = "BG/PO No." = FIELD("No."),
                                  Type = FILTER(Receivable);
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
                    RunObject = Page "Posted Bill Groups Analysis";
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
                            PostedBillGr.Copy(Rec);
                            PostedBillGr.SetRecFilter;
                            REPORT.Run(REPORT::"Posted Bill Group Listing", true, false, PostedBillGr);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            action("Posted Bill Groups Maturity")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Bill Groups Maturity';
                Image = DocumentsMaturity;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Posted Bill Groups Maturity";
                RunPageLink = "No." = FIELD("No."),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Category Filter" = FIELD("Category Filter");
                ToolTip = 'View the posted document lines that have matured. Maturity information can be viewed by period start date.';
            }
        }
    }

    var
        PostedBillGr: Record "Posted Bill Group";
}

