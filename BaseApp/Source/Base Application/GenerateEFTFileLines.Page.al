page 10811 "Generate EFT File Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "EFT Export Workset";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Include; Include)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to either include or exclude this line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on the document that provides the basis for the entry on the journal line.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number that the journal line entry will be posted to.';
                }
                field(Amount; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the journal line consists of.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure Set(BankAccountNumber: Code[20])
    var
        EFTExport: Record "EFT Export";
    begin
        DeleteAll();
        EFTExport.SetCurrentKey("Bank Account No.", Transmitted);
        EFTExport.SetRange("Bank Account No.", BankAccountNumber);
        EFTExport.SetRange(Transmitted, false);
        if EFTExport.Find('-') then
            repeat
                EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(Description));
                TransferFields(EFTExport);
                Include := true;
                Insert;
            until EFTExport.Next() = 0;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure GetFirstColumn(): Text[50]
    begin
        if Rec.FindFirst() then
            exit(Rec."Journal Template Name" + ' · ' + Rec."Journal Batch Name" + ' · ' + Format(Rec."Line No.") + ' · ' + Format(Rec."Sequence No."))
        else
            exit('');
    end;

    [Scope('OnPrem')]
    procedure GetColumns(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    begin
        TempEFTExportWorkset.DeleteAll();
        SetRange(Include, true);
        if FindFirst then
            repeat
                TempEFTExportWorkset.TransferFields(Rec);
                TempEFTExportWorkset.Insert();
            until Next() = 0;
        Reset;
    end;

    [Scope('OnPrem')]
    procedure MarkUnmarkInclude(SetInclude: Boolean; BankAccountNumber: Code[20])
    begin
        SetCurrentKey("Bal. Account No.");
        SetRange("Bal. Account No.", BankAccountNumber);
        if FindFirst then
            repeat
                Include := SetInclude;
                Modify;
            until Next() = 0;
    end;
}

