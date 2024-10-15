#if not CLEAN22
page 11310 "General Ledger Entries Apply"
{
    Caption = 'Apply General Ledger Entries';
    DataCaptionExpression = Header;
    PageType = Worksheet;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by feature Review General Ledger Entries';
    ObsoleteTag = '22.0';
    Permissions = TableData "G/L Entry" = rm,
                  TableData "G/L Entry Application Buffer" = rim;
    SourceTable = "G/L Entry Application Buffer";
    SourceTableTemporary = true;

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
                        SetIncludeEntryFilter();
                        IncludeEntryFilterOnAfterValid();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the entry was created.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that represents the entry to apply. ';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that represents the entry to apply. ';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of a related job.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type to use when posting to this account.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit amount of the entry.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit amount of the entry. Credit amounts always have a minus sign.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is in the additional currency.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount of the entry.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of balancing account used in the entry: G/L Account, Bank Account, or Fixed Asset.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry for the journal line will posted (for example, a cash account for cash purchases).';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who created the entry.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that is linked to the entry.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code on the entry.';
                    Visible = false;
                }
                field("FA Entry Type"; Rec."FA Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field("FA Entry No."; Rec."FA Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be applied.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully applied to. If the check box is selected, then the entry has not yet been fully applied to.';
                }
                field("Closed by Entry No."; Rec."Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry that the entry was applied to.';
                }
                field("Closed at Date"; Rec."Closed at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the entry was applied.';
                }
                field("Closed by Amount"; Rec."Closed by Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the entry was applied to.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
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
                        ShowDimensions();
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
                    var
                        TempGLEntryApplicationBuffer: Record "G/L Entry Application Buffer" temporary;
                    begin
                        TempGLEntryApplicationBuffer.Copy(Rec, true);
                        CurrPage.SetSelectionFilter(TempGLEntryApplicationBuffer);
                        SetApplId(TempGLEntryApplicationBuffer);
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
                    var
                        TempGLEntryApplicationBuffer: Record "G/L Entry Application Buffer" temporary;
                    begin
                        TempGLEntryApplicationBuffer.Copy(Rec, true);
                        Apply(TempGLEntryApplicationBuffer);
                        ShowTotalAppliedAmount := 0;
                        OnAfterPostApplication(Rec);
                    end;
                }
                action(UndoApplication)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Undo Application';
                    ToolTip = 'Unapply the applied general ledger entry. The entry will become open, so that you can change it.';

                    trigger OnAction()
                    var
                        TempGLEntryApplicationBuffer: Record "G/L Entry Application Buffer" temporary;
                    begin
                        TempGLEntryApplicationBuffer.Copy(Rec, true);
                        TempGLEntryApplicationBuffer.SetRecFilter();
                        Undo(TempGLEntryApplicationBuffer);
                        CurrPage.Update(false);
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
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    var
        GLAcc: Record "G/L Account";
    begin
        if Rec."G/L Account No." <> '' then begin
            GLAcc.Get(Rec."G/L Account No.");
            Header := GLAcc."No." + ' ' + GLAcc.Name;
        end;
        CurrPage.Caption := DynamicCaption;
        SetIncludeEntryFilter();
        if Rec.FindFirst() then;
    end;

    var
        Navigate: Page Navigate;
        PreparingEntriesTxt: Label 'Preparing Entries      @1@@@@@@@@@@@@@';
        Header: Text[250];
        ApplyGeneralLedgerEntriesLbl: Label 'Apply General Ledger Entries';
        AppliedGeneralLedgerEntriesLbl: Label 'Applied General Ledger Entries';
        GLEntryApplicationBufferNotOpenErr: Label 'Not possible to set applies-to id for entry %1.', Comment = '%1 - Entry No.';

    protected var
        DynamicCaption: Text[100];
        IncludeEntryFilter: Option All,Open,Closed;
        ShowAppliedAmount: Decimal;
        ShowAmount: Decimal;
        ShowTotalAppliedAmount: Decimal;


    protected procedure SetApplId(var GLEntryBuf: Record "G/L Entry Application Buffer")
    begin
        CheckGLEntryBufIsOpen(GLEntryBuf);

        if GLEntryBuf.FindFirst() then begin
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
        if not GLEntryApplicationBuffer.IsEmpty() then
            Error(GLEntryApplicationBufferNotOpenErr, Format(GLEntryApplicationBuffer."Entry No."));
    end;

    local procedure GetAppliesToID(GLEntryApplID: Code[50]): Code[50]
    var
        ID: Code[50];
    begin
        if GLEntryApplID <> '' then
            exit('');
        ID := CopyStr(UserId(), 1, MaxStrLen(ID));
        if ID = '' then
            exit('***');
        exit(ID);
    end;

    local procedure SetAppliesToIDOnGLEntryAppBuffer(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; GLEntryApplID: Code[50])
    begin
        GLEntryApplicationBuffer.ModifyAll("Applies-to ID", GLEntryApplID);
        GLEntryApplicationBuffer.CalcSums("Remaining Amount");
    end;

    procedure SetAllEntries(GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetAllEntries(Rec, GLAccNo, DynamicCaption, IncludeEntryFilter, IsHandled);
        if IsHandled then
            exit;

        GLEntry.SetCurrentKey("G/L Account No.");
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        if GLEntry.Find('-') then begin
            NoOfRecords := GLEntry.Count();
            Window.Open(PreparingEntriesTxt);
            repeat
                Rec.TransferFields(GLEntry);
                Rec.Insert();
                LineCount := LineCount + 1;
                Window.Update(1, Round(LineCount / NoOfRecords * 10000, 1));
            until GLEntry.Next() = 0;
            Window.Close();
        end;

        DynamicCaption := ApplyGeneralLedgerEntriesLbl;

        // By default only show open entries when applying
        SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        SetRange(Open, true);
        IncludeEntryFilter := IncludeEntryFilter::Open;
    end;

    internal procedure SetAppliedEntries(OrgGLEntry: Record "G/L Entry")
    begin
        GetAppliedEntries(Rec, OrgGLEntry);

        DynamicCaption := AppliedGeneralLedgerEntriesLbl;

        // By default only show open entries when applying
        SetCurrentKey("Closed by Entry No.");
        IncludeEntryFilter := IncludeEntryFilter::All;
        OnAfterSetAppliedEntries(Rec, OrgGLEntry, DynamicCaption, IncludeEntryFilter);
    end;

    internal procedure SetIncludeEntryFilter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetIncludeEntryFilter(Rec, IncludeEntryFilter, IsHandled);
        if IsHandled then
            exit;

        SetCurrentKey("G/L Account No.", "Posting Date", "Entry No.", Open);
        case IncludeEntryFilter of
            IncludeEntryFilter::All:
                SetRange(Open);
            IncludeEntryFilter::Open:
                SetRange(Open, true);
            IncludeEntryFilter::Closed:
                SetRange(Open, false);
        end;

        OnAfterSetIncludeEntryFilter(Rec, IncludeEntryFilter);
    end;

    local procedure UpdateAmounts()
    begin
        ShowAppliedAmount := 0;
        ShowAmount := 0;
        if Rec."Applies-to ID" <> '' then begin
            ShowAmount := Rec."Remaining Amount";
            ShowAppliedAmount := ShowTotalAppliedAmount - Rec."Remaining Amount";
        end;
    end;

    local procedure IncludeEntryFilterOnAfterValid()
    begin
        CurrPage.Update(false);
    end;

    local procedure AfterGetCurrentRecord()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAfterGetCurrentRecord(IsHandled);
        if IsHandled then
            exit;

        UpdateAmounts();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAppliedEntries(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; OrgGLEntry: Record "G/L Entry"; var DynamicCaption: Text[100]; var IncludeEntryFilter: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApplication(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetIncludeEntryFilter(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; var IncludeEntryFilter: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAfterGetCurrentRecord(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAllEntries(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; var GLAccNo: Code[20]; var DynamicCaption: Text[100]; var IncludeEntryFilter: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetIncludeEntryFilter(var GLEntryApplicationBuffer: Record "G/L Entry Application Buffer"; var IncludeEntryFilter: Option; var IsHandled: Boolean)
    begin
    end;
}

#endif