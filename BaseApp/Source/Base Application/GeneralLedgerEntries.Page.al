page 20 "General Ledger Entries"
{
    AdditionalSearchTerms = 'g/l transactions';
    ApplicationArea = Basic, Suite;
    Caption = 'General Ledger Entries';
    DataCaptionExpression = GetCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "G/L Entry" = m;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "G/L Entry";
    SourceTableView = SORTING("G/L Account No.", "Posting Date")
                      ORDER(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Document Type that the entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("G/L Account No."; "G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field("G/L Account Name"; "G/L Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the account that the entry has been posted to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                    Visible = false;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the quantity that was posted on the entry.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Amount of the entry.';
                    Visible = AmountVisible;
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = DebitCreditVisible;
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the general ledger entry that is posted if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction (correction) made by the Reverse function.';
                    Visible = false;
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("FA Entry Type"; "FA Entry Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("FA Entry No."; "FA Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s external document number, such as a vendor''s invoice number.';
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
            }
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    Scope = Repeater;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
                action(GLDimensionOverview)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'G/L Dimension Overview';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View an overview of general ledger entries and dimensions.';

                    trigger OnAction()
                    var
                        GLEntriesDimensionOverview: Page "G/L Entries Dimension Overview";
                    begin
                        if IsTemporary then begin
                            GLEntriesDimensionOverview.SetTempGLEntry(Rec);
                            GLEntriesDimensionOverview.Run;
                        end else
                            PAGE.Run(PAGE::"G/L Entries Dimension Overview", Rec);
                    end;
                }
                action("Value Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value Entries';
                    Image = ValueLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Scope = Repeater;
                    ToolTip = 'View all amounts relating to an item.';

                    trigger OnAction()
                    begin
                        ShowValueEntries;
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
                action(ReverseTransaction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse Transaction';
                    Ellipsis = true;
                    Image = ReverseRegister;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'Reverse a posted general ledger entry.';

                    trigger OnAction()
                    var
                        ReversalEntry: Record "Reversal Entry";
                    begin
                        Clear(ReversalEntry);
                        if Reversed then
                            ReversalEntry.AlreadyReversedEntry(TableCaption, "Entry No.");
                        if "Journal Batch Name" = '' then
                            ReversalEntry.TestFieldError;
                        TestField("Transaction No.");
                        ReversalEntry.ReverseTransaction("Transaction No.")
                    end;
                }
                group(IncomingDocument)
                {
                    Caption = 'Incoming Document';
                    Image = Documents;
                    action(IncomingDocCard)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'View Incoming Document';
                        Enabled = HasIncomingDocument;
                        Image = ViewOrder;
                        ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            IncomingDocument.ShowCard("Document No.", "Posting Date");
                        end;
                    }
                    action(SelectIncomingDoc)
                    {
                        AccessByPermission = TableData "Incoming Document" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select Incoming Document';
                        Enabled = NOT HasIncomingDocument;
                        Image = SelectLineToApply;
                        ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            IncomingDocument.SelectIncomingDocumentForPostedDocument("Document No.", "Posting Date", RecordId);
                        end;
                    }
                    action(IncomingDocAttachFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Incoming Document from File';
                        Ellipsis = true;
                        Enabled = NOT HasIncomingDocument;
                        Image = Attach;
                        ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                        trigger OnAction()
                        var
                            IncomingDocumentAttachment: Record "Incoming Document Attachment";
                        begin
                            IncomingDocumentAttachment.NewAttachmentFromPostedDocument("Document No.", "Posting Date");
                        end;
                    }
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
            action(DocsWithoutIC)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Documents without Incoming Document';
                Image = Documents;
                ToolTip = 'View posted purchase and sales documents under the G/L account that do not have related incoming document records.';

                trigger OnAction()
                var
                    PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf.";
                begin
                    CopyFilter("G/L Account No.", PostedDocsWithNoIncBuf."G/L Account No. Filter");
                    PAGE.Run(PAGE::"Posted Docs. With No Inc. Doc.", PostedDocsWithNoIncBuf);
                end;
            }
            action(ShowChangeHistory)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Change History';
                Enabled = ShowChangeHistoryEnabled;
                Image = History;
                ToolTip = 'View the history of changes for this entry.';

                trigger OnAction()
                var
                    ChangeLogEntry: Record "Change Log Entry";
                begin
                    SetChangeLogEntriesFilter(ChangeLogEntry);
                    PAGE.RunModal(PAGE::"Change Log Entries", ChangeLogEntry);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        HasIncomingDocument := IncomingDocument.PostedDocExists("Document No.", "Posting Date");
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SetControlEnabled;
    end;

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"G/L Entry-Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetControlVisibility;

        if GetFilters <> '' then
            if FindFirst then;
    end;

    var
        GLAcc: Record "G/L Account";
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        HasIncomingDocument: Boolean;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
        ShowChangeHistoryEnabled: Boolean;

    local procedure GetCaption(): Text[250]
    begin
        if GLAcc."No." <> "G/L Account No." then
            if not GLAcc.Get("G/L Account No.") then
                if GetFilter("G/L Account No.") <> '' then
                    if GLAcc.Get(GetRangeMin("G/L Account No.")) then;
        exit(StrSubstNo('%1 %2', GLAcc."No.", GLAcc.Name))
    end;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;

    local procedure SetControlEnabled()
    begin
        ShowChangeHistoryEnabled := HasChangeLogEntries;
    end;

    local procedure HasChangeLogEntries(): Boolean
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        SetChangeLogEntriesFilter(ChangeLogEntry);
        exit(not ChangeLogEntry.IsEmpty);
    end;

    local procedure SetChangeLogEntriesFilter(var ChangeLogEntry: Record "Change Log Entry")
    begin
        ChangeLogEntry.SetRange("Table No.", DATABASE::"G/L Entry");
        ChangeLogEntry.SetRange("Primary Key Field 1 Value", Format("Entry No.", 0, 9));
    end;
}

