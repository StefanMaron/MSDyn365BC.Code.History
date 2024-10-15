page 5601 "Fixed Asset List"
{
    AdditionalSearchTerms = 'fa list';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Assets';
    CardPageID = "Fixed Asset Card";
    Editable = false;
    PageType = List;
    SourceTable = "Fixed Asset";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the vendor from which you purchased this fixed asset.';
                    Visible = false;
                }
                field("Maintenance Vendor No."; "Maintenance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vendor number for the vendor you use for repairs and maintenance of the fixed asset.';
                    Visible = false;
                }
                field("Responsible Employee"; "Responsible Employee")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which employee is responsible for the fixed asset.';
                }
                field("FA Class Code"; "FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a class code for the fixed asset.';
                }
                field("FA Subclass Code"; "FA Subclass Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a fixed asset subclass code, which can be used for subgrouping of fixed assets, for example, cars and machinery.';
                }
                field("FA Location Code"; "FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the location (within a building, for example) of the fixed asset.';
                }
                field("Budgeted Asset"; "Budgeted Asset")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the asset is for budgeting purposes.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the status of the fixed asset.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies a search description for the fixed asset.';
                }
                field("Depreciation Group"; "Depreciation Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation group to apply to this asset.';
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Fixed &Asset")
            {
                Caption = 'Fixed &Asset';
                Image = FixedAssets;
                action(Card)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';

                    trigger OnAction()
                    begin
                        case "FA Type" of
                            "FA Type"::"Future Expense":
                                PAGE.Run(PAGE::"Future Period Expense Card", Rec);
                            else
                                PAGE.Run(PAGE::"Fixed Asset Card", Rec);
                        end;
                    end;
                }
                action("Depreciation &Books")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation &Books';
                    Image = DepreciationBooks;
                    RunObject = Page "FA Depreciation Books";
                    RunPageLink = "FA No." = FIELD("No.");
                    ToolTip = 'View or edit the depreciation book or books that must be used for each of the fixed assets. Here you also specify the way depreciation must be calculated.';
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Fixed Asset Statistics";
                    RunPageLink = "FA No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Process;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(5600),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Process;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            FA: Record "Fixed Asset";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(FA);
                            DefaultDimMultiple.SetMultiRecord(FA, FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Main&tenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main&tenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Page "Maintenance Ledger Entries";
                    RunPageLink = "FA No." = FIELD("No.");
                    RunPageView = SORTING("FA No.");
                    ToolTip = 'View all the maintenance ledger entries for a fixed asset. The entries result from posting transactions in a purchase order, invoice, credit memo, or journal line.';
                }
                action(Picture)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Picture';
                    Image = Picture;
                    RunObject = Page "Fixed Asset Picture";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'Add or view a picture of the fixed asset.';
                }
                action("FA Posting Types Overview")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Types Overview';
                    Image = ShowMatrix;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "FA Posting Types Overview";
                    ToolTip = 'View accumulated amounts for each field, such as book value, acquisition cost, and depreciation, and for each fixed asset. For every fixed asset, a separate line is shown for each depreciation book linked to the asset.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Fixed Asset"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group("Main Asset")
            {
                Caption = 'Main Asset';
                Image = Components;
                action("M&ain Asset Components")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'M&ain Asset Components';
                    Image = Components;
                    RunObject = Page "Main Asset Components";
                    RunPageLink = "Main Asset No." = FIELD("No.");
                    ToolTip = 'View or edit lines, each representing one component of the main asset. The window shows only the components of the main asset that is related to the fixed asset card.';
                }
                action("Ma&in Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ma&in Asset Statistics';
                    Image = StatisticsDocument;
                    RunObject = Page "Main Asset Statistics";
                    RunPageLink = "FA No." = FIELD("No.");
                    ToolTip = 'View detailed historical information about all the components that make up the main asset.';
                }
                action("Create Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create Depreciation Book';
                    Image = DepreciationBooks;

                    trigger OnAction()
                    var
                        FA: Record "Fixed Asset";
                    begin
                        FA.Reset();
                        FA.SetRange("No.", "No.");
                        if FA.Find('-') then
                            REPORT.Run(REPORT::"Create FA Depreciation Books", true, true, FA);
                    end;
                }
                separator(Action45)
                {
                    Caption = '';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = FixedAssetLedger;
                    RunObject = Page "FA Ledger Entries";
                    RunPageLink = "FA No." = FIELD("No.");
                    RunPageView = SORTING("FA No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    RunObject = Page "FA Error Ledger Entries";
                    RunPageLink = "Canceled from FA No." = FIELD("No.");
                    RunPageView = SORTING("Canceled from FA No.")
                                  ORDER(Descending);
                    ToolTip = 'View the entries that have been posted as a result of you using the cancel function to cancel an entry.';
                }
                action("Maintenance &Registration")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance &Registration';
                    Image = MaintenanceRegistrations;
                    RunObject = Page "Maintenance Registration";
                    RunPageLink = "FA No." = FIELD("No.");
                    ToolTip = 'View or edit maintenance codes for the various types of maintenance, repairs, and services performed on your fixed assets. You can then enter the code in the Maintenance Code field on purchase documents or journals.';
                }
            }
        }
        area(processing)
        {
            action("Fixed Asset Journal")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Asset Journal';
                Image = Journal;
                RunObject = Page "Fixed Asset Journal";
                ToolTip = 'Post fixed asset transactions, such as acquisition and depreciation book without integration to the general ledger.';
            }
            action("Fixed Asset G/L Journal")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Asset G/L Journal';
                Image = Journal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Fixed Asset G/L Journal";
                ToolTip = 'Post fixed asset transactions with a depreciation book that is integrated with the general ledger for financial reporting. Both fixed asset ledger entries and general ledger entries are created. ';
            }
            action("Fixed Asset Reclassification Journal")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Asset Reclassification Journal';
                Image = Journal;
                RunObject = Page "FA Reclass. Journal";
                ToolTip = 'Transfer, split, or combine fixed assets.';
            }
            action("Recurring Fixed Asset Journal")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Recurring Fixed Asset Journal';
                Image = Journal;
                RunObject = Page "Recurring Fixed Asset Journal";
                ToolTip = 'Post recurring entries to a depreciation book without integration into general ledger.';
            }
            action("C&opy Fixed Asset")
            {
                ApplicationArea = FixedAssets;
                Caption = 'C&opy Fixed Asset';
                Ellipsis = true;
                Image = CopyFixedAssets;
                ToolTip = 'Create one or more new fixed asset by copying from existing fixed assets that have similar information, such as chairs or cars.';

                trigger OnAction()
                var
                    CopyFA: Report "Copy Fixed Asset";
                begin
                    CopyFA.SetFANo("No.");
                    CopyFA.RunModal();
                end;
            }
        }
        area(reporting)
        {
            action("Fixed Assets List")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Assets List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - List";
                ToolTip = 'View the list of fixed assets that exist in the system .';
            }
            action("Acquisition List")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Acquisition List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - Acquisition List";
                ToolTip = 'View the related acquisitions.';
            }
            action(Details)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Details';
                Image = View;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - Details";
                ToolTip = 'View detailed information about the fixed asset ledger entries that have been posted to a specified depreciation book for each fixed asset.';
            }
            action("Book Value 01")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Book Value 01';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 01";
                ToolTip = 'View detailed information about acquisition cost, depreciation and book value for both individual assets and groups of assets. For each of these three amount types, amounts are calculated at the beginning and at the end of a specified period as well as for the period itself.';
            }
            action("Book Value 02")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Book Value 02';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 02";
                ToolTip = 'View detailed information about acquisition cost, depreciation, appreciation, write-down and book value for both individual assets and groups of assets. For each of these categories, amounts are calculated at the beginning and at the end of a specified period, as well as for the period itself.';
            }
            action(Analysis)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Analysis';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for both individual assets and groups of assets.';
            }
            action("Projected Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Projected Value';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - Projected Value";
                ToolTip = 'View the calculated future depreciation and book value. You can print the report for one depreciation book at a time.';
            }
            action("G/L Analysis")
            {
                ApplicationArea = FixedAssets;
                Caption = 'G/L Analysis';
                Image = "Report";
                RunObject = Report "Fixed Asset - G/L Analysis";
                ToolTip = 'View an analysis of your fixed assets (FA) with various types of data for individual assets and/or groups of assets. On the Fixed Assets FastTab, you can set filters if you want the report to include only certain fixed assets. On the Options FastTab, you can choose among a number of options to tailor the report to meet your specific needs.';
            }
            action(Register)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Register';
                Image = Confirm;
                RunObject = Report "Fixed Asset Register";
                ToolTip = 'View registers containing all the fixed asset entries that are created. Every register shows the first and last entry number of its entries.';
            }
            action("FA Inventory Card FA-6")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Inventory Card FA-6';
                ToolTip = 'View the registration of fixed assets and operations, including the movement of fixed assets within the organization.';

                trigger OnAction()
                var
                    FA: Record "Fixed Asset";
                begin
                    FA.Get("No.");
                    FA.SetRecFilter;
                    REPORT.Run(REPORT::"FA Inventory Card FA-6", true, true, FA);
                end;
            }
            action("Calculate Depreciation")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Calculate Depreciation';
                Ellipsis = true;
                Image = CalculateDepreciation;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Report "Calculate Depreciation";
                ToolTip = 'Calculate depreciation according to conditions that you specify. If the related depreciation book is set up to integrate with the general ledger, then the calculated entries are transferred to the fixed asset general ledger journal. Otherwise, the calculated entries are transferred to the fixed asset journal. You can then review the entries and post the journal.';
            }
            separator(Action1210000)
            {
            }
            action("Precious Metals")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Precious Metals';
                Image = FixedAssets;
                RunObject = Page "Item/FA Precious Metal";
                RunPageLink = "Item Type" = CONST(FA),
                              "No." = FIELD("No.");
                ToolTip = 'View the list of fixed assets that are registered as precious metal.';
            }
            action("FA G/L Turnover")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA G/L Turnover';
                Image = Turnover;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "FA G/L Turnover";
                ToolTip = 'View the financial turnover as a result of fixed asset posting. General ledger entries are the basis for amounts shown in the window.';
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        FixedAsset: Record "Fixed Asset";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(FixedAsset);
        exit(SelectionFilterManagement.GetSelectionFilterForFixedAsset(FixedAsset));
    end;
}

