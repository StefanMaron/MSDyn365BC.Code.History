page 1512 "Notification Setup"
{
    ApplicationArea = Suite;
    Caption = 'Notification Setup';
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Notification Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Notification Type"; "Notification Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies what type of event the notification is about.';
                }
                field("Notification Method"; "Notification Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the notification method that is used to create notifications for the user.';
                }
                field(Schedule; Schedule)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the user receives notifications. The value is copied from the Recurrence field in the Notification Schedule window.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Notification Schedule")
            {
                ApplicationArea = Suite;
                Caption = 'Notification Schedule';
                Image = DateRange;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Notification Schedule";
                RunPageLink = "User ID" = FIELD("User ID"),
                              "Notification Type" = FIELD("Notification Type");
                ToolTip = 'Specify when the user receives notifications. The value is copied from the Recurrence field in the Notification Schedule window.';
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "User ID" := CleanWebFilter(GetFilter("User ID"));
    end;

    trigger OnOpenPage()
    begin
        if not HasFilter then
            SetRange("User ID", "User ID");
    end;

    local procedure CleanWebFilter(FilterString: Text): Text[50]
    begin
        exit(DelChr(FilterString, '=', '*|@|'''));
    end;
}

