report 17304 "Create FE from Sold FA"
{
    ApplicationArea = FixedAssets;
    Caption = 'Create FE from Sold FA';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = SORTING("FA Type") WHERE("FA Type" = FILTER(<> "Future Expense"));
            RequestFilterFields = "No.";
            dataitem("Depreciation Book"; "Depreciation Book")
            {
                DataItemTableView = SORTING(Code) WHERE("Posting Book Type" = CONST("Tax Accounting"));
                dataitem("FA Depreciation Book"; "FA Depreciation Book")
                {
                    DataItemLink = "Depreciation Book Code" = FIELD(Code);
                    DataItemTableView = SORTING("FA No.", "Depreciation Book Code") WHERE("Disposal Date" = FILTER(<> 0D));

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Book Value", "Gain/Loss");
                        if ("Book Value" = 0) and ("Gain/Loss" > 0) then begin
                            GainLoss += "Gain/Loss";
                            TestField("Depreciation Ending Date");
                            if DisposalDate = 0D then begin
                                DisposalDate := "Disposal Date";
                                DepreciationEndingDate := "Depreciation Ending Date";
                            end else begin
                                TestField("Disposal Date", DisposalDate);
                                TestField("Depreciation Ending Date", DepreciationEndingDate)
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("FA No.", "Fixed Asset"."No.");
                    end;
                }

                trigger OnPostDataItem()
                begin
                    if GainLoss = 0 then
                        exit;

                    with FE do begin
                        FE := FETemplate;
                        Blocked := false;
                        Inactive := false;
                        "No." := NoSeriesMgt.GetNextNo(NoSeriesCode, Today, true);
                        "No. Series" := NoSeriesCode;
                        "FA Type" := "FA Type"::"Future Expense";
                        "Created by FA No." := "Fixed Asset"."No.";
                        Insert;
                        Validate(Description, CopyStr(StrSubstNo(Text1000, "Fixed Asset"."No."), 1, MaxStrLen(Description)));
                    end;

                    with FEDeprBook do begin
                        FEDeprBook := FEDeprBookAccounting;
                        "FA No." := FE."No.";
                        Description := FE.Description;
                        Insert(true);
                        Validate("Depreciation Starting Date", 0D);
                        Modify;

                        FEDeprBook := FEDeprBookTaxAccounting;
                        "FA No." := FE."No.";
                        Description := FE.Description;
                        Insert(true);
                        Validate("Depreciation Starting Date", CalcDate('<CM+1D>', DisposalDate));
                        Validate("Depreciation Ending Date", FATaxDeprBook."Depreciation Ending Date");
                        Modify;
                    end;

                    if not DeprBookAccounting."G/L Integration - Acq. Cost" then begin
                        FEJnlSetup.FAJnlName(DeprBookAccounting, FEJnlLineTmp, JnlNextLineNo);
                        FEJnlLineTmp."FA No." := FE."No.";
                        FEJnlLineTmp."FA Posting Type" := FEJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        FEJnlLineTmp."FA Posting Date" := DisposalDate;
                        FEJnlLineTmp.Amount := GainLoss;
                        FEJnlLineTmp."Line No." := FEJnlLineTmp."Line No." + 1;
                        FEJnlLineTmp."Depreciation Book Code" := FEDeprBookAccounting."Depreciation Book Code";
                        FEJnlLineTmp.Description := FE.Description;
                        FEJnlLineTmp.Insert();
                    end else begin
                        FEJnlSetup.GenJnlName(DeprBookAccounting, GenJnlLine, JnlNextLineNo);
                        GenJnlLineTmp."Account No." := FE."No.";
                        GenJnlLineTmp."FA Posting Date" := DisposalDate;
                        GenJnlLineTmp."Posting Date" := DisposalDate;
                        GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        GenJnlLineTmp.Amount := GainLoss;
                        GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                        GenJnlLineTmp."Depreciation Book Code" := FEDeprBookAccounting."Depreciation Book Code";
                        GenJnlLineTmp.Insert();
                    end;

                    if not DeprBookTaxAccounting."G/L Integration - Acq. Cost" then begin
                        FEJnlSetup.FAJnlName(DeprBookTaxAccounting, FEJnlLineTmp, JnlNextLineNo);
                        FEJnlLineTmp."FA No." := FE."No.";
                        FEJnlLineTmp."FA Posting Type" := FEJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        FEJnlLineTmp."FA Posting Date" := DisposalDate;
                        FEJnlLineTmp.Amount := FATaxDeprBook."Gain/Loss";
                        FEJnlLineTmp."Line No." := FEJnlLineTmp."Line No." + 1;
                        FEJnlLineTmp."Depreciation Book Code" := FEDeprBookTaxAccounting."Depreciation Book Code";
                        FEJnlLineTmp.Description := FE.Description;
                        FEJnlLineTmp.Insert();
                    end else begin
                        FEJnlSetup.GenJnlName(DeprBookTaxAccounting, GenJnlLine, JnlNextLineNo);
                        GenJnlLineTmp."Account No." := FE."No.";
                        GenJnlLineTmp."FA Posting Date" := DisposalDate;
                        GenJnlLineTmp."Posting Date" := DisposalDate;
                        GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        GenJnlLineTmp.Amount := FATaxDeprBook."Gain/Loss";
                        GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                        GenJnlLineTmp."Depreciation Book Code" := FEDeprBookTaxAccounting."Depreciation Book Code";
                        GenJnlLineTmp.Description := FE.Description;
                        GenJnlLineTmp.Insert();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GainLoss := 0;
                DisposalDate := 0D;
                DepreciationEndingDate := 0D;

                FE.Reset();
                FE.SetCurrentKey("Created by FA No.");
                FE.SetRange("Created by FA No.", "No.");
                if FE.FindFirst then
                    CurrReport.Skip();

                FATaxDeprBook.SetRange("FA No.", "No.");
                if FATaxDeprBook.FindSet then
                    repeat
                        DeprBook.Get(FATaxDeprBook."Depreciation Book Code");
                    until (FATaxDeprBook.Next = 0) or (DeprBook."Posting Book Type" = DeprBook."Posting Book Type"::"Tax Accounting");
                FATaxDeprBook.CalcFields("Gain/Loss");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FETemplateNo; FETemplateNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FE Template';
                        TableRelation = "Fixed Asset" WHERE("FA Type" = CONST("Future Expense"),
                                                             Blocked = CONST(true),
                                                             Inactive = CONST(true));

                        trigger OnValidate()
                        begin
                            FETemplateNoOnAfterValidate();
                        end;
                    }
                    field(NoSeriesCode; NoSeriesCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FE No. Series';
                        TableRelation = "No. Series";

                        trigger OnValidate()
                        begin
                            NoSeriesCodeOnAfterValidate;
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No';
                        ToolTip = 'Specifies the number of the related document.';
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

    trigger OnPostReport()
    begin
        with FEJnlLine do begin
            FEJnlLineTmp.Reset();
            if FEJnlLineTmp.Find('-') then begin
                LockTable();
                repeat
                    if (FEJnlLineTmp."Journal Template Name" <> "Journal Template Name") or
                       (FEJnlLineTmp."Journal Batch Name" <> "Journal Batch Name")
                    then begin
                        DeprBook.Get(FEJnlLineTmp."Depreciation Book Code");
                        FEJnlSetup.FAJnlName(DeprBook, FEJnlLine, JnlNextLineNo);
                        PostingNoSeries := FEJnlSetup.GetFANoSeries(FEJnlLine);
                        if DocumentNo = '' then
                            DocumentNo2 := FEJnlSetup.GetFAJnlDocumentNo(FEJnlLine, FEJnlLineTmp."FA Posting Date", true)
                        else
                            DocumentNo2 := DocumentNo;
                    end;
                    Init;
                    FEJnlSetup.SetFAJnlTrailCodes(FEJnlLine);
                    "FA Posting Date" := FEJnlLineTmp."FA Posting Date";
                    "Posting Date" := 0D;
                    "FA Posting Type" := FEJnlLineTmp."FA Posting Type";
                    Validate("FA No.", FEJnlLineTmp."FA No.");
                    "Document No." := DocumentNo2;
                    "Posting No. Series" := PostingNoSeries;
                    Description := FEJnlLineTmp.Description;
                    Validate("Depreciation Book Code", FEJnlLineTmp."Depreciation Book Code");
                    Validate(Amount, FEJnlLineTmp.Amount);
                    "No. of Depreciation Days" := FEJnlLineTmp."No. of Depreciation Days";
                    JnlNextLineNo := JnlNextLineNo + 10000;
                    "Line No." := JnlNextLineNo;
                    "Depr. Period Starting Date" := FEJnlLineTmp."Depr. Period Starting Date";
                    Insert(true);
                    FEJnlLineTmp.Delete();
                until FEJnlLineTmp.Next = 0;
            end;
        end;
    end;

    trigger OnPreReport()
    begin
        FETemplate.Get(FETemplateNo);

        with FEDeprBook do begin
            SetRange("FA No.", FETemplateNo);
            FEDeprBookAccounting.FindFirst;
            repeat
                FEDeprBookAccounting := FEDeprBook;
                if not DeprBookAccounting.Get("Depreciation Book Code") then
                    DeprBookAccounting.Init();
            until (Next(1) = 0) or
                  (DeprBookAccounting."Posting Book Type" = DeprBookAccounting."Posting Book Type"::Accounting);
        end;

        if DeprBookAccounting."Posting Book Type" = DeprBookAccounting."Posting Book Type"::Accounting then begin
            FEDeprBookAccounting.TestField("Depreciation Method", FEDeprBookAccounting."Depreciation Method"::"Straight-Line");
            FEJnlSetup.FAJnlName(DeprBookAccounting, FEJnlLineTmp, JnlNextLineNo);
            FEJnlTemplate.Get(FEJnlLineTmp."Journal Template Name");
            FEJnlTemplate.TestField(Type, FEJnlTemplate.Type::"Future Expenses");
        end else begin
            DeprBookAccounting."Posting Book Type" := DeprBookAccounting."Posting Book Type"::Accounting;
            Error(Text1001,
              FETemplateNo,
              DeprBookAccounting.TableCaption,
              DeprBookAccounting.FieldCaption("Posting Book Type"),
              DeprBookAccounting."Posting Book Type");
        end;

        with FEDeprBook do begin
            Find('-');
            repeat
                FEDeprBookTaxAccounting := FEDeprBook;
                if not DeprBookTaxAccounting.Get("Depreciation Book Code") then
                    DeprBookTaxAccounting.Init();
            until (Next(1) = 0) or
                  (DeprBookTaxAccounting."Posting Book Type" = DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting");
        end;

        if DeprBookTaxAccounting."Posting Book Type" = DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting" then begin
            FEDeprBookTaxAccounting.TestField("Depreciation Method", FEDeprBookTaxAccounting."Depreciation Method"::"Straight-Line");
            FEJnlSetup.FAJnlName(DeprBookTaxAccounting, FEJnlLineTmp, JnlNextLineNo);
            FEJnlTemplate.Get(FEJnlLineTmp."Journal Template Name");
            FEJnlTemplate.TestField(Type, FEJnlTemplate.Type::"Future Expenses");
        end else begin
            DeprBookTaxAccounting."Posting Book Type" := DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting";
            Error(Text1001,
              FETemplateNo,
              DeprBookTaxAccounting.TableCaption,
              DeprBookTaxAccounting.FieldCaption("Posting Book Type"),
              DeprBookTaxAccounting."Posting Book Type");
        end;
    end;

    var
        FE: Record "Fixed Asset";
        FETemplate: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DeprBookAccounting: Record "Depreciation Book";
        DeprBookTaxAccounting: Record "Depreciation Book";
        FEDeprBook: Record "FA Depreciation Book";
        FEDeprBookAccounting: Record "FA Depreciation Book";
        FEDeprBookTaxAccounting: Record "FA Depreciation Book";
        FATaxDeprBook: Record "FA Depreciation Book";
        FEJnlSetup: Record "FA Journal Setup";
        FEJnlTemplate: Record "FA Journal Template";
        FEJnlLine: Record "FA Journal Line";
        FEJnlLineTmp: Record "FA Journal Line" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineTmp: Record "Gen. Journal Line" temporary;
        NoSeries: Record "No. Series";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        FETemplateNo: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        NoSeriesCode: Code[20];
        Text1000: Label 'FA %1 was disposed with loss';
        Text1001: Label '%2 with %3 %4 is not defined for FE %1.';
        PostingNoSeries: Code[20];
        JnlNextLineNo: Integer;
        GainLoss: Decimal;
        DisposalDate: Date;
        DepreciationEndingDate: Date;

    local procedure FETemplateNoOnAfterValidate()
    begin
        if not FETemplate.Get(FETemplateNo) then
            FETemplate.Init();
    end;

    local procedure NoSeriesCodeOnAfterValidate()
    begin
        if not NoSeries.Get(NoSeriesCode) then
            NoSeries.Init();
    end;
}

