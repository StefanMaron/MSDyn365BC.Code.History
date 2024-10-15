codeunit 12472 "Copy FA Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text001: Label '%1 %2 cannot be copied onto itself.';
        Text002: Label 'The existing lines for %1 %2 will be deleted.\\';
        Text003: Label 'Do you want to continue?';
        Text004: Label 'The document line(s) with a G/L account where direct posting is not allowed have not been copied to the new document by the Copy Document batch job.';
        FADocType: Option Writeoff,Release,Disposal,"Posted Writeoff","Posted Release","Posted Disposal";
        IncludeHeader: Boolean;
        CreateToHeader: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties(NewIncludeHeader: Boolean; NewCreateToHeader: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        CreateToHeader := NewCreateToHeader;
    end;

    [Scope('OnPrem')]
    procedure FADocHeaderDocType(DocType: Option): Integer
    var
        FADocHeader: Record "FA Document Header";
    begin
        case DocType of
            FADocType::Writeoff:
                exit(FADocHeader."Document Type"::Writeoff);
            FADocType::Release:
                exit(FADocHeader."Document Type"::Release);
            FADocType::Disposal:
                exit(FADocHeader."Document Type"::Movement);
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyFADoc(FromDocType: Option; FromDocNo: Code[20]; var ToFADocHeader: Record "FA Document Header")
    var
        FASetup: Record "Sales & Receivables Setup";
        ToFADocLine: Record "FA Document Line";
        OldFADocHeader: Record "FA Document Header";
        FromFADocHeader: Record "FA Document Header";
        FromFADocLine: Record "FA Document Line";
        FromPostedFADocHeader: Record "Posted FA Doc. Header";
        FromPostedFADocLine: Record "Posted FA Doc. Line";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
    begin
        with ToFADocHeader do begin
            if not CreateToHeader then begin
                if FromDocNo = '' then
                    Error(Text000);
                Find;
            end;
            case FromDocType of
                FADocType::Writeoff,
                FADocType::Release,
                FADocType::Disposal:
                    begin
                        FromFADocHeader.Get(FADocHeaderDocType(FromDocType), FromDocNo);
                        if (FromFADocHeader."Document Type" = "Document Type") and
                           (FromFADocHeader."No." = "No.")
                        then
                            Error(
                              Text001,
                              "Document Type", "No.");
                    end;
                FADocType::"Posted Writeoff",
              FADocType::"Posted Release",
              FADocType::"Posted Disposal":
                    FromPostedFADocHeader.Get(FADocHeaderDocType(FromDocType - 3), FromDocNo);
            end;

            ToFADocLine.LockTable();

            if CreateToHeader then begin
                Insert(true);
                ToFADocLine.SetRange("Document Type", "Document Type");
                ToFADocLine.SetRange("Document No.", "No.");
            end else begin
                ToFADocLine.SetRange("Document Type", "Document Type");
                ToFADocLine.SetRange("Document No.", "No.");
                if IncludeHeader then
                    if not ToFADocLine.IsEmpty() then begin
                        Commit();
                        if not
                           Confirm(
                             Text002 +
                             Text003, true,
                             "Document Type", "No.")
                        then
                            exit;
                        ToFADocLine.DeleteAll(true);
                    end;
            end;

            if ToFADocLine.FindLast() then
                NextLineNo := ToFADocLine."Line No."
            else
                NextLineNo := 0;

            if IncludeHeader then begin
                OldFADocHeader := ToFADocHeader;
                case FromDocType of
                    FADocType::Writeoff,
                    FADocType::Release,
                    FADocType::Disposal:
                        begin
                            TransferFields(FromFADocHeader, false);
                            "Posting Date" := OldFADocHeader."Posting Date";
                        end;
                    FADocType::"Posted Writeoff",
                  FADocType::"Posted Release",
                  FADocType::"Posted Disposal":
                        TransferFields(FromPostedFADocHeader, false);
                end;
                "No. Series" := OldFADocHeader."No. Series";
                "Posting Description" := OldFADocHeader."Posting Description";
                "Posting No." := OldFADocHeader."Posting No.";
                "Posting No. Series" := OldFADocHeader."Posting No. Series";
                "No. Printed" := 0;
            end;

            LinesNotCopied := 0;
            case FromDocType of
                FADocType::Writeoff,
                FADocType::Release,
                FADocType::Disposal:
                    begin
                        FromFADocLine.Reset();
                        FromFADocLine.SetRange("Document Type", FromFADocHeader."Document Type");
                        FromFADocLine.SetRange("Document No.", FromFADocHeader."No.");
                        if FromFADocLine.FindSet() then
                            repeat
                                CopyFADocLine(ToFADocHeader, ToFADocLine, FromFADocLine, NextLineNo, LinesNotCopied);
                            until FromFADocLine.Next() = 0;
                    end;
                FADocType::"Posted Writeoff",
                FADocType::"Posted Release",
                FADocType::"Posted Disposal":
                    begin
                        FASetup.Get();
                        FromFADocHeader.TransferFields(FromPostedFADocHeader);
                        FromPostedFADocLine.Reset();
                        FromPostedFADocLine.SetRange("Document No.", FromPostedFADocHeader."No.");
                        if FromPostedFADocLine.FindSet() then
                            repeat
                                FromFADocLine.TransferFields(FromPostedFADocLine);
                                CopyFADocLine(
                                  ToFADocHeader, ToFADocLine, FromFADocLine,
                                  NextLineNo, LinesNotCopied);
                            until FromPostedFADocLine.Next() = 0;
                    end;
            end;
        end;

        if LinesNotCopied > 0 then
            Message(Text004);
    end;

    [Scope('OnPrem')]
    procedure ShowFADoc(ToFADocHeader: Record "FA Document Header")
    begin
        with ToFADocHeader do
            case "Document Type" of
                "Document Type"::Writeoff:
                    PAGE.Run(PAGE::"FA Writeoff Act", ToFADocHeader);
                "Document Type"::Release:
                    PAGE.Run(PAGE::"FA Release Act", ToFADocHeader);
                "Document Type"::Movement:
                    PAGE.Run(PAGE::"FA Movement Act", ToFADocHeader);
            end;
    end;

    local procedure CopyFADocLine(var ToFADocHeader: Record "FA Document Header"; var ToFADocLine: Record "FA Document Line"; var FromFADocLine: Record "FA Document Line"; var NextLineNo: Integer; var LinesNotCopied: Integer)
    var
        CopyThisLine: Boolean;
    begin
        CopyThisLine := true;
        ToFADocLine := FromFADocLine;
        NextLineNo := NextLineNo + 10000;
        ToFADocLine."Document Type" := ToFADocHeader."Document Type";
        ToFADocLine."Document No." := ToFADocHeader."No.";
        ToFADocLine."Line No." := NextLineNo;
        if CopyThisLine then
            ToFADocLine.Insert
        else
            LinesNotCopied := LinesNotCopied + 1;
    end;
}

