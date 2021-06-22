page 5130 "Opportunity Entries"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Opportunity Entries';
    DataCaptionFields = "Contact No.", "Campaign No.", "Salesperson Code", "Sales Cycle Code", "Sales Cycle Stage", "Close Opportunity Code";
    Editable = false;
    PageType = List;
    SourceTable = "Opportunity Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Opportunity No."; "Opportunity No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the opportunity to which this entry applies.';
                }
                field("Action Taken"; "Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the action that was taken when the entry was last updated. There are six options:';
                }
                field(Active; Active)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the opportunity entry is active.';
                }
                field("Date of Change"; "Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date this opportunity entry was last changed.';
                }
                field("Date Closed"; "Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date that the opportunity was closed.';
                }
                field("Days Open"; "Days Open")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of days that the opportunity entry was open.';
                }
                field("Sales Cycle Code"; "Sales Cycle Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the sales cycle to which the opportunity is linked.';
                    Visible = false;
                }
                field("Sales Cycle Stage Description"; "Sales Cycle Stage Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies a description of the sales cycle that is related to the task. The description is copied from the sales cycle card.';
                }
                field("Previous Sales Cycle Stage"; "Previous Sales Cycle Stage")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales cycle stage of the opportunity before this entry.';
                    Visible = false;
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
            action("Show Opportunity Card")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Show Opportunity Card';
                Image = Opportunity;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Opportunity Card";
                RunPageLink = "No." = FIELD("Opportunity No.");
                RunPageMode = View;
                Scope = Repeater;
                ToolTip = 'Open the card for the opportunity.';
            }
            action("Delete Closed")
            {
                ApplicationArea = All;
                Caption = 'Delete Closed Entries';
                Image = Delete;
                RunObject = Report "Delete Opportunities";
                ToolTip = 'Find and delete closed opportunity entries.';
            }
        }
    }
}

