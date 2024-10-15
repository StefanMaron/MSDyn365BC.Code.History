page 7000015 "Closed Bill Groups"
{
    Caption = 'Closed Bill Groups';
    DataCaptionExpression = Caption;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Closed Bill Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of this closed bill group.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number or code of the bank to which the closed bill group was submitted.';
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number associated with the code or number of the bank, to which the closed bill group was submitted.';
                }
                field("Dealing Type"; "Dealing Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of payment. Collection: The document will be sent to the bank for processing as a receivable. Discount: The document will be sent to the bank for processing as a prepayment discount. When a document is submitted for discount, the bill group bank advances the amount of the document (or a portion of it, in the case of invoices). Later, the bank is responsible for processing the collection of the document on the due date.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the closed bill group is a person or company.';
                }
                field(Factoring; Factoring)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the factoring method to be applied to the invoices of this bill group.';
                }
                field("Closing Date"; "Closing Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the closing date for the closed bill group.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code the bill group was generated in.';
                }
                field("Amount Grouped"; "Amount Grouped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount in this closed bill group.';
                }
                field("Amount Grouped (LCY)"; "Amount Grouped (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the grouped amount of this closed bill group.';
                }
            }
            part(Docs; "Docs. in Closed BG Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = CONST(Receivable),
                              "Collection Agent" = CONST(Bank),
                              "Bill Gr./Pmt. Order No." = FIELD("No.");
                SubPageView = SORTING(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
            }
            group(Expenses)
            {
                Caption = 'Expenses';
                field("Collection Expenses Amt."; "Collection Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of commission and charges for this closed bill group.';
                }
                field("Discount Expenses Amt."; "Discount Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of fees and commission to process the discounting of this closed bill group.';
                }
                field("Discount Interests Amt."; "Discount Interests Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total interest charged to discount the bills/invoices in this closed bill group.';
                }
                field("Rejection Expenses Amt."; "Rejection Expenses Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of expenses associated with the rejection of bills for this closed bill group.';
                }
                field("Risked Factoring Exp. Amt."; "Risked Factoring Exp. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the financial institution''s charges and commission for risked factoring.';
                }
                field("Unrisked Factoring Exp. Amt."; "Unrisked Factoring Exp. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the financial institution''s charges and commission for unrisked factoring.';
                }
            }
            group(Auditing)
            {
                Caption = 'Auditing';
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date of this closed bill group.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies why the entry is created. When reason codes are assigned to journal line or sales and purchase documents, all entries with a reason code will be marked during posting.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of copies printed of this closed bill group.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901421507; "Closed BG Analysis LCY FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1901421607; "Closed BG Analysis Non LCY FB")
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
                    RunPageLink = Type = FILTER(Receivable),
                                  "BG/PO No." = FIELD("No.");
                    ToolTip = 'View or create a comment.';
                }
                separator(Action25)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    RunObject = Page "Closed Bill Groups Analysis";
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
                    Image = List;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Find then begin
                            ClosedBillGr.Copy(Rec);
                            ClosedBillGr.SetRecFilter;
                            REPORT.Run(REPORT::"Closed Bill Group Listing", true, false, ClosedBillGr);
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
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
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
    }

    var
        ClosedBillGr: Record "Closed Bill Group";
        Navigate: Page Navigate;
}

