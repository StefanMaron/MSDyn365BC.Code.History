page 10143 "Posted Deposit"
{
    Caption = 'Posted Deposit';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Deposit,Print/Send';
    SourceTable = "Posted Deposit Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the document number of the deposit document.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the bank account to which the deposit was made.';
                }
                field("Total Deposit Amount"; "Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount deposited to the bank account.';
                }
                field("Total Deposit Lines"; "Total Deposit Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the amounts in the Amount fields on the associated posted deposit lines.';
                }
                field(Difference; GetDifference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date the deposit was posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the bank account that the deposit was deposited in.';
                }
            }
            part(Subform; "Posted Deposit Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Deposit No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = false;
                Visible = true;
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = FIELD("Bank Account No."),
                                  "No." = FIELD("No.");
                    RunPageView = WHERE("Table Name" = CONST("Posted Deposit"));
                    ToolTip = 'View deposit comments that apply.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedDepositHeader: Record "Posted Deposit Header";
                begin
                    PostedDepositHeader.SetRange("No.", "No.");
                    REPORT.Run(REPORT::Deposit, true, false, PostedDepositHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    local procedure GetDifference(): Decimal
    begin
        CalcFields("Total Deposit Lines");
        exit("Total Deposit Amount" - "Total Deposit Lines");
    end;
}

