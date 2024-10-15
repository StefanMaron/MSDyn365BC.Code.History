report 11765 "Non Deductible VAT Correction"
{
    DefaultLayout = RDLC;
    RDLCLayout = './NonDeductibleVATCorrection.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Non-Deductible VAT Correction';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this report should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = SORTING("Primary Entry No.") WHERE("Primary Entry No." = FILTER(<> 0), Type = CONST(Purchase), "VAT % (Non Deductible)" = FILTER(<> 0));
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

            trigger OnAfterGetRecord()
            var
                NonDeductibleVATSetup: Record "Non Deductible VAT Setup";
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                if "Primary Entry No." <> "Entry No." then
                    exit;
                if not TempVATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                    TempVATPostingSetup := VATPostingSetup;
                    TempVATPostingSetup.Insert();
                    NonDeductibleVATSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                    NonDeductibleVATSetup.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if NonDeductibleVATSetup.FindSet then
                        repeat
                            TempNonDeductibleVATSetup := NonDeductibleVATSetup;
                            TempNonDeductibleVATSetup.Insert();
                        until NonDeductibleVATSetup.Next = 0;
                end;

                TempNonDeductibleVATSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                TempNonDeductibleVATSetup.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                TempNonDeductibleVATSetup.SetRange("From Date", 0D, "VAT Date");
                if not TempNonDeductibleVATSetup.FindLast then
                    Error(Text001Err, "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group", "VAT Date");
                VATEntryLast.SetCurrentKey("Primary Entry No.");
                VATEntryLast.SetRange("Primary Entry No.", "Entry No.");
                VATEntryLast.FindLast;
                if VATEntryLast."VAT % (Non Deductible)" = TempNonDeductibleVATSetup."Non Deductible VAT %" then
                    exit;
                TempVATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                TempVATPostingSetup.TestField("Non Deduct. VAT Corr. Account");
                TempVATEntryCorrBuf := "VAT Entry";
                TempVATEntryCorrBuf."VAT % (Non Deductible)" := TempNonDeductibleVATSetup."Non Deductible VAT %";
                TempVATEntryCorrBuf."VAT Base (Non Deductible)" :=
                  Round((Base - "VAT Amount (Non Deductible)") *
                    (TempVATEntryCorrBuf."VAT % (Non Deductible)" - VATEntryLast."VAT % (Non Deductible)") / 100);
                TempVATEntryCorrBuf."VAT Amount (Non Deductible)" :=
                  Round((Amount + "VAT Amount (Non Deductible)") *
                    (TempVATEntryCorrBuf."VAT % (Non Deductible)" - VATEntryLast."VAT % (Non Deductible)") / 100);
                TempVATEntryCorrBuf.Base := TempVATEntryCorrBuf."VAT Amount (Non Deductible)";
                TempVATEntryCorrBuf.Amount := -TempVATEntryCorrBuf."VAT Amount (Non Deductible)";
                TempVATEntryCorrBuf.Insert();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("VAT Date", FromVATDate, ToVATDate);
            end;
        }
        dataitem(Correction; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(greVATEntry__VAT_Date_; VATEntry."VAT Date")
            {
            }
            column(greVATEntry__Document_No__; VATEntry."Document No.")
            {
            }
            column(greVATEntry__VAT_Bus__Posting_Group_; VATEntry."VAT Bus. Posting Group")
            {
            }
            column(greVATEntry__VAT_Prod__Posting_Group_; VATEntry."VAT Prod. Posting Group")
            {
            }
            column(greVATEntry__VAT____Non_Deductible__; VATEntry."VAT % (Non Deductible)")
            {
            }
            column(greLastVATEntry__VAT____Non_Deductible__; VATEntryLast."VAT % (Non Deductible)")
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Base__Non_Deductible__; TempVATEntryCorrBuf."VAT Base (Non Deductible)")
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Amount__Non_Deductible__; TempVATEntryCorrBuf."VAT Amount (Non Deductible)")
            {
            }
            column(greVATEntry__Posting_Date_; VATEntry."Posting Date")
            {
            }
            column(greTVATEntryCorrBuffer__VAT____Non_Deductible__; TempVATEntryCorrBuf."VAT % (Non Deductible)")
            {
            }
            column(greVATEntry_Base___greVATEntry__VAT_Amount__Non_Deductible__; VATEntry.Base - VATEntry."VAT Amount (Non Deductible)")
            {
            }
            column(greVATEntry_Amount___greVATEntry__VAT_Amount__Non_Deductible__; VATEntry.Amount + VATEntry."VAT Amount (Non Deductible)")
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Base__Non_Deductible___Control4011219; TempVATEntryCorrBuf."VAT Base (Non Deductible)")
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Amount__Non_Deductible___Control4011220; TempVATEntryCorrBuf."VAT Amount (Non Deductible)")
            {
            }
            column(Trial_BalanceCaption; Trial_BalanceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(greVATEntry__VAT_Date_Caption; VATEntry__VAT_Date_CaptionLbl)
            {
            }
            column(greVATEntry__Document_No__Caption; VATEntry__Document_No__CaptionLbl)
            {
            }
            column(greVATEntry__VAT_Bus__Posting_Group_Caption; VATEntry__VAT_Bus__Posting_Group_CaptionLbl)
            {
            }
            column(greVATEntry__VAT_Prod__Posting_Group_Caption; VATEntry__VAT_Prod__Posting_Group_CaptionLbl)
            {
            }
            column(greVATEntry__VAT____Non_Deductible__Caption; VATEntry__VAT____Non_Deductible__CaptionLbl)
            {
            }
            column(greLastVATEntry__VAT____Non_Deductible__Caption; LastVATEntry__VAT____Non_Deductible__CaptionLbl)
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Base__Non_Deductible__Caption; TVATEntryCorrBuffer__VAT_Base__Non_Deductible__CaptionLbl)
            {
            }
            column(greTVATEntryCorrBuffer__VAT_Amount__Non_Deductible__Caption; TVATEntryCorrBuffer__VAT_Amount__Non_Deductible__CaptionLbl)
            {
            }
            column(greVATEntry__Posting_Date_Caption; VATEntry__Posting_Date_CaptionLbl)
            {
            }
            column(greTVATEntryCorrBuffer__VAT____Non_Deductible__Caption; TVATEntryCorrBuffer__VAT____Non_Deductible__CaptionLbl)
            {
            }
            column(greVATEntry_Base___greVATEntry__VAT_Amount__Non_Deductible__Caption; VATEntry_Base___greVATEntry__VAT_Amount__Non_Deductible__CaptionLbl)
            {
            }
            column(greVATEntry_Amount___greVATEntry__VAT_Amount__Non_Deductible__Caption; VATEntry_Amount___greVATEntry__VAT_Amount__Non_Deductible__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Correction_Number; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempVATEntryCorrBuf.FindSet
                else
                    if TempVATEntryCorrBuf.Next = 0 then
                        CurrReport.Break();

                VATEntry.Get(TempVATEntryCorrBuf."Entry No.");
                VATEntryLast.SetCurrentKey("Primary Entry No.");
                VATEntryLast.SetRange("Primary Entry No.", TempVATEntryCorrBuf."Entry No.");
                VATEntryLast.FindLast;

                if Post then
                    PostVAT;
            end;

            trigger OnPreDataItem()
            begin
                if TempVATEntryCorrBuf.IsEmpty then
                    Error(Text002Err);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Entries)
                {
                    Caption = 'Entries';
                    field(FromVATDate; FromVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting VAT Date';
                        ToolTip = 'Specifies the vat starting date';
                    }
                    field(ToVATDate; ToVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending VAT Date';
                        ToolTip = 'Specifies the last date in the period.';
                    }
                }
                group(Posting)
                {
                    Caption = 'Posting';
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies if the non deductible VAT correction has to be posted.';
                    }
                    field(DimVATCoeffUnpostAcc; DimVATCoeffUnpostAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimension';
                        OptionCaption = 'Dimension by Cost Account,Dimension by VAT Entry';
                        ToolTip = 'Specifies the filter for dimension 1.';
                    }
                    field(UseDocumentNo; UseDocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Document No';
                        ToolTip = 'Specifies document No. for new entries';
                    }
                    field(UsePostingDate; UsePostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Posting Date';
                        ToolTip = 'Specifies posting date for new entries';
                    }
                    field(UseVATDate; UseVATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use VAT Date';
                        ToolTip = 'Specifies vat date for new entries';
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
        if (FromVATDate = 0D) or (ToVATDate = 0D) then
            Error(Text003Err);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("VAT Coefficient");
    end;

    var
        TempVATEntryCorrBuf: Record "VAT Entry" temporary;
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        TempNonDeductibleVATSetup: Record "Non Deductible VAT Setup" temporary;
        VATEntry: Record "VAT Entry";
        VATEntryLast: Record "VAT Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FromVATDate: Date;
        ToVATDate: Date;
        UsePostingDate: Date;
        UseVATDate: Date;
        UseDocumentNo: Code[20];
        Post: Boolean;
        DimVATCoeffUnpostAcc: Option "Dimension by Cost Account","Dimension by VAT Entry";
        Text001Err: Label 'Non deductable VAT setup has not been found for %1 %2 <= %3.', Comment = '%1 = VAT Bus. Posting Group,%2 = VAT Prod. Posting Group,%3 = VAT Date';
        Text002Err: Label 'No entries to correct have been found.';
        Text003Err: Label 'You must fill Starting VAT Date and Ending VAT Date.';
        Trial_BalanceCaptionLbl: Label 'Non Deductable VAT Correction';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VATEntry__VAT_Date_CaptionLbl: Label 'VAT Date';
        VATEntry__Document_No__CaptionLbl: Label 'Document No.';
        VATEntry__VAT_Bus__Posting_Group_CaptionLbl: Label 'VAT Bus. Posting Group';
        VATEntry__VAT_Prod__Posting_Group_CaptionLbl: Label 'VAT Prod. Posting Group';
        VATEntry__VAT____Non_Deductible__CaptionLbl: Label 'VAT % (Non Deductible)';
        LastVATEntry__VAT____Non_Deductible__CaptionLbl: Label 'Last VAT % (Non Deductible)';
        TVATEntryCorrBuffer__VAT_Base__Non_Deductible__CaptionLbl: Label 'VAT Base Corr. (Non Deductible)';
        TVATEntryCorrBuffer__VAT_Amount__Non_Deductible__CaptionLbl: Label 'VAT Amount Corr. (Non Deductible)';
        VATEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        TVATEntryCorrBuffer__VAT____Non_Deductible__CaptionLbl: Label 'New VAT % (Non Deductible)';
        VATEntry_Base___greVATEntry__VAT_Amount__Non_Deductible__CaptionLbl: Label 'Vendor Base';
        VATEntry_Amount___greVATEntry__VAT_Amount__Non_Deductible__CaptionLbl: Label 'Vendor Amount';
        TotalCaptionLbl: Label 'Total';

    local procedure PostVAT()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TempVATPostingSetup.Get(TempVATEntryCorrBuf."VAT Bus. Posting Group", TempVATEntryCorrBuf."VAT Prod. Posting Group");
        GenJnlLine.Init();
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := TempVATPostingSetup."Non Deduct. VAT Corr. Account";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
        GenJnlLine."VAT Calculation Type" := TempVATEntryCorrBuf."VAT Calculation Type";
        GenJnlLine."Source Code" := SourceCodeSetup."VAT Coefficient";
        if UsePostingDate = 0D then
            GenJnlLine."Posting Date" := TempVATEntryCorrBuf."Posting Date"
        else
            GenJnlLine."Posting Date" := UsePostingDate;
        if UseDocumentNo = '' then
            GenJnlLine."Document No." := TempVATEntryCorrBuf."Document No."
        else
            GenJnlLine."Document No." := UseDocumentNo;
        GenJnlLine."Tax Area Code" := TempVATEntryCorrBuf."Tax Area Code";
        GenJnlLine."Tax Liable" := TempVATEntryCorrBuf."Tax Liable";
        GenJnlLine."Tax Group Code" := TempVATEntryCorrBuf."Tax Group Code";
        GenJnlLine."VAT Bus. Posting Group" := TempVATEntryCorrBuf."VAT Bus. Posting Group";
        GenJnlLine."VAT Prod. Posting Group" := TempVATEntryCorrBuf."VAT Prod. Posting Group";
        GenJnlLine."VAT Registration No." := TempVATEntryCorrBuf."VAT Registration No.";
        GenJnlLine."Registration No." := TempVATEntryCorrBuf."Registration No.";
        if UseVATDate = 0D then
            GenJnlLine."VAT Date" := TempVATEntryCorrBuf."VAT Date"
        else
            GenJnlLine."VAT Date" := UseVATDate;
        GenJnlLine."VAT % (Non Deductible)" := TempVATEntryCorrBuf."VAT % (Non Deductible)";
        GenJnlLine."VAT Base (Non Deductible)" := TempVATEntryCorrBuf."VAT Base (Non Deductible)";
        GenJnlLine."VAT Amount (Non Deductible)" := TempVATEntryCorrBuf."VAT Amount (Non Deductible)";
        GenJnlLine."VAT Base LCY (Non Deduct.)" := TempVATEntryCorrBuf."VAT Base (Non Deductible)";
        GenJnlLine."VAT Amount LCY (Non Deduct.)" := TempVATEntryCorrBuf."VAT Amount (Non Deductible)";
        GenJnlLine."Primary VAT Entry No." := TempVATEntryCorrBuf."Entry No.";
        case DimVATCoeffUnpostAcc of
            DimVATCoeffUnpostAcc::"Dimension by Cost Account":
                PostWithCostGLAccountDim(GenJnlLine);
            DimVATCoeffUnpostAcc::"Dimension by VAT Entry":
                PostWithVATEntryDim(GenJnlLine, VATEntry);
        end;
    end;

    local procedure PostWithCostGLAccountDim(var GenJnlLine: Record "Gen. Journal Line")
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := DATABASE::"G/L Account";
        TableID[2] := DATABASE::"G/L Account";
        No[1] := GenJnlLine."Account No.";
        No[2] := GenJnlLine."Bal. Account No.";
        GenJnlLine."Dimension Set ID" := DimMgt.GetDefaultDimID(TableID, No, GenJnlLine."Source Code",
            GenJnlLine."Shortcut Dimension 1 Code",
            GenJnlLine."Shortcut Dimension 2 Code",
            0, 0);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    local procedure PostWithVATEntryDim(var GenJnlLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry")
    begin
        GenJnlLine."Dimension Set ID" := VATEntry."Dimension Set ID";
        GenJnlLine."Shortcut Dimension 1 Code" := VATEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VATEntry."Global Dimension 2 Code";
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;
}

