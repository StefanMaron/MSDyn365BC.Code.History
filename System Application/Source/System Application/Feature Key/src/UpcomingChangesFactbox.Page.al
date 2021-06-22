// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Factbox part page that enables a user to learn more about upcoming changes
/// </summary>
page 2611 "Upcoming Changes Factbox"
{
    PageType = CardPart;
    Caption = 'Preview upcoming changes';
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                ShowCaption = false;
                group(DescLine1)
                {
                    ShowCaption = false;
                    InstructionalText = 'Business Central offers previews of upcoming features and mandatory design changes to help you manage your business solution.';
                }
                group(DescLine2)
                {
                    ShowCaption = false;
                    InstructionalText = 'A feature selected for preview is visible to all users by default. You can choose to set the feature to be enabled for none.';
                }
                group(Links)
                {
                    ShowCaption = false;
                    InstructionalText = ' ';
                    field(LearnMoreNewFeatures; LearnMoreNewFeaturesLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreAboutPreviewProcessUrlTxt);
                        end;
                    }
                    field(ReleasePlan; ReleasePlanLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        trigger OnDrillDown()
                        begin
                            Hyperlink(ReleasePlanUrlTxt);
                        end;
                    }
                }
            }
        }
    }

    var
        LearnMoreNewFeaturesLbl: Label 'Learn more about the preview process.';
        ReleasePlanLbl: Label 'See the Release Plan';
        LearnMoreAboutPreviewProcessUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2112707', Locked = true;
        ReleasePlanUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2047422', Locked = true;
}