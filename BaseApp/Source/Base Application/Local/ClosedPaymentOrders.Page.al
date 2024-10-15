page 7000060 "Closed Payment Orders"
{
    Caption = 'Closed Payment Orders';
    DataCaptionExpression = Caption();
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Closed Payment Order";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number related to this closed payment order.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number or code of the bank where this closed payment order was delivered.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name associated with the bank code or bank number where the closed payment order was delivered.';
                }
                field("Closing Date"; Rec."Closing Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the closing date for this closed payment order.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code in which the payment order was generated.';
                }
                field("Amount Grouped"; Rec."Amount Grouped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount for this closed payment order.';
                }
                field("Amount Grouped (LCY)"; Rec."Amount Grouped (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the grouped amount for this closed payment order.';
                }
            }
            part(Docs; "Docs. in Closed PO Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = CONST(Payable),
                              "Collection Agent" = CONST(Bank),
                              "Bill Gr./Pmt. Order No." = FIELD("No.");
                SubPageView = SORTING(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
            }
            group(Expenses)
            {
                Caption = 'Expenses';
                field("Payment Order Expenses Amt."; Rec."Payment Order Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of payable document expenses for this closed payment order.';
                }
            }
            group(Auditing)
            {
                Caption = 'Auditing';
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when this closed payment order was posted.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies why the entry is created. When reason codes are assigned to journal line or sales and purchase documents, all entries with a reason code will be marked during posting.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of printed copies of this closed payment order.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903433507; "Closed PO Analysis LCY FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1903433207; "Closed PO Analysis Non LCY FB")
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
                                  Type = CONST(Payable);
                    ToolTip = 'View or create a comment.';
                }
                separator(Action25)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Enabled = true;
                    Image = "Report";
                    RunObject = Page "Closed Pmt. Ord. Analysis";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action45)
                {
                }
                action(Listing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Listing';
                    Ellipsis = true;
                    Enabled = true;
                    Image = List;
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Find() then begin
                            ClosedPmtOrd.Copy(Rec);
                            ClosedPmtOrd.SetRecFilter();
                            REPORT.Run(REPORT::"Closed Payment Order Listing", true, false, ClosedPmtOrd);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Enabled = true;
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Option: Integer;
                begin
                    Navigate.SetDoc("Posting Date", "No.");
                    Navigate.Run();
                end;
            }
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Listing_Promoted; Listing)
                {
                }
            }
        }
    }

    var
        ClosedPmtOrd: Record "Closed Payment Order";
        Navigate: Page Navigate;
}

