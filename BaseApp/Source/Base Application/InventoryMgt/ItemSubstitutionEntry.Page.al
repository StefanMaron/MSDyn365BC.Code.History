page 5716 "Item Substitution Entry"
{
    Caption = 'Item Substitution Entry';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    RefreshOnActivate = false;
    SourceTable = "Item Substitution";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Substitute Type"; Rec."Substitute Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of the item that can be used as a substitute.';
                }
                field("Substitute No."; Rec."Substitute No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item that can be used as a substitute in case the original item is unavailable.';
                }
                field("Substitute Variant Code"; Rec."Substitute Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the variant that can be used as a substitute.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the description of the substitute item.';
                }
                field(Interchangeable; Interchangeable)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the item and the substitute item are interchangeable.';
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a condition exists for this substitution.';
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
        area(processing)
        {
            action("&Condition")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Condition';
                Image = ViewComments;
                RunObject = Page "Condition Entry";
                RunPageLink = Type = FIELD(Type),
                              "No." = FIELD("No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Substitute Type" = FIELD("Substitute Type"),
                              "Substitute No." = FIELD("Substitute No."),
                              "Substitute Variant Code" = FIELD("Substitute Variant Code");
                ToolTip = 'Specify a condition for the item substitution, which is for information only and does not affect the item substitution.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Condition_Promoted"; "&Condition")
                {
                }
            }
        }
    }
}

