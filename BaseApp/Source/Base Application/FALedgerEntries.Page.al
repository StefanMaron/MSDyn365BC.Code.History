page 5604 "FA Ledger Entries"
{
    AdditionalSearchTerms = 'fixed asset ledger entries';
    ApplicationArea = FixedAssets;
    Caption = 'FA Ledger Entries';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "FA Ledger Entry";
    SourceTableView = SORTING("Entry No.");
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA Posting Date"; "FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("Depr. Period Starting Date"; "Depr. Period Starting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the start date of the depreciation period associated with the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry document type.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the entry.';
                }
                field("FA No."; "FA No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field("FA Posting Group"; "FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                    Visible = false;
                }
                field("FA Posting Category"; "FA Posting Category")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the posting category assigned to the entry when it was posted.';
                }
                field("FA Posting Type"; "FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Need Cost Posted to G/L"; "Need Cost Posted to G/L")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the need cost is posted to general ledger.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("FA Location Code"; "FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the record are processed.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry amount in currency.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Reclassification Entry"; "Reclassification Entry")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies whether the entry was made to reclassify a fixed asset, for example, to change the dimension the fixed asset is linked to.';
                }
                field("Index Entry"; "Index Entry")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies this entry is an index entry.';
                    Visible = false;
                }
                field("No. of Depreciation Days"; "No. of Depreciation Days")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of depreciation days that were used for calculating depreciation for the fixed asset entry.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies whether the entry has been part of a reverse transaction (correction) made by the Reverse function.';
                    Visible = false;
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the correcting entry.';
                    Visible = false;
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("G/L Entry No."; "G/L Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the entry number of the corresponding G/L entry that was created in the general ledger for this fixed asset transaction.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Initial Acquisition"; "Initial Acquisition")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the fixed asset ledger entry is an initial acquisition.';
                }
                field("Depr. Bonus"; "Depr. Bonus")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies if the fixed asset ledger entry contains a depreciation bonus.';
                }
                field("Depr. Bonus Recovery Date"; "Depr. Bonus Recovery Date")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies date of the depreciation bonus recovery associated with the fixed asset ledger entry.';
                }
                field("Depr. Group Elimination"; "Depr. Group Elimination")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the depreciation group elimination of the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Tax Difference Code"; "Tax Difference Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset ledger entry.';
                    Visible = false;
                }
                field("Sales Gain Amount"; "Sales Gain Amount")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the sales gain amount associated with the fixed asset ledger entry.';
                }
                field("Sales Loss Amount"; "Sales Loss Amount")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the sales loss amount associated with the fixed asset ledger entry.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; "Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; "Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; "Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; "Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; "Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; "Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CancelEntries)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Cancel Entries';
                    Ellipsis = true;
                    Image = CancelLine;
                    ToolTip = 'Remove one or more fixed asset ledger entries from the FA Ledger Entries window. If you posted erroneous transactions to one or more fixed assets, you can use this function to cancel the fixed asset ledger entries. In the FA Ledger Entries window, select the entry or entries that you want to cancel.';

                    trigger OnAction()
                    begin
                        FALedgEntry.Copy(Rec);
                        CurrPage.SetSelectionFilter(FALedgEntry);
                        Clear(CancelFAEntries);
                        CancelFAEntries.GetFALedgEntry(FALedgEntry);
                        CancelFAEntries.RunModal();
                        Clear(CancelFAEntries);
                    end;
                }
                separator(Action37)
                {
                }
                action(ReverseTransaction)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Reverse Transaction';
                    Ellipsis = true;
                    Image = ReverseRegister;
                    ToolTip = 'Undo an erroneous journal posting.';

                    trigger OnAction()
                    var
                        ReversalEntry: Record "Reversal Entry";
                        FADeprBook: Record "FA Depreciation Book";
                    begin
                        Clear(ReversalEntry);
                        if Reversed then
                            ReversalEntry.AlreadyReversedEntry(TableCaption, "Entry No.");
                        if "Journal Batch Name" = '' then
                            ReversalEntry.TestFieldError;
                        FADeprBook.Get("FA No.", "Depreciation Book Code");
                        if FADeprBook."Disposal Date" > 0D then
                            Error(Text001);
                        if "Transaction No." = 0 then
                            Error(CannotUndoErr, "Entry No.", "Depreciation Book Code");
                        TestField("G/L Entry No.");
                        ReversalEntry.ReverseTransaction("Transaction No.");
                    end;
                }
                separator(Action1470001)
                {
                }
                action("Mark As Depr. Bonus Base")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Mark As Depr. Bonus Base';
                    Image = ReOpen;
                    ToolTip = 'Set the selected entry to take part in calculating the depreciation bonus. A depreciation bonus is an accelerated depreciation method applied in tax accounting because of provisions in the Russian tax laws. A depreciation bonus enables you to include fixed asset and capital investment expenses in the current period at the rate of 10 percent or 30 percent.';

                    trigger OnAction()
                    var
                        FALedgEntry1: Record "FA Ledger Entry";
                    begin
                        FALedgEntry1.Reset();
                        CurrPage.SetSelectionFilter(FALedgEntry1);
                        FALedgEntry.UnMarkAsDeprBonusBase(FALedgEntry1, true);
                    end;
                }
                action("Unmark As Depr. Bonus Base")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Unmark As Depr. Bonus Base';
                    Image = ReopenCancelled;
                    ToolTip = 'Set the selected entry to not take part in calculating the depreciation bonus. A depreciation bonus is an accelerated depreciation method applied in tax accounting because of provisions in the Russian tax laws. A depreciation bonus enables you to include fixed asset and capital investment expenses in the current period at the rate of 10 percent or 30 percent.';

                    trigger OnAction()
                    var
                        FALedgEntry1: Record "FA Ledger Entry";
                    begin
                        FALedgEntry1.Reset();
                        CurrPage.SetSelectionFilter(FALedgEntry1);
                        FALedgEntry.UnMarkAsDeprBonusBase(FALedgEntry1, false);
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"FA Entry - Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        CancelFAEntries: Report "Cancel FA Entries";
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        Navigate: Page Navigate;
        CannotUndoErr: Label 'You cannot undo the FA Ledger Entry No. %1 by using the Reverse Transaction function because Depreciation Book %2 does not have the appropriate G/L integration setup.';
        Text001: Label 'You cannot reverse the transaction because the fixed asset has been sold.';

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}

