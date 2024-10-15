namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;

page 5611 "Depreciation Book List"
{
    ApplicationArea = FixedAssets;
    Caption = 'Depreciation Books';
    CardPageID = "Depreciation Book Card";
    Editable = false;
    PageType = List;
    SourceTable = "Depreciation Book";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a code that identifies the depreciation book.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the purpose of the depreciation book.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Depr. Book")
            {
                Caption = '&Depr. Book';
                action("FA Posting Type Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Type Setup';
                    Image = Setup;
                    RunObject = Page "FA Posting Type Setup";
                    RunPageLink = "Depreciation Book Code" = field(Code);
                    ToolTip = 'Set up how to handle the write-down, appreciation, custom 1, and custom 2 posting types that you use when posting to fixed assets.';
                }
                action("FA &Journal Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA &Journal Setup';
                    Image = JournalSetup;
                    RunObject = Page "FA Journal Setup";
                    RunPageLink = "Depreciation Book Code" = field(Code);
                    ToolTip = 'Set up the FA general ledger journal, the FA journal, and the insurance journal templates and batches to use when duplicating depreciation entries and acquisition-cost entries and when calculating depreciation or indexing fixed assets.';
                }
            }
        }
    }
}

