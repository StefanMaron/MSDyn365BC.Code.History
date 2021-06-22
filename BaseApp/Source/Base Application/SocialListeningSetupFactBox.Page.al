page 876 "Social Listening Setup FactBox"
{
    Caption = 'Social Media Insights Setup';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Social Listening Search Topic";

    layout
    {
        area(content)
        {
            field(InfoText; InfoText)
            {
                ApplicationArea = Suite;
                Caption = 'Search Topic';
                ToolTip = 'Specifies the search topic for social media insights.';

                trigger OnDrillDown()
                var
                    TempSocialListeningSearchTopic: Record "Social Listening Search Topic" temporary;
                begin
                    TempSocialListeningSearchTopic := Rec;
                    TempSocialListeningSearchTopic.Insert();
                    PAGE.RunModal(PAGE::"Social Listening Search Topic", TempSocialListeningSearchTopic);

                    if TempSocialListeningSearchTopic.Find and
                       (TempSocialListeningSearchTopic."Search Topic" <> '')
                    then begin
                        Validate("Search Topic", TempSocialListeningSearchTopic."Search Topic");
                        if not Modify then
                            Insert;
                        CurrPage.Update;
                    end else
                        if Delete then
                            Init;

                    SetInfoText;

                    CurrPage.Update(false);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetInfoText;
    end;

    var
        InfoText: Text;
        SetupRequiredTxt: Label 'Setup is required';

    local procedure SetInfoText()
    begin
        if "Search Topic" = '' then
            InfoText := SetupRequiredTxt
        else
            InfoText := "Search Topic";
    end;
}

