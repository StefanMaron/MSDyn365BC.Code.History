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
                    OptionCaption = 'All,Open,Closed';
                    ToolTip = 'Specifies which entries you want the program to show in the Apply General Ledger Entries window.';

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
                    ToolTip = 'Specifies when the entry was created.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that represents the entry to apply. ';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that represents the entry to apply. ';
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
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of a related job.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Suite;
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
                    ToolTip = 'Specifies the debit amount of the entry.';
                    Visible = false;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit amount of the entry. Credit amounts always have a minus sign.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is in the additional currency.';
                    Visible = false;
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount of the entry.';
                    Visible = false;
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account used in the entry: G/L Account, Bank Account, or Fixed Asset.';
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
                    ToolTip = 'Specifies the ID of the user who created the entry.';
                    Visible = false;
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that is linked to the entry.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
                field("FA Entry Type"; "FA Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field("FA Entry No."; "FA Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be applied.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully applied to. If the check box is selected, then the entry has not yet been fully applied to.';
                }
                field("Closed by Entry No."; "Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry that the entry was applied to.';
                }
                field("Closed at Date"; "Closed at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the entry was applied.';
                }
                field("Closed by Amount"; "Closed by Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the entry was applied to.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry.';
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
                    ToolTip = 'Specifies the amount of the G/L entry that you want to apply to other entries.';
                }
                field(ShowAppliedAmount; ShowAppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the sum of the amounts on the selected entries that will be applied to the entry shown in the Amount field.';
                }
                field(ShowTotalAppliedAmount; ShowTotalAppliedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount after the application, which is the difference between the Amount and Applied Amount fields.';
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
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
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
                action(PostApplication)
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
                        ShowTotalAppliedAmount := 0;
                    end;
                }
                action(UndoApplication)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Undo Application';
                    ToolTip = 'Unapply the applied general ledger entry. The entry will become open, so that you can change it.';

                    trigger OnAction()
                    begin
                        TempGLEntryBuf.Copy(Rec);
                        TempGLEntryBuf.SetRecFilter;
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
                Caption = '&Navigate';
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
        AfterGetCurrentRecord;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord;
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
        TempGLEntryBuf: Record "G/L Entry Application Buffer" temporary;
        TempGLEntryBuf2: Record "G/L Entry Application Buffer" temporary;
        Navigate: Page Navigate;
        ShowAppliedAmount: Decimal;
        ShowAmount: Decimal;
        ShowTotalAppliedAmount: Decimal;
        Text11300: Label 'Preparing Entries      @1@@@@@@@@@@@@@';
        Header: Text[250];
        Text11302: Label 'Apply General Ledger Entries';
        Text11303: Label 'Applied General Ledger Entries';
        DynamicCaption: Text[100];
        IncludeEntryFilter: Option All,Open,Closed;
        GLEntryApplicationBufferNotOpenErr: Label 'Not possible to set applies-to id for entry %1.', Comment = '%1 - Entry No.';

    [Scope('OnPrem')]
    procedure SetApplId(var GLEntryBuf: Record "G/L Entry Application Buffer")
    begin
        CheckGLEntryBufIsOpen(GLEntryBuf);

        if GLEntryBuf.Find('-') then begin
            GLEntryBuf."Applies-to ID" := GetAppliesToID(GLEntryBuf."Applies-to ID");
            SetAppliesToIDOnGLEntryAppBuffer(GLEntryBuf, GLEntryBuf."Applies-to ID");

            if GLEntryBuf."Applies-to ID" <> '' then
                ShowTotalAppliedAmount += GLEntryBuf."Remaining Amount"
            else
                ShowTotalAppliedAmount -= GLEntryBuf."Remaining Amount";
        end;
    end;

    local procedure CheckGLEntryBufIsOpen(GLEntryApplicationBuffer: Record "G/L Entry Application Buffer")
    begin
        GLEntryApplicationBuffer.SetRange(Open, false);
        if not GLEntryApplicationBuffer.IsEmpty then
            Error(GLEntryApplicationBufferNotOpenErr, Format(GLEntryApplicationBuffer."Entry No."));
    end;

    local procedure GetAppliesToID(GLEntryApplID: Code[50]): Code[50]
    var
        ID: Code[50];
    begin
        if GLEntryApplID <> '' then
            exit('');
        ID := UserId;
        if ID = '' then
            exit('***');
        exit(ID);
    end;

    local procedure SetAppliesToIDOnGLEntryAppBuffer(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; GLEntryApplID: Code[50])
    begin
        GLEntryApplicationBuffer.ModifyAll("Applies-to ID", GLEntryApplID);
        GLEntryApplicationBuffer.CalcSums("Remaining Amount");
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
        if GLEntry.Find('-') then begin
            NoOfRecords := GLEntry.Count;
            Window.Open(Text11300);
            repeat
                TempGLEntryBuf.TransferFields(GLEntry);
                TempGLEntryBuf.Insert;
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
    begin
        GetAppliedEntries(TempGLEntryBuf, OrgGLEntry);

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

    [Scope('OnPrem')]
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
    procedure DemoDataTool()
    var
        Window: Dialog;
        tmpAmt: Decimal;
        Stop: Boolean;
    begin
        Window.Open('Applying G/L Ledger Entries');

        SetAllEntries('452000');
        TempGLEntryBuf.SetRange("Global Dimension 1 Code", '');
        TempGLEntryBuf.SetRange(Open, true);

        if TempGLEntryBuf.Find('-') then
            repeat
                TempGLEntryBuf2 := TempGLEntryBuf;
                TempGLEntryBuf2.Insert;
            until TempGLEntryBuf.Next = 0;

        if TempGLEntryBuf.Find('-') then
            repeat
                tmpAmt := TempGLEntryBuf.Amount;
                if TempGLEntryBuf2.Find('-') then
                    repeat
                        if TempGLEntryBuf2.Amount = -tmpAmt then
                            Stop := true;
                    until (TempGLEntryBuf2.Next = 0) or (Stop = true);
            until (TempGLEntryBuf.Next = 0) or (Stop = true);

        // setApplID
        if Stop = true then begin
            TempGLEntryBuf.SetRange(Amount, tmpAmt);
            SetApplId(TempGLEntryBuf);
            TempGLEntryBuf.SetRange(Amount);

            TempGLEntryBuf.SetRange(Amount, -tmpAmt);
            SetApplId(TempGLEntryBuf);
            TempGLEntryBuf.SetRange(Amount);

            // Appl
            TempGLEntryBuf.Apply(TempGLEntryBuf);
        end;

        Window.Close;
    end;

    local procedure IncludeEntryFilterOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        UpdateAmounts;
    end;
}

