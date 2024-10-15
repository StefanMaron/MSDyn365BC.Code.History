report 14934 "Write-off for Tax Ledger"
{
    Caption = 'Write-off for Tax Ledger';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Posted FA Doc. Header"; "Posted FA Doc. Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Writeoff));
            dataitem("Posted FA Doc. Line"; "Posted FA Doc. Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    FixedAsset: Record "Fixed Asset";
                    GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
                    FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
                    DimMgt: Codeunit DimensionManagement;
                    BookValue: Decimal;
                    DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
                begin
                    FixedAsset.Get("FA No.");
                    Window.Update(1, "FA No.");

                    FADeprBook.Get("FA No.", DeprBookCode);
                    FADeprBook.SetFilter("FA Posting Date Filter", '..%1', PostingDate);
                    FADeprBook.CalcFields("Book Value");
                    if FADeprBook."Book Value" = 0 then
                        CurrReport.Skip();

                    if not DeprBook."G/L Integration - Disposal" or FixedAsset."Budgeted Asset" then begin
                        with FAJnlLine do begin
                            LockTable();
                            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                            Init();
                            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                            FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                            "Line No." := FAJnlNextLineNo;
                            "Posting Date" := PostingDate;
                            "FA Posting Date" := PostingDate;
                            if "Posting Date" = "FA Posting Date" then
                                "Posting Date" := 0D;
                            Validate("FA Posting Type", "FA Posting Type"::Disposal);
                            Validate("FA No.", FixedAsset."No.");
                            "Document No." := "Posted FA Doc. Header"."No.";
                            Validate("Depreciation Book Code", DeprBookCode);
                            Validate("Depr. until FA Posting Date", not DeprBook."G/L Integration - Depreciation");
                            Validate(Amount, BookValue);
                            "Location Code" := FixedAsset."FA Location Code";
                            "Employee No." := FixedAsset."Responsible Employee";
                            CreateDimFromDefaultDim();
                            if Post then
                                FAJnlPostLine.FAJnlPostLine(FAJnlLine, true)
                            else
                                Insert(true);
                        end;
                    end else begin
                        with GenJnlLine do begin
                            LockTable();
                            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);

                            Init();
                            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                            GenJnlNextLineNo := GenJnlNextLineNo + 1000;
                            "Line No." := GenJnlNextLineNo;
                            "Posting Date" := PostingDate;
                            "FA Posting Date" := PostingDate;
                            if "Posting Date" = "FA Posting Date" then
                                "FA Posting Date" := 0D;
                            "Account Type" := "Account Type"::"Fixed Asset";
                            Validate("FA Posting Type", "FA Posting Type"::Disposal);
                            Validate("Account No.", FixedAsset."No.");
                            "Document No." := "Posted FA Doc. Header"."No.";
                            Validate("Depreciation Book Code", DeprBookCode);
                            Validate(Amount, BookValue);
                            "Employee No." := FixedAsset."Responsible Employee";
                            "FA Location Code" := FixedAsset."FA Location Code";
                            DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), "Account No.");
                            CreateDim(DefaultDimSource);
                            if Post then
                                GenJnlPostLine.RunWithCheck(GenJnlLine)
                            else
                                Insert(true);
                        end;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if UseNewPostDate then
                    PostingDate := NewPostingDate
                else
                    PostingDate := "Posting Date";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control1210001)
                {
                    ShowCaption = false;
                    field(UseNewPostDate; UseNewPostDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use New Posting Date';

                        trigger OnValidate()
                        begin
                            if not UseNewPostDate then
                                NewPostingDate := 0D;
                        end;
                    }
                    field(NewPostingDate; NewPostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Posting Date';
                        Editable = UseNewPostDate;
                    }
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Tax Depreciation Book");
        DeprBookCode := TaxRegisterSetup."Tax Depreciation Book";
        DeprBook.Get(DeprBookCode);

        if UseNewPostDate then
            if NewPostingDate = 0D then
                Error(Text000);

        Window.Open(
          Text001 +
          Text002);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FAJnlSetup: Record "FA Journal Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        Window: Dialog;
        NewPostingDate: Date;
        PostingDate: Date;
        DeprBookCode: Code[10];
        [InDataSet]
        UseNewPostDate: Boolean;
        Post: Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        Text000: Label 'You must specify New Posting Date.';
        Text001: Label 'Processing';
        Text002: Label 'Fixed Asset #1##########';
        [InDataSet]
        NewPostingDateTextBoxEnable: Boolean;

    [Scope('OnPrem')]
    procedure InitializeRequest(UseNewPostDate2: Boolean; NewPostingDate2: Date; Post2: Boolean)
    begin
        ClearAll();
        UseNewPostDate := UseNewPostDate2;
        NewPostingDate := NewPostingDate2;
        Post := Post2;
    end;
}

