page 10147 "Posted Deposit List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Deposits';
    CardPageID = "Posted Deposit";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Deposit Header";
    UsageCategory = History;

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
                    ToolTip = 'Specifies the document number of the deposit document.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account to which the deposit was made.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date the deposit was posted.';
                }
                field("Total Deposit Amount"; "Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount deposited to the bank account.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                    Visible = false;
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting description of the deposit.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the bank account that the deposit was deposited in.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language code of the bank account that the deposit was deposited into.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Deposit")
            {
                Caption = '&Deposit';
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "No." = FIELD("No.");
                    RunPageView = WHERE("Table Name" = CONST("Posted Deposit"));
                    ToolTip = 'View a list of deposit comments.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
            }
        }
        area(reporting)
        {
            action(Deposit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deposit';
                Image = Document;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report Deposit;
                ToolTip = 'Create a new deposit. ';
            }
        }
    }
}

