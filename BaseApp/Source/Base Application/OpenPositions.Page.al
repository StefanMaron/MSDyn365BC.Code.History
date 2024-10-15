page 17383 "Open Positions"
{
    Caption = 'Open Positions';
    Editable = false;
    PageType = Worksheet;
    SourceTable = Position;
    SourceTableTemporary = true;
    SourceTableView = WHERE("Budgeted Position" = CONST(false));

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Parent Position No."; "Parent Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Code"; "Job Title Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Title Name"; "Job Title Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Org. Unit Code"; "Org. Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Org. Unit Name"; "Org. Unit Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field(Rate; Rate)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Filled Rate"; "Filled Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category.';
                }
                field("Use Trial Period"; "Use Trial Period")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Liability for Breakage"; "Liability for Breakage")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Hire Conditions"; "Hire Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Kind of Work"; "Kind of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Conditions of Work"; "Conditions of Work")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc Group Code"; "Calc Group Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Position)
            {
                Caption = 'Position';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Position Card";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
                }
            }
        }
    }
}

