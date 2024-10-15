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
                field("Employee No. Mandatory"; "Employee No. Mandatory")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the employee number is mandatory for the fixed asset setup information.';
                }
                field("FA Location Mandatory"; "FA Location Mandatory")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the fixed asset location is mandatory for the fixed asset setup information.';
                }
                field("Release Depr. Book"; "Release Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the release depreciation book associated with the fixed asset setup information.';
                }
                field("Disposal Depr. Book"; "Disposal Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the disposal depreciation book associated with the fixed asset setup information.';
                }
                field("Quantitative Depr. Book"; "Quantitative Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantitative depreciation book associated with the fixed asset setup information.';
                }
                field("Future Depr. Book"; "Future Depr. Book")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the future depreciation book associated with the fixed asset setup information.';
                }
                field("On Disposal Maintenance Code"; "On Disposal Maintenance Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the on disposal maintenance code associated with the fixed asset setup information.';
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
                field("Writeoff Nos."; "Writeoff Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Release Nos."; "Release Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Disposal Nos."; "Disposal Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Posted Writeoff Nos."; "Posted Writeoff Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Posted Release Nos."; "Posted Release Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
                field("Posted Disposal Nos."; "Posted Disposal Nos.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new records.';
                }
            }
            group("Assessed Tax")
            {
                Caption = 'Assessed Tax';
                field("AT Declaration Template Code"; "AT Declaration Template Code")
                {
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("AT Advance Template Code"; "AT Advance Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field(KBK; KBK)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the budget classification code associated with the fixed asset setup information.';
                }
                field("KBK (UGSS)"; "KBK (UGSS)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the budget classification code for the united gas supply system associated with the fixed asset setup information.';
                }
            }
            group(Templates)
            {
                Caption = 'Templates';
                field("INV-1 Template Code"; "INV-1 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("INV-1a Template Code"; "INV-1a Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("INV-11 Template Code"; "INV-11 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("INV-18 Template Code"; "INV-18 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-1 Template Code"; "FA-1 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("M-2a Template Code"; "M-2a Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-2 Template Code"; "FA-2 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-14 Template Code"; "FA-14 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-3 Template Code"; "FA-3 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-4 Template Code"; "FA-4 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-4a Template Code"; "FA-4a Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-6 Template Code"; "FA-6 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("FA-15 Template Code"; "FA-15 Template Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
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
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000H4E', 'Fixed Asset Setup', Enum::"Feature Uptake Status"::Discovered);
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

