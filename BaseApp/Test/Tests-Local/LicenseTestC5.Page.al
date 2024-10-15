page 130099 "License Test - C5"
{
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    Permissions = TableData "G/L Entry" = rimd;
    ShowFilter = false;
    SourceTable = "License Information";

    layout
    {
        area(content)
        {
            group(Control19)
            {
                ShowCaption = false;
                field(TransactionNo; TransactionNo)
                {
                    Caption = 'Enter Transaction No.';
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Enter Posting Date';
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                field(Near; NearMaxLimit)
                {
                    Caption = 'Near Max Limit';
                    Editable = false;
                }
                field("Max"; MaxLimit)
                {
                    Caption = 'Max Limit';
                    Editable = false;
                }
            }
            group(Control5)
            {
                ShowCaption = false;
                field(ExecutePermission; SysObjExecutePerm(6010) + ' & ' + SysObjExecutePerm(6011))
                {
                    Caption = 'Execute Permission';
                }
            }
            repeater(Group)
            {
                Editable = false;
                field("Line No."; "Line No.")
                {
                }
                field(Text; Text)
                {
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(MakeTransaction)
            {
                Caption = 'Make Transaction';
                Image = Add;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    MakeGLEntry(TransactionNo, PostingDate);
                end;
            }
            action(PostTransaction)
            {
                Caption = 'Post Transaction';
                Image = Post;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    PostGLJnlLine(PostingDate);
                end;
            }
            action(GLEntries)
            {
                Caption = 'G/L Entries';
                Image = GeneralLedger;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "General Ledger Entries";
            }
            action(AccountingPeriods)
            {
                Caption = 'Accounting Periods';
                Image = AccountingPeriods;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Accounting Periods";
            }
            separator(Action13)
            {
            }
            action(DeleteEntries)
            {
                Caption = 'DeleteEntries';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    InitTest(0);
                end;
            }
        }
    }

    var
        TransactionNo: Integer;
        PostingDate: Date;

    local procedure PostGLJnlLine(PostingDate: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJnlLine.Init;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", GetAccountNo(true));
        GenJnlLine.Validate("Document No.", Format(CurrentDateTime));
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate(Amount, 1000);
        GenJnlLine."Bal. Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", GetAccountNo(false));

        GenJnlPostLine.RunWithCheck(GenJnlLine);

        TransactionNo := GetLastTransactionNo;
    end;

    local procedure InitTest(TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetFilter("Transaction No.", '%1..', TransactionNo);
        GLEntry.DeleteAll;
    end;

    local procedure MakeGLEntry(TransactionNo: Integer; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
        EntryNo: Integer;
    begin
        EntryNo := 1;
        if GLEntry.FindLast then
            EntryNo := GLEntry."Entry No." + 1;

        GLEntry."Entry No." := EntryNo;
        GLEntry."Transaction No." := TransactionNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Insert;
    end;

    local procedure GetAccountNo("Ascending": Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Ascending := Ascending;
        GLAccount.SetRange("Direct Posting", true);
        if GLAccount.FindFirst then
            exit(GLAccount."No.");
        exit('');
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindLast then
            exit(GLEntry."Transaction No.");
        exit(0);
    end;

    local procedure MaxLimit(): Integer
    begin
        exit(2500);
    end;

    local procedure NearMaxLimit(): Integer
    begin
        exit(0.95 * MaxLimit);
    end;

    local procedure SysObjExecutePerm(ObjID: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if LicensePermission.Get(LicensePermission."Object Type"::System, ObjID) then
            if LicensePermission."Execute Permission" = LicensePermission."Execute Permission"::Yes then
                exit(StrSubstNo('%1 YES', ObjID));
        exit(StrSubstNo('%1 NO', ObjID));
    end;
}

