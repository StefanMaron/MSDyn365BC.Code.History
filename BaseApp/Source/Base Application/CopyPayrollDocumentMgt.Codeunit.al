codeunit 17408 "Copy Payroll Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text002: Label 'The existing lines for %1 will be deleted.\\';
        Text003: Label 'Do you want to continue?';
        DocType: Option "Payroll Document","Posted Payroll Document";
        IncludeHeader: Boolean;
        CreateToHeader: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties(NewIncludeHeader: Boolean; NewCreateToHeader: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        CreateToHeader := NewCreateToHeader;
    end;

    [Scope('OnPrem')]
    procedure CopyPayrollDoc(FromDocType: Option; FromDocNo: Code[20]; var ToPayrollDoc: Record "Payroll Document")
    var
        ToPayrollDocLine: Record "Payroll Document Line";
        OldPayrollDoc: Record "Payroll Document";
        FromPayrollDoc: Record "Payroll Document";
        FromPayrollDocLine: Record "Payroll Document Line";
        FromPostedPayrollDoc: Record "Posted Payroll Document";
        FromPostedPayrollDocLine: Record "Posted Payroll Document Line";
        ReleasePayrollDoc: Codeunit "Release Payroll Document";
        ReleaseDocument: Boolean;
        NextLineNo: Integer;
    begin
        with ToPayrollDoc do begin
            if not CreateToHeader then begin
                if FromDocNo = '' then
                    Error(Text000);
                Find;
            end;
            case FromDocType of
                DocType::"Payroll Document":
                    FromPayrollDoc.Get(FromDocNo);
                DocType::"Posted Payroll Document":
                    FromPostedPayrollDoc.Get(FromDocNo);
            end;

            ToPayrollDocLine.LockTable;

            if CreateToHeader then begin
                Insert(true);
                ToPayrollDocLine.SetRange("Document No.", "No.");
            end else begin
                ToPayrollDocLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if not ToPayrollDocLine.IsEmpty then begin
                        Commit;
                        if not Confirm(Text002 + Text003, true, "No.") then
                            exit;
                        ToPayrollDocLine.DeleteAll(true);
                    end;
            end;

            if ToPayrollDocLine.FindLast then
                NextLineNo := ToPayrollDocLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then begin
                OldPayrollDoc := ToPayrollDoc;
                case FromDocType of
                    DocType::"Payroll Document":
                        begin
                            TransferFields(FromPayrollDoc, false);
                            "Posting Date" := OldPayrollDoc."Posting Date";
                        end;
                    DocType::"Posted Payroll Document":
                        TransferFields(FromPostedPayrollDoc, false);
                end;
                if Status = Status::Released then begin
                    Status := Status::Open;
                    ReleaseDocument := true;
                end;
                "No. Series" := OldPayrollDoc."No. Series";
                "Posting Description" := OldPayrollDoc."Posting Description";
                "Posting No. Series" := OldPayrollDoc."Posting No. Series";

                if CreateToHeader then
                    Modify(true)
                else
                    Modify;
            end;

            case FromDocType of
                DocType::"Payroll Document":
                    begin
                        FromPayrollDocLine.Reset;
                        FromPayrollDocLine.SetRange("Document No.", FromPayrollDoc."No.");
                        if FromPayrollDocLine.FindSet then
                            repeat
                                CopyDocLine(ToPayrollDoc, ToPayrollDocLine, FromPayrollDocLine, NextLineNo);
                            until FromPayrollDocLine.Next = 0;
                    end;
                DocType::"Posted Payroll Document":
                    begin
                        FromPayrollDoc.TransferFields(FromPostedPayrollDoc);
                        FromPostedPayrollDocLine.Reset;
                        FromPostedPayrollDocLine.SetRange("Document No.", FromPostedPayrollDoc."No.");
                        if FromPostedPayrollDocLine.FindSet then
                            repeat
                                FromPayrollDocLine.TransferFields(FromPostedPayrollDocLine);
                                CopyDocLine(ToPayrollDoc, ToPayrollDocLine, FromPayrollDocLine, NextLineNo);
                            until FromPostedPayrollDocLine.Next = 0;
                    end;
            end;
        end;

        if ReleaseDocument then begin
            ToPayrollDoc.Status := ToPayrollDoc.Status::Released;
            ReleasePayrollDoc.Reopen(ToPayrollDoc);
        end;
    end;

    local procedure CopyDocLine(var ToPayrollDoc: Record "Payroll Document"; var ToPayrollDocLine: Record "Payroll Document Line"; var FromPayrollDocLine: Record "Payroll Document Line"; var NextLineNo: Integer)
    begin
        ToPayrollDocLine := FromPayrollDocLine;
        NextLineNo := NextLineNo + 10000;
        ToPayrollDocLine."Document No." := ToPayrollDoc."No.";
        ToPayrollDocLine."Line No." := NextLineNo;
        ToPayrollDocLine.Insert;
    end;
}

