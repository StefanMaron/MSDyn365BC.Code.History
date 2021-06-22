page 1052 "Reminder Terms Translation"
{
    Caption = 'Reminder Terms Translation';
    DataCaptionExpression = PageCaption;
    SourceTable = "Reminder Terms Translation";

    layout
    {
        area(content)
        {
            repeater(Control1004)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies translation of reminder terms so that customers are reminded in their own language.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Note About Line Fee on Report"; "Note About Line Fee on Report")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that any notes about line fees will be added to the reminder.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PageCaption := "Reminder Terms Code";
    end;

    var
        PageCaption: Text;
}

