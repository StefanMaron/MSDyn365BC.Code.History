page 11775 "Apply General Ledger Entries"
{
    Caption = 'Apply General Ledger Entries';
    DataCaptionFields = "G/L Account No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "G/L Entry" = m;
    SourceTable = "G/L Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TempApplyingGLEntry.""Posting Date"""; TempApplyingGLEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the entry''s Posting Date.';
                }
                field("TempApplyingGLEntry.""Document Type"""; TempApplyingGLEntry."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the original document type which will be applied.';
                }
                field("TempApplyingGLEntry.""Document No."""; TempApplyingGLEntry."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the entry''s Document No.';
                }
                field("TempApplyingGLEntry.""G/L Account No."""; TempApplyingGLEntry."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field("TempApplyingGLEntry.Description"; TempApplyingGLEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry.';
                }
                field("TempApplyingGLEntry.Amount"; TempApplyingGLEntry.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount to apply.';
                }
                field(ApplyingRemainingAmount; ApplyingRemainingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount of general ledger entries';
                }
            }
            repeater(Control1220000)
            {
                ShowCaption = false;
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID to apply to the general ledger entry.';

                    trigger OnValidate()
                    begin
                        AppliestoIDOnAfterValidate;
                    end;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the posting of the apply general ledger entries will be recorded.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the original document type which will be applied.';
                    Visible = false;
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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry to be applied.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field("Amount to Apply"; "Amount to Apply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount to apply.';

                    trigger OnValidate()
                    begin
                        AmounttoApplyOnAfterValidate;
                    end;
                }
                field("Applying Entry"; "Applying Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the general ledger entry is an applying entry.';
                    Visible = false;
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the applied amount for the general ledger entry.';
                }
                field(xRemainingAmount; Remaining)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount';
                    ToolTip = 'Specifies the remaining amount of general ledger entries';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code for the Gen. Prod. Posting Group that applies to the entry.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a VAT business posting group code.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                    Visible = false;
                }
            }
            group(Control1220034)
            {
                ShowCaption = false;
                fixed(Control1220026)
                {
                    ShowCaption = false;
                    group(Control1220028)
                    {
                        Caption = 'Amount to Apply';
                        field(ApplyingAmount; ApplyingAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount to Apply';
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the apply amount for the general ledger entry.';
                        }
                    }
                    group("Available Amount")
                    {
                        Caption = 'Available Amount';
                        field(AvailableAmount; AvailableAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Available Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the journal entry that you have selected as the applying entry.';
                        }
                    }
                    group(Balance)
                    {
                        Caption = 'Balance';
                        field("AvailableAmount + ApplyingAmount"; AvailableAmount + ApplyingAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies the description of the entry to be applied.';
                        }
                    }
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
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied General Ledger Entries";
                    RunPageOnRec = true;
                    ToolTip = 'Specifies the apllied entries.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View the dimension sets that are set up for the entry.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed G/L Entries";
                    RunPageLink = "G/L Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("G/L Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Specifies the detailed ledger entries of the entry.';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                action("Set Applying Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Applying Entry';
                    Image = Line;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Sets applying entry';

                    trigger OnAction()
                    var
                        TEntryNo: Integer;
                    begin
                        if GenJnlLineApply then
                            exit;

                        TEntryNo := "Entry No.";
                        if TempApplyingGLEntry."Entry No." <> 0 then
                            RemoveApplyingGLEntry;
                        SetApplyingGLEntry(TEntryNo);
                    end;
                }
                action("Remove Applying Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Applying Entry';
                    Image = CancelLine;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Removes applying entry';

                    trigger OnAction()
                    begin
                        if GenJnlLineApply then
                            exit;

                        RemoveApplyingGLEntry;
                    end;
                }
                action("Set Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'Sets applies to id';

                    trigger OnAction()
                    begin
                        SetAppliesToID;
                    end;
                }
                action("Post Application")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Application';
                    Ellipsis = true;
                    Image = PostApplication;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'This batch job posts G/L entries application.';

                    trigger OnAction()
                    var
                        GLEntry2: Record "G/L Entry";
                        GLEntry3: Record "G/L Entry";
                    begin
                        if CalcType <> CalcType::GenJnlLine then begin
                            if TempApplyingGLEntry."Entry No." <> 0 then begin
                                GLEntry3.Get(TempApplyingGLEntry."Entry No.");
                                GLEntry3.CalcFields("Applied Amount");
                                Commit();
                                GLEntryPostApplication.PostApplyGLEntry(TempApplyingGLEntry);
                                CurrPage.Update(false);
                                GLEntry2.Get(TempApplyingGLEntry."Entry No.");
                                GLEntry2.CalcFields("Applied Amount");
                                if GLEntry3."Applied Amount" <> GLEntry2."Applied Amount" then
                                    RemoveApplyingGLEntry;
                            end else
                                Error(AppEntryNeedErr);
                        end else
                            Error(AppFromWindowErr);
                    end;
                }
                action("Show Only Selected Entries to Be Applied")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Only Selected Entries to Be Applied';
                    Image = ShowSelected;
                    ToolTip = 'View the selected ledger entries that will be applied to the specified record. ';

                    trigger OnAction()
                    begin
                        ShowAppliedEntries := not ShowAppliedEntries;
                        if ShowAppliedEntries then
                            SetRange("Applies-to ID", GLApplID)
                        else
                            SetRange("Applies-to ID");
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

    trigger OnAfterGetRecord()
    begin
        CalcFields("Applied Amount");
        Remaining := Amount - "Applied Amount";
    end;

    trigger OnClosePage()
    var
        lreGLEntry: Record "G/L Entry";
    begin
        ShowAppliedEntries := false;
        if not PostingDone then begin
            lreGLEntry := TempApplyingGLEntry;
            if lreGLEntry.Find then
                GLEntryPostApplication.SetApplyingGLEntry(lreGLEntry, false, '');
        end;
    end;

    trigger OnOpenPage()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GetFilter("G/L Account No."));
        PostingDone := false;

        if CalcType = CalcType::GenJnlLine then begin
            case ApplnType of
                ApplnType::"Applies-to Doc. No.":
                    GLApplID := GenJnlLine."Applies-to Doc. No.";
                ApplnType::"Applies-to ID":
                    GLApplID := GenJnlLine."Applies-to ID";
            end;
            CalcApplnAmount;
        end else
            FindApplyingGLEntry;
    end;

    var
        AppEntryNeedErr: Label 'You must select an applying entry before posting the application.';
        AppFromWindowErr: Label 'You must post the application from the window where you entered the applying entry.';
        TempApplyingGLEntry: Record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntryPostApplication: Codeunit "G/L Entry -Post Application";
        Navigate: Page Navigate;
        ShowAppliedEntries: Boolean;
        ApplyingRemainingAmount: Decimal;
        ApplyingAmount: Decimal;
        AvailableAmount: Decimal;
        GLApplID: Code[50];
        Remaining: Decimal;
        ApplEntryNo: Integer;
        PostingDone: Boolean;
        GenJnlLineApply: Boolean;
        ApplnType: Option " ","Applies-to Doc. No.","Applies-to ID";
        CalcType: Option Direct,GenJnlLine;

    local procedure FindApplyingGLEntry()
    begin
        GLApplID := UserId;
        if GLApplID = '' then
            GLApplID := '***';

        if ApplEntryNo <> 0 then begin
            SetApplyingGLEntry(ApplEntryNo);
            ApplEntryNo := 0;
        end else begin
            GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
            GLEntry.SetRange("G/L Account No.", "G/L Account No.");
            GLEntry.SetRange("Applies-to ID", GLApplID);
            GLEntry.SetRange(Closed, false);
            GLEntry.SetRange("Applying Entry", true);
            if GLEntry.FindFirst then
                SetApplyingGLEntry(GLEntry."Entry No.");
        end;
        CalcApplnAmount;
    end;

    local procedure SetApplyingGLEntry(EntryNo: Integer)
    begin
        Get(EntryNo);
        GLEntryPostApplication.SetApplyingGLEntry(Rec, true, GLApplID);
        if Amount > 0 then
            SetFilter(Amount, '<0')
        else
            SetFilter(Amount, '>0');
        "Applying Entry" := true;
        Modify;

        TempApplyingGLEntry := Rec;
        SetCurrentKey("Entry No.");
        SetFilter("Entry No.", '<> %1', "Entry No.");
        AvailableAmount := Amount - "Applied Amount";
        ApplyingRemainingAmount := Amount - "Applied Amount";
        CalcApplnAmount;
        SetCurrentKey("G/L Account No.");
    end;

    local procedure RemoveApplyingGLEntry()
    begin
        if Get(TempApplyingGLEntry."Entry No.") then begin
            GLEntryPostApplication.SetApplyingGLEntry(Rec, false, '');
            SetRange(Amount);
            "Applying Entry" := false;
            Modify;

            Clear(TempApplyingGLEntry);
            SetCurrentKey("Entry No.");
            SetRange("Entry No.");
            AvailableAmount := 0;
            ApplyingRemainingAmount := 0;
            CalcApplnAmount;
        end;
    end;

    local procedure SetAppliesToID()
    begin
        GLEntry.Reset();
        GLEntry.Copy(Rec);
        CurrPage.SetSelectionFilter(GLEntry);
        if GLEntry.FindSet(true, false) then
            repeat
                GLEntryPostApplication.SetApplyingGLEntry(GLEntry, false, GLApplID);
            until GLEntry.Next() = 0;
        Rec := GLEntry;
        CalcApplnAmount;
        CurrPage.Update(false);
    end;

    local procedure CalcApplnAmount()
    begin
        ApplyingAmount := 0;
        GLEntry.Reset();
        GLEntry.Copy(Rec);
        GLEntry.SetRange("Applies-to ID", GLApplID);
        if GLEntry.FindSet then
            repeat
                ApplyingAmount := ApplyingAmount + GLEntry."Amount to Apply";
            until GLEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckAppliesToID(var GLEntry2: Record "G/L Entry")
    begin
        if GLEntry2."Applies-to ID" <> '' then begin
            GLApplID := UserId;
            if GLApplID = '' then
                GLApplID := '***';
            GLEntry2.TestField("Applies-to ID", GLApplID);
        end;
    end;

    local procedure AppliestoIDOnAfterValidate()
    begin
        if ("Applies-to ID" = GLApplID) and ("Amount to Apply" = 0) then
            SetAppliesToID;

        if "Applies-to ID" = '' then begin
            "Applies-to ID" := '';
            "Amount to Apply" := 0;
            Modify;
        end;
    end;

    local procedure AmounttoApplyOnAfterValidate()
    begin
        if "Amount to Apply" <> 0 then
            "Applies-to ID" := GLApplID
        else
            "Applies-to ID" := '';
        Modify;
        CalcApplnAmount;
    end;

    [Scope('OnPrem')]
    procedure SetAplEntry(ApplEntryNo1: Integer)
    begin
        ApplEntryNo := ApplEntryNo1;
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line"; ApplnTypeSelect: Integer)
    begin
        GenJnlLine := NewGenJnlLine;
        GenJnlLineApply := true;

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account" then
            ApplyingAmount := -GenJnlLine.Amount;
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" then
            ApplyingAmount := GenJnlLine.Amount;

        CalcType := CalcType::GenJnlLine;

        case ApplnTypeSelect of
            GenJnlLine.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            GenJnlLine.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        TempApplyingGLEntry."Entry No." := 1;
        TempApplyingGLEntry."Posting Date" := GenJnlLine."Posting Date";
        TempApplyingGLEntry."Document Type" := GenJnlLine."Document Type";
        TempApplyingGLEntry."Document No." := GenJnlLine."Document No.";
        TempApplyingGLEntry."G/L Account No." := GenJnlLine."Account No.";
        TempApplyingGLEntry.Description := GenJnlLine.Description;
        TempApplyingGLEntry.Amount := GenJnlLine.Amount;
        ApplyingRemainingAmount := GenJnlLine.Amount;
        CalcApplnAmount;
    end;
}

