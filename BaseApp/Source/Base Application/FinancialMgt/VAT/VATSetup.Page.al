page 187 "VAT Setup"
{
    DeleteAllowed = false;
    PageType = Card;
    SourceTable = "VAT Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Enable Non-Deductible VAT"; Rec."Enable Non-Deductible VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Non-Deductible VAT feature is enabled.';
                }
            }
            group(NonDeductibleVAT)
            {
                Caption = 'Non-Deductible VAT';
                Visible = "Enable Non-Deductible VAT";

                field(UseForItemCost; Rec."Use For Item Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the item cost.';
                }
                field(UseForFixedAssetCost; Rec."Use For Fixed Asset Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the fixed asset cost.';
                }
                field(UseForJobCost; Rec."Use For Job Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be added to the job cost.';
                }
                field("Show Non-Ded. VAT In Lines"; Rec."Show Non-Ded. VAT In Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the non-deductible VAT must be shown in document lines pages.';
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}

