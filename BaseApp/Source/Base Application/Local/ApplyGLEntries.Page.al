page 10842 "Apply G/L Entries"
{
    Caption = 'Apply G/L Entries';
    DataCaptionExpression = GetCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "G/L Entry" = rimd;
    SourceTable = "G/L Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the G/L entries were posted.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the G/L entries apply to';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the general ledger entries apply to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies additional information about the general ledger entry.';
                }
                field(Letter; Letter)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a three letter combination that is set automatically when you post the application.';
                }
                field("Letter Date"; Rec."Letter Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the most recent date on the entries that are being applied.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the ID when you choose Set Applies-to ID. The field is cleared when you post the application.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that will be applied.';
                }
            }
            group(Control1120000)
            {
                ShowCaption = false;
                field(ApplnCode; ApplnCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Appln. Code';
                    Editable = false;
                    ToolTip = 'Specifies the letters of this line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GLEntry.Reset();
                        GLEntry.SetRange(Letter, Letter);
                        PAGE.RunModal(PAGE::"General Ledger Entries", GLEntry);
                    end;
                }
                field(Debit; Debit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Debit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the accumulated debit amount of all the lines applied to this line.';
                }
                field(Credit; Credit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit (LCY';
                    Editable = false;
                    ToolTip = 'Specifies the accumulated credit amount of all the lines applied to this line.';
                }
                field("Debit - Credit"; Debit - Credit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the accumulated balance of all the lines applied to this line.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Application)
            {
                Caption = 'Application';
                Image = Apply;
                action(SetAppliesToID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    ShortCutKey = 'F7';
                    ToolTip = 'Fill in the Applies-to ID field on the selected non-applied entry with the document number of the entry on the payment. NOTE: This only works for non-applied entries.';

                    trigger OnAction()
                    begin
                        SetAppliesToIDField(true);
                    end;
                }
                action(SetAppliesToIDAll)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Applies-to ID (All)';
                    Image = SelectLineToApply;
                    ToolTip = 'Fill in the Applies-to ID field on the selected entry with the document number of the entry on the payment. NOTE: This works for both applied and non-applied entries.';

                    trigger OnAction()
                    begin
                        SetAppliesToIDField(false);
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
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforePostApplication(Rec, IsHandled);
                        if IsHandled then
                            exit;
                        GLEntriesApplication.Validate(Rec);
                    end;
                }
                action(UnapplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unapply Entries';
                    Image = UnApply;
                    ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                    trigger OnAction()
                    begin
                        Clear(GLEntry);
                        GLEntry.SetRange("G/L Account No.", "G/L Account No.");
                        GLEntry.SetRange(Letter, Letter);
                        if GLEntry.Find('-') then
                            repeat
                                GLEntry.Letter := '';
                                GLEntry."Letter Date" := 0D;
                                GLEntry.Modify();
                            until GLEntry.Next() = 0;
                        if Letter <> '' then
                            Message('%1', Text001);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetAppliesToID_Promoted; SetAppliesToID)
                {
                }
                actionref(SetAppliesToIDAll_Promoted; SetAppliesToIDAll)
                {
                }
                actionref(PostApplication_Promoted; PostApplication)
                {
                }
                actionref(UnapplyEntries_Promoted; UnapplyEntries)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntriesApplication: Codeunit "G/L Entry Application";
        ApplnCode: Code[10];
        Debit: Decimal;
        Credit: Decimal;
        Text001: Label 'Successfully unapplied';

    [Scope('OnPrem')]
    procedure CalcAmount()
    var
        GLE: Record "G/L Entry";
    begin
        ApplnCode := Letter;
        Debit := 0;
        Credit := 0;

        if Letter <> '' then begin
            GLE.SetRange("G/L Account No.", "G/L Account No.");
            GLE.SetRange(Letter, Letter);
            if GLE.Find('-') then
                repeat
                    Debit := Debit + GLE."Debit Amount";
                    Credit := Credit + GLE."Credit Amount";
                until GLE.Next() = 0;
        end else begin
            Debit := "Debit Amount";
            Credit := "Credit Amount";
        end;
    end;

    local procedure GetCaption(): Text[250]
    begin
        if GLAcc."No." <> "G/L Account No." then
            if not GLAcc.Get("G/L Account No.") then
                if GetFilter("G/L Account No.") <> '' then
                    if GLAcc.Get(GetRangeMin("G/L Account No.")) then;
        exit(StrSubstNo('%1 %2', GLAcc."No.", GLAcc.Name))
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        CalcAmount();
    end;

    local procedure SetAppliesToIDField(OnlyNotApplied: Boolean)
    begin
        Clear(GLEntry);
        GLEntry.Copy(Rec);
        CurrPage.SetSelectionFilter(GLEntry);
        GLEntriesApplication.SetAppliesToID(GLEntry, OnlyNotApplied);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApplication(var GLEntry: Record "G/L Entry"; var IsHandled: Boolean);
    begin
    end;
}

