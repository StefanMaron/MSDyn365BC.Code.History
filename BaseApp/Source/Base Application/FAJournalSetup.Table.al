table 5605 "FA Journal Setup"
{
    Caption = 'FA Journal Setup';

    fields
    {
        field(1; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            NotBlank = true;
            TableRelation = "Depreciation Book";
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(3; "FA Jnl. Template Name"; Code[10])
        {
            Caption = 'FA Jnl. Template Name';
            Editable = true;
            TableRelation = "FA Journal Template";

            trigger OnValidate()
            begin
                "FA Jnl. Batch Name" := '';
            end;
        }
        field(4; "FA Jnl. Batch Name"; Code[10])
        {
            Caption = 'FA Jnl. Batch Name';
            TableRelation = "FA Journal Batch".Name WHERE("Journal Template Name" = FIELD("FA Jnl. Template Name"));
        }
        field(5; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                "Gen. Jnl. Batch Name" := '';
            end;
        }
        field(6; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Gen. Jnl. Template Name"));
        }
        field(7; "Insurance Jnl. Template Name"; Code[10])
        {
            Caption = 'Insurance Jnl. Template Name';
            TableRelation = "Insurance Journal Template";

            trigger OnValidate()
            begin
                "Insurance Jnl. Batch Name" := '';
            end;
        }
        field(8; "Insurance Jnl. Batch Name"; Code[10])
        {
            Caption = 'Insurance Jnl. Batch Name';
            TableRelation = "Insurance Journal Batch".Name WHERE("Journal Template Name" = FIELD("Insurance Jnl. Template Name"));
        }
    }

    keys
    {
        key(Key1; "Depreciation Book Code", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        DeprBook.LockTable();
        DeprBook.Get("Depreciation Book Code");
    end;

    var
        Text000: Label 'You must specify %1.';
        DeprBook: Record "Depreciation Book";

    procedure GenJnlName(var DeprBook: Record "Depreciation Book"; var GenJnlLine: Record "Gen. Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("Gen. Jnl. Template Name");
        FAJnlSetup.TestField("Gen. Jnl. Batch Name");
        TemplateName := FAJnlSetup."Gen. Jnl. Template Name";
        BatchName := FAJnlSetup."Gen. Jnl. Batch Name";
        GenJnlTemplate.Get(TemplateName);
        GenJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetGenJnlRange(GenJnlLine, TemplateName, BatchName);
        NextLineNo := GenJnlLine."Line No.";
    end;

    procedure FAJnlName(var DeprBook: Record "Depreciation Book"; var FAJnlLine: Record "FA Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("FA Jnl. Template Name");
        FAJnlSetup.TestField("FA Jnl. Batch Name");
        TemplateName := FAJnlSetup."FA Jnl. Template Name";
        BatchName := FAJnlSetup."FA Jnl. Batch Name";
        FAJnlTemplate.Get(TemplateName);
        FAJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetFAJnlRange(FAJnlLine, TemplateName, BatchName);
        NextLineNo := FAJnlLine."Line No.";
    end;

    procedure InsuranceJnlName(var DeprBook: Record "Depreciation Book"; var InsuranceJnlLine: Record "Insurance Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("Insurance Jnl. Template Name");
        FAJnlSetup.TestField("Insurance Jnl. Batch Name");
        TemplateName := FAJnlSetup."Insurance Jnl. Template Name";
        BatchName := FAJnlSetup."Insurance Jnl. Batch Name";
        InsuranceJnlTempl.Get(TemplateName);
        InsuranceJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetInsuranceJnlRange(InsuranceJnlLine, TemplateName, BatchName);
        NextLineNo := InsuranceJnlLine."Line No.";
    end;

    procedure SetGenJnlTrailCodes(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        with GenJnlLine do begin
            GenJnlTemplate.Get("Journal Template Name");
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            "Source Code" := GenJnlTemplate."Source Code";
            "Reason Code" := GenJnlBatch."Reason Code";
            GenJnlBatch.TestField("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            GenJnlBatch.TestField("Bal. Account No.", '');
        end;
    end;

    procedure GetFAJnlDocumentNo(var FAJnlLine: Record "FA Journal Line"; PostingDate: Date; CreateError: Boolean): Code[20]
    var
        FAJnlBatch: Record "FA Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
    begin
        with FAJnlLine do begin
            FAJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if (FAJnlBatch."No. Series" <> '') and not Find('=><') then
                DocumentNo := NoSeriesMgt.GetNextNo(FAJnlBatch."No. Series", PostingDate, false);
            if (DocumentNo = '') and CreateError then
                Error(Text000, FieldCaption("Document No."));
        end;
        exit(DocumentNo);
    end;

    procedure GetGenJnlDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; CreateError: Boolean): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
    begin
        with GenJnlLine do begin
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if (GenJnlBatch."No. Series" <> '') and not Find('=><') then
                DocumentNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, false);
            if (DocumentNo = '') and CreateError then
                Error(Text000, FieldCaption("Document No."));
        end;
        exit(DocumentNo);
    end;

    procedure GetInsuranceJnlDocumentNo(var InsuranceJnlLine: Record "Insurance Journal Line"; PostingDate: Date): Code[20]
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
    begin
        with InsuranceJnlLine do begin
            InsuranceJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if (InsuranceJnlBatch."No. Series" <> '') and not Find('=><') then
                DocumentNo := NoSeriesMgt.GetNextNo(InsuranceJnlBatch."No. Series", PostingDate, false);
            if DocumentNo = '' then
                Error(Text000, FieldCaption("Document No."));
        end;
        exit(DocumentNo);
    end;

    procedure GetFANoSeries(var FAJnlLine: Record "FA Journal Line"): Code[20]
    var
        FAJnlBatch: Record "FA Journal Batch";
    begin
        FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
        if FAJnlBatch."No. Series" <> FAJnlBatch."Posting No. Series" then
            exit(FAJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure GetGenNoSeries(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."No. Series" <> GenJnlBatch."Posting No. Series" then
            exit(GenJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure GetInsuranceNoSeries(var InsuranceJnlLine: Record "Insurance Journal Line"): Code[20]
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");
        if InsuranceJnlBatch."No. Series" <> InsuranceJnlBatch."Posting No. Series" then
            exit(InsuranceJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure SetFAJnlTrailCodes(var FAJnlLine: Record "FA Journal Line")
    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
    begin
        with FAJnlLine do begin
            FAJnlTemplate.Get("Journal Template Name");
            FAJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            "Source Code" := FAJnlTemplate."Source Code";
            "Reason Code" := FAJnlBatch."Reason Code";
        end;
    end;

    procedure SetInsuranceJnlTrailCodes(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        with InsuranceJnlLine do begin
            InsuranceJnlTempl.Get("Journal Template Name");
            InsuranceJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            "Source Code" := InsuranceJnlTempl."Source Code";
            "Reason Code" := InsuranceJnlBatch."Reason Code";
        end;
    end;

    procedure IncFAJnlBatchName(var FAJnlBatch: Record "FA Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."FA Jnl. Template Name" = FAJnlBatch."Journal Template Name") and
                   (FAJnlSetup."FA Jnl. Batch Name" = FAJnlBatch.Name)
                then begin
                    FAJnlSetup."FA Jnl. Batch Name" := IncStr(FAJnlSetup."FA Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next = 0;
    end;

    procedure IncGenJnlBatchName(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."Gen. Jnl. Template Name" = GenJnlBatch."Journal Template Name") and
                   (FAJnlSetup."Gen. Jnl. Batch Name" = GenJnlBatch.Name)
                then begin
                    FAJnlSetup."Gen. Jnl. Batch Name" := IncStr(FAJnlSetup."Gen. Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next = 0;
    end;

    procedure IncInsuranceJnlBatchName(var InsuranceJnlBatch: Record "Insurance Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."Insurance Jnl. Template Name" = InsuranceJnlBatch."Journal Template Name") and
                   (FAJnlSetup."Insurance Jnl. Batch Name" = InsuranceJnlBatch.Name)
                then begin
                    FAJnlSetup."Insurance Jnl. Batch Name" := IncStr(FAJnlSetup."Insurance Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next = 0;
    end;
}

