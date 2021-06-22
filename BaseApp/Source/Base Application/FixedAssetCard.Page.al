page 5600 "Fixed Asset Card"
{
    Caption = 'Fixed Asset Card';
    PageType = Document;
    Permissions = TableData "FA Depreciation Book" = rim;
    RefreshOnActivate = true;
    SourceTable = "Fixed Asset";

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
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;

                    trigger OnValidate()
                    begin
                        ShowAcquireNotification
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the fixed asset.';

                    trigger OnValidate()
                    begin
                        ShowAcquireNotification
                    end;
                }
                group(Control34)
                {
                    ShowCaption = false;
                    field("FA Class Code"; "FA Class Code")
                    {
                        ApplicationArea = FixedAssets;
                        Importance = Promoted;
                        ToolTip = 'Specifies the class that the fixed asset belongs to.';
                    }
                    field("FA Subclass Code"; "FA Subclass Code")
                    {
                        ApplicationArea = FixedAssets;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the subclass of the class that the fixed asset belongs to.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            FASubclass: Record "FA Subclass";
                        begin
                            if "FA Class Code" <> '' then
                                FASubclass.SetFilter("FA Class Code", '%1|%2', '', "FA Class Code");

                            if FASubclass.Get("FA Subclass Code") then;
                            if PAGE.RunModal(0, FASubclass) = ACTION::LookupOK then begin
                                Text := FASubclass.Code;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            SetDefaultDepreciationBook;
                            SetDefaultPostingGroup;
                            ShowAcquireNotification;
                        end;
                    }
                }
                field("FA Location Code"; "FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field("Budgeted Asset"; "Budgeted Asset")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies if the asset is for budgeting purposes.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the fixed asset''s serial number.';
                }
                field("Main Asset/Component"; "Main Asset/Component")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies if the fixed asset is a main fixed asset or a component of a fixed asset.';
                }
                field("Component of Main Asset"; "Component of Main Asset")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the main fixed asset.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a search description for the fixed asset.';
                }
                field("Responsible Employee"; "Responsible Employee")
                {
                    ApplicationArea = FixedAssets;
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
                field(Acquired; Acquired)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies if the fixed asset has been acquired.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies when the fixed asset card was last modified.';
                }
            }
            group("Depreciation Book")
            {
                Caption = 'Depreciation Book';
                Visible = Simple;
                field(DepreciationBookCode; FADepreciationBook."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Book Code';
                    Importance = Additional;
                    TableRelation = "Depreciation Book";
                    ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';

                    trigger OnValidate()
                    begin
                        LoadDepreciationBooks;
                        FADepreciationBook.Validate("Depreciation Book Code");
                        SaveSimpleDepriciationBook(xRec."No.");
                        ShowAcquireNotification;
                    end;
                }
                field(FAPostingGroup; FADepreciationBook."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posting Group';
                    Importance = Additional;
                    TableRelation = "FA Posting Group";
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';

                    trigger OnValidate()
                    begin
                        LoadDepreciationBooks;
                        FADepreciationBook.Validate("FA Posting Group");
                        SaveSimpleDepriciationBook(xRec."No.");
                        ShowAcquireNotification;
                    end;
                }
                field(DepreciationMethod; FADepreciationBook."Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Method';
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';

                    trigger OnValidate()
                    begin
                        LoadDepreciationBooks;
                        FADepreciationBook.Validate("Depreciation Method");
                        SaveSimpleDepriciationBook(xRec."No.");
                        ShowAcquireNotification;
                    end;
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(DepreciationStartingDate; FADepreciationBook."Depreciation Starting Date")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Starting Date';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';

                        trigger OnValidate()
                        begin
                            LoadDepreciationBooks;
                            FADepreciationBook.Validate("Depreciation Starting Date");
                            SaveSimpleDepriciationBook(xRec."No.");
                            ShowAcquireNotification;
                        end;
                    }
                    field(NumberOfDepreciationYears; FADepreciationBook."No. of Depreciation Years")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'No. of Depreciation Years';
                        ToolTip = 'Specifies the length of the depreciation period, expressed in years.';

                        trigger OnValidate()
                        begin
                            LoadDepreciationBooks;
                            FADepreciationBook.Validate("No. of Depreciation Years");
                            SaveSimpleDepriciationBook(xRec."No.");
                            ShowAcquireNotification;
                        end;
                    }
                    field(DepreciationEndingDate; FADepreciationBook."Depreciation Ending Date")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Ending Date';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';

                        trigger OnValidate()
                        begin
                            LoadDepreciationBooks;
                            FADepreciationBook.Validate("Depreciation Ending Date");
                            SaveSimpleDepriciationBook(xRec."No.");
                            ShowAcquireNotification;
                        end;
                    }
                }
                field(BookValue; BookValue)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the book value for the fixed asset.';

                    trigger OnDrillDown()
                    begin
                        FADepreciationBook.DrillDownOnBookValue;
                    end;
                }
                field(DepreciationTableCode; FADepreciationBook."Depreciation Table Code")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Table Code';
                    Importance = Additional;
                    TableRelation = "Depreciation Table Header";
                    ToolTip = 'Specifies the code of the depreciation table to use if you have selected the User-Defined option in the Depreciation Method field.';

                    trigger OnValidate()
                    begin
                        LoadDepreciationBooks;
                        FADepreciationBook.Validate("Depreciation Table Code");
                        SaveSimpleDepriciationBook(xRec."No.");
                    end;
                }
                field(UseHalfYearConvention; FADepreciationBook."Use Half-Year Convention")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Use Half-Year Convention';
                    Importance = Additional;
                    ToolTip = 'Specifies that the Half-Year Convention is to be applied to the selected depreciation method.';

                    trigger OnValidate()
                    begin
                        LoadDepreciationBooks;
                        FADepreciationBook.Validate("Use Half-Year Convention");
                        SaveSimpleDepriciationBook(xRec."No.");
                    end;
                }
                group(Control38)
                {
                    ShowCaption = false;
                    Visible = ShowAddMoreDeprBooksLbl;
                    field(AddMoreDeprBooks; AddMoreDeprBooksLbl)
                    {
                        ApplicationArea = FixedAssets;
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;

                        trigger OnDrillDown()
                        begin
                            Simple := not Simple;
                        end;
                    }
                }
            }
            part(DepreciationBook; "FA Depreciation Books Subform")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Books';
                SubPageLink = "FA No." = FIELD("No.");
                Visible = NOT Simple;
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
                    ToolTip = 'Specifies the number of the vendor who performs repairs and maintenance on the fixed asset.';
                }
                field("Under Maintenance"; "Under Maintenance")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the fixed asset is currently being repaired.';
                }
                field("Next Service Date"; "Next Service Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the next scheduled service date for the fixed asset. This is used as a filter in the Maintenance - Next Service report.';
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
                    ToolTip = 'View or edit fixed asset components of the main fixed asset that is represented by the fixed asset card.';
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
                    ToolTip = 'View the amounts that you posted to each insurance policy for the fixed asset. The amounts shown can be more or less than the actual insurance policy coverage. The amounts shown can differ from the actual book value of the asset.';
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
                    ToolTip = 'View the entries that have been posted as a result of you using the Cancel function to cancel an entry.';
                }
                action("Main&tenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main&tenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Page "Maintenance Ledger Entries";
                    RunPageLink = "FA No." = FIELD("No.");
                    RunPageView = SORTING("FA No.");
                    ToolTip = 'View all the maintenance ledger entries for a fixed asset.';
                }
            }
        }
        area(processing)
        {
            action(Acquire)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Acquire';
                Enabled = Acquirable;
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Acquire the fixed asset.';

                trigger OnAction()
                var
                    FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
                begin
                    FixedAssetAcquisitionWizard.RunAcquisitionWizard("No.");
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
            action("FA Book Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Value';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 01";
                ToolTip = 'View detailed information about acquisition cost, depreciation and book value for both individual fixed assets and groups of fixed assets. For each of these three amount types, amounts are calculated at the beginning and at the end of a specified period as well as for the period itself.';
            }
            action("FA Book Val. - Appr. & Write-D")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Val. - Appr. & Write-D';
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
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "No." <> xRec."No." then
            SaveSimpleDepriciationBook(xRec."No.");

        LoadDepreciationBooks;
        CurrPage.Update(false);
        FADepreciationBook.Copy(FADepreciationBookOld);
        ShowAcquireNotification;
        BookValue := GetBookValue;
    end;

    trigger OnOpenPage()
    begin
        Simple := true;
        SetNoFieldVisible;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        SaveSimpleDepriciationBook("No.");
    end;

    var
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBookOld: Record "FA Depreciation Book";
        FAAcquireWizardNotificationId: Guid;
        NoFieldVisible: Boolean;
        Simple: Boolean;
        AddMoreDeprBooksLbl: Label 'Add More Depreciation Books';
        Acquirable: Boolean;
        ShowAddMoreDeprBooksLbl: Boolean;
        BookValue: Decimal;

    local procedure ShowAcquireNotification()
    var
        ShowAcquireNotification: Boolean;
    begin
        ShowAcquireNotification :=
          (not Acquired) and FieldsForAcquitionInGeneralGroupAreCompleted and AtLeastOneDepreciationLineIsComplete;
        if ShowAcquireNotification and IsNullGuid(FAAcquireWizardNotificationId) then begin
            Acquirable := true;
            ShowAcquireWizardNotification;
        end else
            Acquirable := false;
    end;

    local procedure AtLeastOneDepreciationLineIsComplete(): Boolean
    var
        FADepreciationBookMultiline: Record "FA Depreciation Book";
    begin
        if Simple then
            exit(FADepreciationBook.RecIsReadyForAcquisition);

        exit(FADepreciationBookMultiline.LineIsReadyForAcquisition("No."));
    end;

    local procedure SaveSimpleDepriciationBook(FixedAssetNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if not SimpleDepreciationBookHasChanged then
            exit;

        if Simple and FixedAsset.Get(FixedAssetNo) then begin
            if FADepreciationBook."Depreciation Book Code" <> '' then
                if FADepreciationBook."FA No." = '' then begin
                    FADepreciationBook.Validate("FA No.", FixedAssetNo);
                    FADepreciationBook.Insert(true)
                end else
                    FADepreciationBook.Modify(true)
        end;
    end;

    local procedure SetDefaultDepreciationBook()
    var
        FASetup: Record "FA Setup";
    begin
        if FADepreciationBook."Depreciation Book Code" = '' then begin
            FASetup.Get();
            FADepreciationBook.Validate("Depreciation Book Code", FASetup."Default Depr. Book");
            SaveSimpleDepriciationBook("No.");
            LoadDepreciationBooks;
        end;
    end;

    local procedure SetDefaultPostingGroup()
    var
        FASubclass: Record "FA Subclass";
    begin
        if FADepreciationBook."FA Posting Group" <> '' then
            exit;

        if FASubclass.Get("FA Subclass Code") then;
        FADepreciationBook.Validate("FA Posting Group", FASubclass."Default FA Posting Group");
        SaveSimpleDepriciationBook("No.");
    end;

    local procedure SimpleDepreciationBookHasChanged(): Boolean
    begin
        exit(Format(FADepreciationBook) <> Format(FADepreciationBookOld));
    end;

    local procedure LoadDepreciationBooks()
    begin
        Clear(FADepreciationBookOld);
        FADepreciationBookOld.SetRange("FA No.", "No.");
        if FADepreciationBookOld.Count <= 1 then begin
            if FADepreciationBookOld.FindFirst then begin
                FADepreciationBookOld.CalcFields("Book Value");
                ShowAddMoreDeprBooksLbl := true
            end;
            Simple := true;
        end else
            Simple := false;

        OnAfterLoadDepreciationBooks(Rec, Simple);
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.FixedAssetNoIsVisible;
    end;

    local procedure GetBookValue(): Decimal
    begin
        if FADepreciationBook."Disposal Date" > 0D then
            exit(0);
        exit(FADepreciationBook."Book Value");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadDepreciationBooks(FixedAsset: Record "Fixed Asset"; var Simple: Boolean);
    begin
    end;
}

