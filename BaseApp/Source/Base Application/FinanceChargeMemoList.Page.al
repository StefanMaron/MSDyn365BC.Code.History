page 448 "Finance Charge Memo List"
{
    ApplicationArea = Suite;
    Caption = 'Finance Charge Memos';
    CardPageID = "Finance Charge Memo";
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Memo,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Finance Charge Memo Header";
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer you want to create a finance charge memo for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer the finance charge memo is for.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the finance charge memo.';
                }
                field("Interest Amount"; "Interest Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the total of the interest amounts on the finance charge memo lines.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the finance charge memo is for.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Memo")
            {
                Caption = '&Memo';
                Image = Notes;
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Fin. Charge Comment Sheet";
                    RunPageLink = Type = CONST("Finance Charge Memo"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                separator(Action8)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Finance Charge Memo Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Finance Charge Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Finance Charge Memos';
                    Ellipsis = true;
                    Image = CreateFinanceChargememo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create finance charge memos for one or more customers with overdue payments.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Finance Charge Memos");
                    end;
                }
                action("Suggest Fin. Charge Memo Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Fin. Charge Memo Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    ToolTip = 'Create finance charge memo lines in existing finance charge memos for any overdue payments based on information in the Finance Charge Memo window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Suggest Fin. Charge Memo Lines", true, false, FinChrgMemoHeader);
                        FinChrgMemoHeader.Reset();
                    end;
                }
                action("Update Finance Charge Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Finance Charge Text';
                    Ellipsis = true;
                    Image = RefreshText;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related finance charge terms with those from different terms.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Update Finance Charge Text", true, false, FinChrgMemoHeader);
                        FinChrgMemoHeader.Reset();
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        FinChrgMemoHeader.PrintRecords;
                        FinChrgMemoHeader.Reset();
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified finance charge entries according to your specifications in the Finance Charge Terms window. This specification determines whether interest and/or additional fees are posted to the customer''s account and the general ledger.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinChrgMemoHeader);
                        REPORT.RunModal(REPORT::"Issue Finance Charge Memos", true, true, FinChrgMemoHeader);
                        FinChrgMemoHeader.Reset();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Finance Charge Memo Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo Nos.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo Nos.";
                ToolTip = 'View or edit the finance charge memo numbers that are set up. ';
            }
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
    }

    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
}

