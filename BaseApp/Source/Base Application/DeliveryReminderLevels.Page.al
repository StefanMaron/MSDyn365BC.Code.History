page 5005281 "Delivery Reminder Levels"
{
    Caption = 'Delivery Reminder Levels';
    DataCaptionFields = "Reminder Terms Code";
    PageType = List;
    SourceTable = "Delivery Reminder Level";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reminder terms code defined for this reminder level.';
                    Visible = "Reminder Terms CodeVisible";
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of this delivery reminder level.';
                }
                field("Due Date Calculation"; "Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that determines how the due date is calculated on the delivery reminder.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Level")
            {
                Caption = '&Level';
                Image = ReminderTerms;
                action("Beginning Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Beginning Text';
                    Image = BeginningText;
                    RunObject = Page "Delivery Reminder Text";
                    RunPageLink = "Reminder Terms Code" = FIELD("Reminder Terms Code"),
                                  "Reminder Level" = FIELD("No."),
                                  Position = CONST(Beginning);
                    ToolTip = 'Define a beginning text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
                action("Ending Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Text';
                    Image = EndingText;
                    RunObject = Page "Delivery Reminder Text";
                    RunPageLink = "Reminder Terms Code" = FIELD("Reminder Terms Code"),
                                  "Reminder Level" = FIELD("No."),
                                  Position = CONST(Ending);
                    ToolTip = 'Define an ending text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        DeliveryReminderTerms.SetFilter(Code, GetFilter("Reminder Terms Code"));
        ShowColumn := true;
        if DeliveryReminderTerms.FindFirst then begin
            DeliveryReminderTerms.SetRecFilter;
            if DeliveryReminderTerms.GetFilter(Code) = GetFilter("Reminder Terms Code") then
                ShowColumn := false;
        end;
        "Reminder Terms CodeVisible" := ShowColumn;
    end;

    var
        DeliveryReminderTerms: Record "Delivery Reminder Term";
        ShowColumn: Boolean;
        [InDataSet]
        "Reminder Terms CodeVisible": Boolean;
}

