page 3731 "Product Video Topics"
{
    Caption = 'Setup Guide Topics';
    PageType = ListPart;
    SourceTableTemporary = true;
    SourceTable = Integer;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; TopicName)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        Video: Codeunit Video;
                    begin
                        Video.Show("Video Category".FromInteger(Number));
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Show Assisted Setup")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Show Assisted Setup';
                Tooltip = 'Get assistance with set-up.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Assisted Setup");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        i: Integer;
    begin
        foreach i in "Video Category".Ordinals() do
            // skip showing uncategoried videos- as this page should focus on meaningful topics for new users 
            if Format("Video Category".FromInteger(i)) <> Format("Video Category"::Uncategorized) then begin
                Init();
                Number := i;
                Insert();
            end;
    end;

    trigger OnAfterGetRecord()
    var
        VideoCategory: Enum "Video Category";
    begin
        VideoCategory := "Video Category".FromInteger(Number);
        TopicName := Format(VideoCategory);
    end;

    var
        TopicName: Text;
}