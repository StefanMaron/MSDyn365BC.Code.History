namespace Microsoft.FixedAssets.Insurance;

page 5646 "Insurance Statistics"
{
    Caption = 'Insurance Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Insurance;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Annual Premium"; Rec."Annual Premium")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount of the annual insurance premium.';
                }
                field("Policy Coverage"; Rec."Policy Coverage")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount of coverage provided by this insurance policy.';
                }
                field("Total Value Insured"; Rec."Total Value Insured")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total value of fixed assets linked to this insurance policy. This is the value of fixed assets for which insurance is required.';
                }
                field("""Policy Coverage"" - ""Total Value Insured"""; Rec."Policy Coverage" - Rec."Total Value Insured")
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Over/Under Insured';
                    ToolTip = 'Specifies if the fixed asset is insured at the right value.';
                }
            }
        }
    }

    actions
    {
    }
}

