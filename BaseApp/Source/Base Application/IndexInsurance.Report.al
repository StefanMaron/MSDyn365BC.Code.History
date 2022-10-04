report 5691 "Index Insurance"
{
    ApplicationArea = FixedAssets;
    Caption = 'Index Insurance';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";

            trigger OnAfterGetRecord()
            begin
                if Blocked or Inactive then
                    CurrReport.Skip();
                Window.Update(1, "No.");
                TempInsurance.DeleteAll();
                InsCoverageLedgEntry.SetRange("FA No.", "No.");
                InsCoverageLedgEntry.SetRange("Posting Date", 0D, PostingDate);
                if InsCoverageLedgEntry.Find('-') then
                    repeat
                        TempInsurance."No." := InsCoverageLedgEntry."Insurance No.";
                        if TempInsurance.Insert() then begin
                            InsCoverageLedgEntry.SetRange("Insurance No.", InsCoverageLedgEntry."Insurance No.");
                            InsCoverageLedgEntry.CalcSums(Amount);
                            InsCoverageLedgEntry.SetRange("Insurance No.");
                            if InsCoverageLedgEntry.Amount <> 0 then begin
                                if Insurance.Get(InsCoverageLedgEntry."Insurance No.") then begin
                                    if Insurance.Blocked then
                                        CurrReport.Skip();
                                end else
                                    CurrReport.Skip();
                                InsuranceJnlLine."Line No." := 0;
                                FAJnlSetup.SetInsuranceJnlTrailCodes(InsuranceJnlLine);
                                InsuranceJnlLine.Validate("Insurance No.", InsCoverageLedgEntry."Insurance No.");
                                InsuranceJnlLine.Validate("FA No.", "No.");
                                InsuranceJnlLine.Validate(
                                  Amount, Round(InsCoverageLedgEntry.Amount * (IndexFigure / 100 - 1)));
                                InsuranceJnlLine."Document No." := DocumentNo;
                                InsuranceJnlLine."Posting No. Series" := NoSeries;
                                InsuranceJnlLine.Description := PostingDescription;
                                InsuranceJnlLine."Index Entry" := true;
                                NextLineNo := NextLineNo + 10000;
                                InsuranceJnlLine."Line No." := NextLineNo;
                                InsuranceJnlLine.Insert(true);
                            end;
                        end;
                    until InsCoverageLedgEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                InsCoverageLedgEntry.SetCurrentKey("FA No.", "Insurance No.");
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
                    field(IndexFigure; IndexFigure)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Index Figure';
                        DecimalPlaces = 0 : 8;
                        ToolTip = 'Specifies an index figure that is to calculate the index amounts entered in the journal. For example, if you want to index by 2%, enter 102 in this field; if you want to index by -3% percent, enter 97 in this field.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date to be used by the batch job. This date appears in the Posting Date field on the insurance journal lines.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a posting description to appear on the resulting journal lines.';
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
        if PostingDate = 0D then
            Error(Text000, InsuranceJnlLine.FieldCaption("Posting Date"));
        if PostingDate <> NormalDate(PostingDate) then
            Error(Text001);
        if IndexFigure = 100 then
            Error(Text002);
        if IndexFigure <= 0 then
            Error(Text003);
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        DeprBook.Get(FASetup."Insurance Depr. Book");
        InsuranceJnlLine.LockTable();
        FAJnlSetup.InsuranceJnlName(DeprBook, InsuranceJnlLine, NextLineNo);
        NoSeries := FAJnlSetup.GetInsuranceNoSeries(InsuranceJnlLine);
        if DocumentNo = '' then
            DocumentNo := FAJnlSetup.GetInsuranceJnlDocumentNo(InsuranceJnlLine, PostingDate);
        InsuranceJnlLine."Posting Date" := PostingDate;
        Window.Open(Text004);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        Insurance: Record Insurance;
        FAJnlSetup: Record "FA Journal Setup";
        TempInsurance: Record Insurance temporary;
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsuranceJnlLine: Record "Insurance Journal Line";
        Window: Dialog;
        PostingDate: Date;
        IndexFigure: Decimal;
        DocumentNo: Code[20];
        NoSeries: Code[20];
        PostingDescription: Text[100];
        NextLineNo: Integer;

        Text000: Label 'You must specify %1.';
        Text001: Label 'Posting Date must not be a closing date.';
        Text002: Label 'Index Figure must not be 100.';
        Text003: Label 'Index Figure must be positive.';
        Text004: Label 'Indexing insurance    #1##########';

    procedure InitializeRequest(DocumentNoFrom: Code[20]; PostingDescriptionFrom: Text[100]; PostingDateFrom: Date; IndexFigureFrom: Decimal)
    begin
        DocumentNo := DocumentNoFrom;
        PostingDescription := PostingDescriptionFrom;
        PostingDate := PostingDateFrom;
        IndexFigure := IndexFigureFrom;
    end;
}

