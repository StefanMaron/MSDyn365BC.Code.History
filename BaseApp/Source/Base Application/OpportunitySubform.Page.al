page 5125 "Opportunity Subform"
{
    Caption = 'Sales Cycle Stages';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Opportunity Entry";
    SourceTableView = SORTING("Opportunity No.")
                      ORDER(Descending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Active; Active)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the opportunity entry is active.';
                }
                field("Action Taken"; "Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the action that was taken when the entry was last updated. There are six options:';
                }
                field("Sales Cycle Stage"; "Sales Cycle Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the sales cycle stage currently of the opportunity.';
                }
                field("Sales Cycle Stage Description"; "Sales Cycle Stage Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Stage Description';
                    ToolTip = 'Specifies a description of the sales cycle that is related to the task. The description is copied from the sales cycle card.';
                }
                field("Date of Change"; "Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date this opportunity entry was last changed.';
                }
                field("Date Closed"; "Date Closed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the opportunity was closed.';
                    Visible = false;
                }
                field("Days Open"; "Days Open")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days that the opportunity entry was open.';
                    Visible = false;
                }
                field("Estimated Close Date"; "Estimated Close Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated date when the opportunity entry will be closed.';
                }
                field("Estimated Value (LCY)"; "Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity entry.';
                }
                field("Calcd. Current Value (LCY)"; "Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the calculated current value of the opportunity entry.';
                }
                field("Completed %"; "Completed %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the percentage of the sales cycle that has been completed for this opportunity entry.';
                }
                field("Chances of Success %"; "Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the chances of success of the opportunity entry.';
                }
                field("Probability %"; "Probability %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the probability of the opportunity resulting in a sale.';
                }
                field("Close Opportunity Code"; "Close Opportunity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code for closing the opportunity.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

