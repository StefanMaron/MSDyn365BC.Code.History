page 5600 "Fixed Asset Card"
{
    Caption = 'Fixed Asset Card';
    PageType = ListPlus;
    Permissions = TableData "FA Depreciation Book" = rim;
    RefreshOnActivate = true;
    SourceTable = "Fixed Asset";
    SourceTableView = SORTING("FA Type")
                      WHERE("FA Type" = FILTER("Fixed Assets" | "Intangible Asset"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the fixed asset''s serial number.';
                }
                field("Inventory Number"; "Inventory Number")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the fixed asset''s inventory number.';
                }
                field("Factory No."; "Factory No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the factory number that defines the location of the fixed asset.';
                }
                field("Passport No."; "Passport No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the passport number of the manufacturer or distributor of the fixed asset.';
                }
                field(Manufacturer; Manufacturer)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the manufacturer of the vehicle associated with the fixed asset.';
                }
                field("Manufacturing Year"; "Manufacturing Year")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the year the fixed asset was manufactured.';
                }
                field("FA Type"; "FA Type")
                {
                    ApplicationArea = FixedAssets;
                    OptionCaption = 'Fixed Assets,Intangible Asset';
                    ToolTip = 'Specifies the type of asset.';
                }
                field("CD No."; "CD No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a search description for the fixed asset.';
                }
                field("Responsible Employee"; "Responsible Employee")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies which employee is responsible for the fixed asset.';
                }
                field(Inactive; Inactive)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies that the fixed asset is inactive (for example, if the asset is not in service or is obsolete).';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies when the fixed asset card was last modified.';
                }
                field(Status; Status)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the status of the fixed asset.';
                }
                field("Initial Release Date"; "Initial Release Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date that the fixed asset was first released.';
                }
                field("Status Document No."; "Status Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number assigned to the document that changed the value of the Status field after the document was posted.';
                }
            }
            part(DepreciationBook; "FA Depreciation Books Subform")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "FA No." = FIELD("No.");
            }
            group(Classification)
            {
                Caption = 'Classification';
                field("FA Class Code"; "FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies a class code for the fixed asset.';
                }
                field("FA Subclass Code"; "FA Subclass Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies a fixed asset subclass code, which can be used for subgrouping of fixed assets, for example, cars and machinery.';
                }
                field("FA Location Code"; "FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the location (within a building, for example) of the fixed asset.';
                }
                field("Budgeted Asset"; "Budgeted Asset")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the asset is for budgeting purposes.';
                }
                field("Tax Difference Code"; "Tax Difference Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Maintenance)
            {
                Caption = 'Maintenance';
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor from which you purchased this fixed asset.';
                }
                field("Maintenance Vendor No."; "Maintenance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor number for the vendor you use for repairs and maintenance of the fixed asset.';
                }
                field("Under Maintenance"; "Under Maintenance")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether the fixed asset is currently being repaired.';
                }
                field("Next Service Date"; "Next Service Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the next scheduled service date for the fixed asset. This is used as a filter in the Maintenance - Next Service report.';
                }
                field("Last Renovation Date"; "Last Renovation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date of the last renovation associated with the fixed asset.';
                }
                field("Warranty Date"; "Warranty Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the warranty expiration date of the fixed asset.';
                }
                field(Insured; Insured)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the fixed asset is linked to an insurance policy.';
                }
            }
            group(Depreciation)
            {
                Caption = 'Depreciation';
                field("Depreciation Group"; "Depreciation Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation group to apply to this asset.';
                }
                field("Depreciation Code"; "Depreciation Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation code to apply to this asset.';
                }
                field("Belonging to Manufacturing"; "Belonging to Manufacturing")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how the fixed asset is used in manufacturing.';
                }
                field("Undepreciable FA"; "Undepreciable FA")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if you can repay fixed assets with the whole amount of their acquisition at the time of their release.';
                }
            }
            group(Components)
            {
                Caption = 'Components';
                field("Main Asset/Component"; "Main Asset/Component")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the asset is a main asset or a component of a main asset.';
                }
                field("Component of Main Asset"; "Component of Main Asset")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the main asset that this asset is a component of, or the number of the asset itself, if the asset is a main asset.';
                }
            }
            group(Vehicle)
            {
                Caption = 'Vehicle';
                field("Vehicle Identification Number"; "Vehicle Identification Number")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle identification number associated with the fixed asset.';
                }
                field("Vehicle Model"; "Vehicle Model")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle model associated with the fixed asset.';
                }
                field("Vehicle Type"; "Vehicle Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle type associated with the fixed asset.';
                }
                field("Vehicle Reg. No."; "Vehicle Reg. No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle registration number associated with the fixed asset.';
                }
                field("Vehicle Class"; "Vehicle Class")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle class associated with the fixed asset.';
                }
                field("Vehicle Engine No."; "Vehicle Engine No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle engine number associated with the fixed asset.';
                }
                field("Vehicle Chassis No."; "Vehicle Chassis No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle chassis number associated with the fixed asset.';
                }
                field("Vehicle Capacity"; "Vehicle Capacity")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle capacity associated with the fixed asset.';
                }
                field("Vehicle Passport Weight"; "Vehicle Passport Weight")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle passport weight associated with the fixed asset.';
                }
                field("Run after Release Date"; "Run after Release Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the run after release date associated with the fixed asset.';
                }
                field("Run after Renovation Date"; "Run after Renovation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the run after renovation date associated with the fixed asset.';
                }
                field("Vehicle Writeoff Date"; "Vehicle Writeoff Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date this vehicle is taken out of service.';
                }
            }
            group("Assessed Tax")
            {
                Caption = 'Assessed Tax';
                field("Assessed Tax Code"; "Assessed Tax Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the assessed tax code associated with the fixed asset.';
                }
                field("Property Type"; "Property Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the property type of the fixed asset.';
                }
                field("Book Value per Share"; "Book Value per Share")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the book value of the fixed asset, per share.';
                }
                field("OKATO Code"; "OKATO Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the region where the current fixed asset is situated.';
                }
                field("Tax Amount Paid Abroad"; "Tax Amount Paid Abroad")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount of tax that was paid abroad for the fixed asset.';
                }
            }
            group(Control1904423301)
            {
                Caption = 'History';
                field("Accrued Depr. Amount"; "Accrued Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the accrued depreciation amount of the fixed asset.';
                }
                field("Operation Life (Months)"; "Operation Life (Months)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the operation life of the fixed asset.';
                }
                group(Control38)
                {
                    ShowCaption = false;
                }
            }
        }
        area(factboxes)
        {
            part(FixedAssetPicture; "Fixed Asset Picture")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Asset Picture';
                SubPageLink = "No." = FIELD("No.");
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(5600),
                              "No." = FIELD("No.");
            }
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
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5600),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Maintenance &Registration")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance &Registration';
                    Image = MaintenanceRegistrations;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Maintenance Registration";
                    RunPageLink = "FA No." = FIELD("No.");
                    ToolTip = 'View or edit the date and description regarding the maintenance of the fixed asset.';
                }
                action("FA Posting Types Overview")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Types Overview';
                    Image = ShowMatrix;
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
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal;
                    end;
                }
            }
            group("Main Asset")
            {
                Caption = 'Main Asset';
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
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                separator(Action39)
                {
                    Caption = '';
                }
            }
            group(Insurance)
            {
                Caption = 'Insurance';
                Image = TotalValueInsured;
                action("Total Value Ins&ured")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Value Ins&ured';
                    Image = TotalValueInsured;
                    RunObject = Page "Total Value Insured";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View the amounts that you posted to each insurance policy for the fixed asset. The entries in this window correspond to all of the entries in the Coverage Ledger Entry table for the fixed asset. The amounts shown can be more or less than the actual insurance policy coverage. The amounts shown can differ from the actual book value of the asset.';
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
                separator(Action1210012)
                {
                }
                action("Precious Metal")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Precious Metal';
                    Image = FixedAssets;
                    RunObject = Page "Item/FA Precious Metal";
                    RunPageLink = "Item Type" = CONST(FA),
                                  "No." = FIELD("No.");
                    ToolTip = 'View the list of fixed assets that are registered as precious metal.';
                }
                action("Ta&x Differences Detailed")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ta&x Differences Detailed';
                    Image = TaxDetail;
                    ToolTip = 'View the tax difference detailed entries that are associated with the archived general journal line.';

                    trigger OnAction()
                    begin
                        ShowTaxDifferences;
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Create FA Depreciation Books")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create FA Depreciation Books';
                    Image = NewDepreciationBook;

                    trigger OnAction()
                    begin
                        FA.Get("No.");
                        REPORT.Run(REPORT::"Create FA Depreciation Books", true, true, FA);
                    end;
                }
            }
            action(CalculateDepreciation)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Calculate Depreciation';
                Image = CalculateDepreciation;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Calculate depreciation according to the conditions that you define. If the fixed assets that are included in the batch job are integrated with the general ledger (defined in the depreciation book that is used in the batch job), the resulting entries are transferred to the fixed assets general ledger journal. Otherwise, the batch job transfers the entries to the fixed asset journal. You can then post the journal or adjust the entries before posting, if necessary.';

                trigger OnAction()
                var
                    FixedAsset: Record "Fixed Asset";
                begin
                    FixedAsset.SetRange("No.", "No.");
                    REPORT.RunModal(REPORT::"Calculate Depreciation", true, false, FixedAsset);
                end;
            }
            action("C&opy Fixed Asset")
            {
                ApplicationArea = FixedAssets;
                Caption = 'C&opy Fixed Asset';
                Ellipsis = true;
                Image = CopyFixedAssets;
                ToolTip = 'View or edit fixed asset components of the main fixed asset that is represented by the fixed asset card.';

                trigger OnAction()
                var
                    CopyFA: Report "Copy Fixed Asset";
                begin
                    CopyFA.SetFANo("No.");
                    CopyFA.RunModal;
                end;
            }
        }
        area(reporting)
        {
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
                ToolTip = 'View detailed information about acquisition cost, depreciation and book value for both individual fixed assets and groups of fixed assets. For each of these three amount types, amounts are calculated at the beginning and at the end of a specified period as well as for the period itself.';
            }
            action("Book Value 02")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Book Value 02';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 02";
                ToolTip = 'View detailed information about acquisition cost, depreciation, appreciation, write-down and book value for both individual fixed assets and groups of fixed assets. For each of these categories, amounts are calculated at the beginning and at the end of a specified period, as well as for the period itself.';
            }
            action(Analysis)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Analysis';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Fixed Asset - Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for both individual fixed assets and groups of fixed assets.';
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
                ToolTip = 'View an analysis of your fixed assets with various types of data for individual fixed assets and/or groups of fixed assets.';
            }
            action(Register)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Register';
                Image = Confirm;
                RunObject = Report "Fixed Asset Register";
                ToolTip = 'View registers containing all the fixed asset entries that are created. Each register shows the first and last entry number of its entries.';
            }
            action("Report FA Inventory Card FA-6")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Inventory Card FA-6';
                Image = "Report";

                trigger OnAction()
                begin
                    FA.Get("No.");
                    FA.SetRecFilter;
                    REPORT.Run(REPORT::"FA Inventory Card FA-6", true, true, FA);
                end;
            }
            action("FA G/L Turnover")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA G/L Turnover';
                Image = Turnover;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Page "FA G/L Turnover";
            }
        }
    }

    var
        FA: Record "Fixed Asset";
}

