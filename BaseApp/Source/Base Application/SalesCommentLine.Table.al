table 44 "Sales Comment Line"
{
    Caption = 'Sales Comment Line';
    DrillDownPageID = "Sales Comment List";
    LookupPageID = "Sales Comment List";

    fields
    {
        field(1; "Document Type"; Enum "Sales Comment Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.SetRange("Document Line No.", "Document Line No.");
        SalesCommentLine.SetRange(Date, WorkDate);
        if not SalesCommentLine.FindFirst then
            Date := WorkDate;

        OnAfterSetUpNewLine(Rec, SalesCommentLine);
    end;

    procedure CopyComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLine2: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyComments(SalesCommentLine, ToDocumentType, IsHandled, FromDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        SalesCommentLine.SetRange("Document Type", FromDocumentType);
        SalesCommentLine.SetRange("No.", FromNumber);
        if SalesCommentLine.FindSet() then
            repeat
                SalesCommentLine2 := SalesCommentLine;
                SalesCommentLine2."Document Type" := ToDocumentType;
                SalesCommentLine2."No." := ToNumber;
                SalesCommentLine2.Insert();
            until SalesCommentLine.Next() = 0;
    end;

    procedure CopyLineComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLineNo: Integer)
    var
        SalesCommentLineSource: Record "Sales Comment Line";
        SalesCommentLineTarget: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyLineComments(
          SalesCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber, FromDocumentLineNo, ToDocumentLineNo);
        if IsHandled then
            exit;

        SalesCommentLineSource.SetRange("Document Type", FromDocumentType);
        SalesCommentLineSource.SetRange("No.", FromNumber);
        SalesCommentLineSource.SetRange("Document Line No.", FromDocumentLineNo);
        if SalesCommentLineSource.FindSet() then
            repeat
                SalesCommentLineTarget := SalesCommentLineSource;
                SalesCommentLineTarget."Document Type" := ToDocumentType;
                SalesCommentLineTarget."No." := ToNumber;
                SalesCommentLineTarget."Document Line No." := ToDocumentLineNo;
                SalesCommentLineTarget.Insert();
            until SalesCommentLineSource.Next() = 0;
    end;

    procedure CopyHeaderComments(FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    var
        SalesCommentLineSource: Record "Sales Comment Line";
        SalesCommentLineTarget: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyHeaderComments(SalesCommentLineTarget, IsHandled, FromDocumentType, ToDocumentType, FromNumber, ToNumber);
        if IsHandled then
            exit;

        SalesCommentLineSource.SetRange("Document Type", FromDocumentType);
        SalesCommentLineSource.SetRange("No.", FromNumber);
        SalesCommentLineSource.SetRange("Document Line No.", 0);
        if SalesCommentLineSource.FindSet() then
            repeat
                SalesCommentLineTarget := SalesCommentLineSource;
                SalesCommentLineTarget."Document Type" := ToDocumentType;
                SalesCommentLineTarget."No." := ToNumber;
                SalesCommentLineTarget.Insert();
            until SalesCommentLineSource.Next() = 0;
    end;

    procedure DeleteComments(DocType: Option; DocNo: Code[20])
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        if not IsEmpty then
            DeleteAll();
    end;

    procedure ShowComments(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        SalesCommentSheet: Page "Sales Comment Sheet";
    begin
        SetRange("Document Type", DocType);
        SetRange("No.", DocNo);
        SetRange("Document Line No.", DocLineNo);
        Clear(SalesCommentSheet);
        SalesCommentSheet.SetTableView(Rec);
        SalesCommentSheet.RunModal;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var SalesCommentLineRec: Record "Sales Comment Line"; var SalesCommentLineFilter: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComments(var SalesCommentLine: Record "Sales Comment Line"; ToDocumentType: Integer; var IsHandled: Boolean; FromDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20]; FromDocumentLineNo: Integer; ToDocumentLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyHeaderComments(var SalesCommentLine: Record "Sales Comment Line"; var IsHandled: Boolean; FromDocumentType: Integer; ToDocumentType: Integer; FromNumber: Code[20]; ToNumber: Code[20])
    begin
    end;
}

