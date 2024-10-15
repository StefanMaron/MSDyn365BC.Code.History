page 11309 "Apply General Ledger Entries"
{
    Caption = 'Apply General Ledger Entries';
    DataCaptionExpression = Header;
    PageType = Worksheet;
    Permissions = TableData "G/L Entry" = rm,
                  TableData "G/L Entry Application Buffer" = rim;
    SourceTable = "G/L Entry Application Buffer";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(IncludeEntryFilter; IncludeEntryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include Entries';
                    ToolTip = 'Specifies which status entries must have to be shown in the window. You can only apply general ledger entries that are open. Open is the default value in the field.';

                    trigger OnValidate()
                    begin
                        SetIncludeEntryFilter;
                        IncludeEntryFilterOnAfterValid;
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("G/L Account No."; "G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in the additional reporting currency.';
                    Visible = false;
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT included in the total amount.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account used in the entry: G/L Account, Bank Account, Vendor, Customer, or Fixed Asset.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry for the journal line will posted (for example, a cash account for cash purchases).';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("FA Entry Type"; "FA Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("FA Entry No."; "FA Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the fixed asset entry.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be applied to if the entry has not been completely applied to.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the general ledger entry is open. The general ledger entry will remain open until it is fully applied.';
                }
                field("Closed by Entry No."; "Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the original entry that was applied to close the general ledger entry.';
                }
                field("Closed at Date"; "Closed at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the entry was applied.';
                }
                field("Closed by Amount"; "Closed by Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original entry that was applied to close the general ledger entry.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the consecutive number assigned to this entry.';
                }
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = false;
                }
            }
            group(Control1010001)
            {
                Editable = false;
                ShowCaption = false;
                field(ShowAmount; ShowAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount to be applied.';
                }
                field(ShowAppliedAmount; ShowAppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the sum of the amounts in the Amount to Apply field, Pmt. Disc. Amount field, and the Rounding. The amount is in the currency represented by the code in the Currency Code field.';
                }
                field(ShowTotalAppliedAmount; ShowTotalAppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies any extra amount that will remain after the application.';
                }
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        if GLEntry.Get("Entry No.") then
                            GLEntry.ShowDimensions();
                    end;
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action(SetAppliesToID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    ShortCutKey = 'F7';
                    ToolTip = 'Set the Applies-to ID field on the posted entry to automatically be filled in with the document number of the entry in the journal.';

                    trigger OnAction()
                    begin
                        TempGLEntryBuf.Copy(Rec);
                        CurrPage.SetSelectionFilter(TempGLEntryBuf);
                        SetApplId(TempGLEntryBuf);
                    end;
                }
                action("Post Application")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Application';
                    Image = PostApplication;
                    ShortCutKey = 'F9';
                    ToolTip = 'Define the document number of the ledger entry to use to perform the application. In addition, you specify the Posting Date for the application.';

                    trigger OnAction()
                    begin
                        TempGLEntryBuf.Copy(Rec);
                        Apply(TempGLEntryBuf);
                    end;
                }
                action("&Undo Application")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Undo Application';
                    Image = Undo;
                    ToolTip = 'Unapply the selected general ledger entries. Note: If an entry is applied to more than one application entry, you must unapply the latest application entry first. By default, the latest entry is displayed.';

                    trigger OnAction()
                    begin
                        TempGLEntryBuf.Copy(Rec);
                        CurrPage.SetSelectionFilter(TempGLEntryBuf);
                        Undo(TempGLEntryBuf);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAmounts;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        TempGLEntryBuf.Copy(Rec);
        Found := TempGLEntryBuf.Find(Which);
        if Found then
            Rec := TempGLEntryBuf;
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempGLEntryBuf.Copy(Rec);
        ResultSteps := TempGLEntryBuf.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempGLEntryBuf;
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
    begin
        if TempGLEntryBuf."G/L Account No." <> '' then begin
            GLAcc.Get(TempGLEntryBuf."G/L Account No.");
            Header := GLAcc."No." + ' ' + GLAcc.Name;
        end;
        CurrPage.Caption := DynamicCaption;
        SetIncludeEntryFilter;
    end;

    var
        Navigate: Page Navigate;
        GLEntryApplID: Code[50];
        Text11300: Label 'Preparing Entries      @1@@@@@@@@@@@@@';
        Text11301: Label 'Another user has modified the record for this general ledger entry after you retrieved it from the database.';
        Header: Text[250];
        Text11302: Label 'Apply General Ledger Entries';
        Text11303: Label 'Applied General Ledger Entries';
        DynamicCaption: Text[100];
        Text11304: Label 'You can apply multiple entries only if all entries being applied can be fully closed.';
        Text11305: Label 'There are no general ledger entries to apply';

    protected var
        TempGLEntryBuf: Record "G/L Entry Application Buffer" temporary;
        IncludeEntryFilter: Option All,Open,Closed;
        ShowAppliedAmount: Decimal;
        ShowAmount: Decimal;
        ShowTotalAppliedAmount: Decimal;

#pragma warning disable AS0022 // False positive due to a compiler bug fix
    [Scope('OnPrem')]
    procedure Apply(var GLEntryBuf: Record "G/L Entry Application Buffer")
    var
        GLEntry: Record "G/L Entry";
        AppliedAmount: Decimal;
        TotalAppliedAmount: Decimal;
        RemainingAmount: Decimal;
        BaseEntryNo: Integer;
    begin
        GLEntryBuf.TestField("Applies-to ID");
        BaseEntryNo := TempGLEntryBuf."Entry No.";
        RemainingAmount := GLEntryBuf."Remaining Amount";

        RealEntryChanged(TempGLEntryBuf, GLEntry);

        GLEntryBuf.SetRange("Applies-to ID", GLEntryBuf."Applies-to ID");
        GLEntryBuf.SetFilter("Entry No.", '<> %1', GLEntryBuf."Entry No.");
        GLEntryBuf.SetRange(Positive, not GLEntryBuf.Positive);
        GLEntryBuf.CalcSums("Remaining Amount");
        if GLEntryBuf."Remaining Amount" = 0 then
            Error(Text11305);
        if RemainingAmount + GLEntryBuf."Remaining Amount" <> 0 then begin
            GLEntryBuf.SetRange(Positive);
            GLEntryBuf.CalcSums("Remaining Amount");
            if RemainingAmount + GLEntryBuf."Remaining Amount" <> 0 then
                Error(Text11304);
        end;
        GLEntryBuf.FindSet;
        repeat
            GLEntryBuf.TestField("G/L Account No.", GLEntryBuf."G/L Account No.");
            GLEntryBuf.TestField(Open, true);
            AppliedAmount := -GLEntryBuf."Remaining Amount";
            TotalAppliedAmount := TotalAppliedAmount + AppliedAmount;
            RealEntryChanged(GLEntryBuf, GLEntry);
            UpdateTempTable(GLEntryBuf, 0, false, BaseEntryNo, "Posting Date", -AppliedAmount, '');
            UpdateRealTable(GLEntry, 0, false, BaseEntryNo, "Posting Date", -AppliedAmount, '');
        until GLEntryBuf.Next = 0;

        // Update entry where cursor is on
        // Update real Table
        with GLEntry do begin
            Get(BaseEntryNo);
            UpdateRealTable(
              GLEntry, "Remaining Amount" - TotalAppliedAmount,
              ("Remaining Amount" - TotalAppliedAmount) <> 0, 0, 0D, 0, '');
        end;

        // Update Temporary Table
        with TempGLEntryBuf do begin
            Get(BaseEntryNo);
            UpdateTempTable(
              TempGLEntryBuf, "Remaining Amount" - TotalAppliedAmount,
              ("Remaining Amount" - TotalAppliedAmount) <> 0, 0, 0D, 0, '');
        end;

        ShowTotalAppliedAmount := 0;
    end;
#pragma warning restore AS0022

    [Scope('OnPrem')]
    procedure Undo(var GLEntryBuf: Record "G/L Entry Application Buffer")
    var
        OrgGLEntry: Record "G/L Entry";
        GLEntry: Record "G/L Entry";
        UndoGLEntry: Record "G/L Entry";
        BaseEntryNo: Integer;
    begin
        // 'Real' G/L Entry changed whilst undoing ?
        RealEntryChanged(GLEntryBuf, GLEntry);

        with GLEntryBuf do begin
            Reset;

            if "Closed by Entry No." <> 0 then begin
                OrgGLEntry.Get("Closed by Entry No.");
                OrgGLEntry.TestField("Closed by Entry No.", 0);
            end else
                OrgGLEntry.Get("Entry No.");
            BaseEntryNo := OrgGLEntry."Entry No.";

            UndoGLEntry.SetCurrentKey("Closed by Entry No.");
            UndoGLEntry.SetRange("Closed by Entry No.", OrgGLEntry."Entry No.");
            if UndoGLEntry.FindSet then
                repeat
                    RealEntryChanged(GLEntryBuf, GLEntry);
                    if Get(UndoGLEntry."Entry No.") then
                        UpdateTempTable(GLEntryBuf, "Closed by Amount", true, 0, 0D, 0, '');
                    UpdateRealTable(UndoGLEntry, UndoGLEntry."Closed by Amount", true, 0, 0D, 0, '');
                until UndoGLEntry.Next = 0;

            GLEntry.Get(BaseEntryNo);
            UpdateRealTable(GLEntry, GLEntry.Amount, true, 0, 0D, 0, '');
            if TempGLEntryBuf.Get(BaseEntryNo) then
                UpdateTempTable(TempGLEntryBuf, TempGLEntryBuf.Amount, true, 0, 0D, 0, '');

            SetRange("Closed by Entry No.");
            SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetApplId(var GLEntryBuf: Record "G/L Entry Application Buffer")
    begin
        GLEntryBuf.TestField(Open, true);
        if GLEntryBuf.Find('-') then begin
            // Make Applies-to ID
            if GLEntryBuf."Applies-to ID" <> '' then
                GLEntryApplID := ''
            else begin
                GLEntryApplID := UserId;
                if GLEntryApplID = '' then
                    GLEntryApplID := '***';
            end;

            // Set Applies-to ID
            repeat
                GLEntryBuf.TestField(Open, true);
                GLEntryBuf."Applies-to ID" := GLEntryApplID;
                if GLEntryApplID = '' then
                    ShowTotalAppliedAmount -= GLEntryBuf."Remaining Amount"
                else
                    ShowTotalAppliedAmount += GLEntryBuf."Remaining Amount";
                GLEntryBuf.Modify();
            until GLEntryBuf.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAllEntries(GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
    begin
        GLEntry.SetCurrentKey("G/L Account No.");
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        if GLEntry.FindSet then begin
            NoOfRecords := GLEntry.Count();
            Window.Open(Text11300);
            repeat
                TransferGLEntry(TempGLEntryBuf, GLEntry);
                LineCount := LineCount + 1;
                Window.Update(1, Round(LineCount / NoOfRecords * 10000, 1));
            until GLEntry.Next = 0;
            Window.Close;
        end;

        DynamicCaption := Text11302;

        // By default only show open entries when applying
        SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        SetRange(Open, true);
        IncludeEntryFilter := IncludeEntryFilter::Open;
    end;

    [Scope('OnPrem')]
    procedure SetAppliedEntries(OrgGLEntry: Record "G/L Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        if OrgGLEntry."Closed by Entry No." <> 0 then begin
            GLEntry.Get(OrgGLEntry."Closed by Entry No.");
            TransferGLEntry(TempGLEntryBuf, GLEntry);
        end else begin
            GLEntry.SetCurrentKey("Closed by Entry No.");
            GLEntry.SetRange("Closed by Entry No.", OrgGLEntry."Entry No.");
            if GLEntry.FindSet then
                repeat
                    if GLEntry."Entry No." <> OrgGLEntry."Entry No." then
                        TransferGLEntry(TempGLEntryBuf, GLEntry);
                until GLEntry.Next = 0;
        end;

        DynamicCaption := Text11303;

        // By default only show open entries when applying
        SetCurrentKey("Closed by Entry No.");
        IncludeEntryFilter := IncludeEntryFilter::All;
    end;

    [Scope('OnPrem')]
    procedure SetIncludeEntryFilter()
    begin
        SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        case IncludeEntryFilter of
            IncludeEntryFilter::All:
                SetRange(Open);
            IncludeEntryFilter::Open:
                SetRange(Open, true);
            IncludeEntryFilter::Closed:
                SetRange(Open, false);
        end;
    end;

    [Obsolete('Function scope will be changed to OnPrem', '15.1')]
    procedure UpdateAmounts()
    begin
        ShowAppliedAmount := 0;
        ShowAmount := 0;
        if "Applies-to ID" <> '' then begin
            ShowAmount := TempGLEntryBuf."Remaining Amount";
            ShowAppliedAmount := ShowTotalAppliedAmount - TempGLEntryBuf."Remaining Amount";
        end;
    end;

    [Scope('OnPrem')]
    procedure RealEntryChanged(TempEntry: Record "G/L Entry Application Buffer"; var GlEntry: Record "G/L Entry")
    begin
        // 'Real' G/L Entry changed whilst application ?
        with GlEntry do begin
            LockTable();
            Get(TempEntry."Entry No.");
            if ("Remaining Amount" <> TempEntry."Remaining Amount") or
               (Open <> TempEntry.Open) or
               ("Closed by Entry No." <> TempEntry."Closed by Entry No.") or
               ("Closed at Date" <> TempEntry."Closed at Date") or
               ("Closed by Amount" <> TempEntry."Closed by Amount")
            then
                Error(Text11301);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateTempTable(var TempEntry: Record "G/L Entry Application Buffer"; RemainingAmt: Decimal; IsOpen: Boolean; ClosedbyEntryNo: Integer; ClosedbyDate: Date; ClosedbyAmt: Decimal; AppliesToID: Code[20])
    begin
        // Update Temporary Table
        with TempEntry do begin
            "Remaining Amount" := RemainingAmt;
            Open := IsOpen;
            "Closed by Entry No." := ClosedbyEntryNo;
            "Closed at Date" := ClosedbyDate;
            "Closed by Amount" := ClosedbyAmt;
            "Applies-to ID" := AppliesToID;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateRealTable(RealEntry: Record "G/L Entry"; RemainingAmt: Decimal; IsOpen: Boolean; ClosedbyEntryNo: Integer; ClosedbyDate: Date; ClosedbyAmt: Decimal; AppliesToID: Code[20])
    begin
        // Update Temporary Table
        with RealEntry do begin
            "Remaining Amount" := RemainingAmt;
            Open := IsOpen;
            "Closed by Entry No." := ClosedbyEntryNo;
            "Closed at Date" := ClosedbyDate;
            "Closed by Amount" := ClosedbyAmt;
            "Applies-to ID" := AppliesToID;
            Modify;
        end;
    end;

    local procedure IncludeEntryFilterOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure TransferGLEntry(var GLEntryBuf: Record "G/L Entry Application Buffer"; GLEntry: Record "G/L Entry")
    begin
        GLEntryBuf.TransferFields(GLEntry);
        GLEntryBuf.Positive := GLEntry.Amount > 0;
        GLEntryBuf.Insert();
    end;
}

