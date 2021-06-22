page 871 "Social Listening Search Topic"
{
    Caption = 'Social Media Search Topic';
    DataCaptionExpression = GetCaption;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Social Listening Search Topic";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control5)
                {
                    InstructionalText = 'Create a search topic in Microsoft Social Engagement and paste the search topic ID or URL into the Search Topic ID field.';
                    ShowCaption = false;
                    field(SetupSearchTopicLbl; SetupSearchTopicLbl)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            HyperLink(SocialListeningMgt.MSLSearchItemsURL);
                        end;
                    }
                }
                field("Search Topic"; "Search Topic")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the Search Topic ID that refers to the search topic created in Microsoft Social Listening.';
                }
            }
        }
    }

    actions
    {
    }

    var
        SocialListeningMgt: Codeunit "Social Listening Management";
        SetupSearchTopicLbl: Label 'Set up search topic.';
}

