page 439 "Issued Reminder Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Issued Reminder Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the customer ledger entry that this reminder line is for.';
                    Visible = false;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type of the customer ledger entry this reminder line is for.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the customer ledger entry this reminder line is for.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the customer ledger entry this reminder line is for.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies an entry description, based on the contents of the Type field.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original amount of the customer ledger entry that this reminder line is for.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = RemainingAmountEmphasize;
                    ToolTip = 'Specifies the remaining amount of the customer ledger entry this reminder line is for.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = AmountEmphasize;
                    ToolTip = 'Specifies the amount in the currency of the reminder.';
                    Visible = false;
                }
                field("Interest Amount"; "Interest Amount")
                {
                    ToolTip = 'Specifies the total of the interest amounts on the reminder lines.';
                }
                field("No. of Reminders"; "No. of Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reminder Level';
                    ToolTip = 'Specifies a number that indicates the reminder level.';
                    Visible = false;
                }
                field("Applies-To Document Type"; "Applies-To Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-To Document No."; "Applies-To Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat;
        RemainingAmountOnFormat;
        AmountOnFormat;
    end;

    var
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        RemainingAmountEmphasize: Boolean;
        [InDataSet]
        AmountEmphasize: Boolean;

    local procedure DescriptionOnFormat()
    begin
        if "Detailed Interest Rates Entry" then
            DescriptionIndent := 2;
        DescriptionEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure RemainingAmountOnFormat()
    begin
        RemainingAmountEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure AmountOnFormat()
    begin
        AmountEmphasize := not "Detailed Interest Rates Entry";
    end;
}

