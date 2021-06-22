page 5607 "Fixed Asset Setup"
{
    AdditionalSearchTerms = 'fa setup';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,General,Depreciation,Posting,Journal Templates';
    SourceTable = "FA Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Default Depr. Book"; "Default Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the default depreciation book on journal lines and purchase lines and when you run batch jobs and reports.';
                }
                field("Allow Posting to Main Assets"; "Allow Posting to Main Assets")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether you have split your fixed assets into main assets and components, and you want to be able to post directly to main assets.';
                }
                field("Allow FA Posting From"; "Allow FA Posting From")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the earliest date when posting to the fixed assets is allowed.';
                }
                field("Allow FA Posting To"; "Allow FA Posting To")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the latest date when posting to the fixed assets is allowed.';
                }
                field("Insurance Depr. Book"; "Insurance Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies a depreciation book code. If you use the insurance facilities, you must enter a code to post insurance coverage ledger entries.';
                }
                field("Automatic Insurance Posting"; "Automatic Insurance Posting")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies you want to post insurance coverage ledger entries when you post acquisition cost entries with the Insurance No. field filled in.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Fixed Asset Nos."; "Fixed Asset Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to fixed assets.';
                }
                field("Insurance Nos."; "Insurance Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to insurance policies.';
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
            action("Depreciation Books")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Books';
                Image = DepreciationBooks;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Depreciation Book List";
                ToolTip = 'Set up depreciation books for various depreciation purposes, such as tax and financial statements.';
            }
            action("Depreciation Tables")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Tables';
                Image = "Table";
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                RunObject = Page "Depreciation Table List";
                ToolTip = 'Set up the different depreciation methods that you will use to depreciate fixed assets.';
            }
            action("FA Classes")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Classes';
                Image = FARegisters;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "FA Classes";
                ToolTip = 'Set up different asset classes, such as Tangible Assets and Intangible Assets, to group your fixed assets by categories.';
            }
            action("FA Subclasses")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Subclasses';
                Image = FARegisters;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "FA Subclasses";
                ToolTip = 'Set up different asset subclasses, such as Plant and Property and Machinery and Equipment, that you can assign to fixed assets and insurance policies.';
            }
            action("FA Locations")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Locations';
                Image = FixedAssets;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "FA Locations";
                ToolTip = 'Set up different locations, such as a warehouse or a location within a warehouse, that you can assign to fixed assets.';
            }
            group(Posting)
            {
                Caption = 'Posting';
                action("FA Posting Type Setup")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Type Setup';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "FA Posting Type Setup";
                    ToolTip = 'Define how to handle the Write-Down, Appreciation, Custom 1, and Custom 2 posting types that you use when posting to fixed assets.';
                }
                action("FA Posting Groups")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Groups';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "FA Posting Groups";
                    ToolTip = 'Set up the accounts to which transactions are posted for fixed assets for each posting group, so that you can assign them to the relevant fixed assets.';
                }
                action("FA Journal Templates")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Journal Templates';
                    Image = JournalSetup;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "FA Journal Templates";
                    ToolTip = 'Set up number series and reason codes in the journals that you use for fixed asset posting. By using different templates you can design windows with different layouts and you can assign trace codes, number series, and reports to each template.';
                }
                action("FA Reclass. Journal Templates")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Reclass. Journal Templates';
                    Image = JournalSetup;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "FA Reclass. Journal Templates";
                    ToolTip = 'Set up number series and reason codes in the journal that you use to reclassify fixed assets. By using different templates you can design windows with different layouts and you can assign trace codes, number series, and reports to each template.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

