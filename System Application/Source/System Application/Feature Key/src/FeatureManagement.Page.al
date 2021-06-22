// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Page that enables a user to pick which new features to use
/// </summary>
page 2610 "Feature Management"
{
    PageType = List;
    Caption = 'Available Features and Changes';
    SourceTable = "Feature Key";
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(FeatureKeys)
            {
                field(FeatureDescription; Description)
                {
                    Caption = 'Change';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(LearnMore; LearnMoreLbl)
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink("Learn More Link");
                    end;
                }

                field(MandatoryBy; "Mandatory By")
                {
                    Caption = 'Mandatory by';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(EnabledFor; Enabled)
                {
                    Caption = 'Preview available for';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the users that the preview is available for. You must sign out and then sign in again for the change to take effect.';

                    trigger OnValidate()
                    begin
                        FeatureManagementImpl.SendSignInAgainNotification();
                    end;
                }

                field(TryItOut; TryItOut)
                {
                    Caption = 'Get Started';
                    ApplicationArea = All;
                    Editable = false;
                    Enabled = "Can Try";

                    trigger OnDrillDown()
                    begin
                        if "Can Try" then
                            HyperLink(FeatureManagementImpl.GetFeatureKeyUrlForWeb(ID));
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Upcoming Changes FactBox"; "Upcoming Changes Factbox")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if "Can Try" then
            TryItOut := TryItOutLbl
        else
            Clear(TryItOut);
    end;

    var
        FeatureManagementImpl: Codeunit "Feature Management Impl.";
        LearnMoreLbl: Label 'Learn more';
        TryItOutLbl: Label 'Try it out';
        TryItOut: Text;
}