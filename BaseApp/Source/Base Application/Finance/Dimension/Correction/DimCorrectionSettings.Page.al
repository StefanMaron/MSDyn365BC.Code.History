namespace Microsoft.Finance.Dimension.Correction;

page 2582 "Dim Correction Settings"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Dimension Correction Settings';
    AdditionalSearchTerms = 'dimension correction setup';

    layout
    {
        area(Content)
        {
            part(DimCorrectionBlockedSetup; "Dim Correction Blocked Setup")
            {
                ApplicationArea = All;
                Caption = 'Dimensions Blocked For Correction';
            }
        }
    }
}