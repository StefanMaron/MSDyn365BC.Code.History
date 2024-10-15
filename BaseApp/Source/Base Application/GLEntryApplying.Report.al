#if not CLEAN19
report 11767 "G/L Entry Applying"
{
    DefaultLayout = RDLC;
    RDLCLayout = './GLEntryApplying.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Entry Applying (Obsolete)';
    Permissions = TableData "G/L Entry" = rm;
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            RequestFilterFields = "No.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteAccFilter; AccFilter)
            {
            }
            column(gteGLEntryFilter; GLEntryFilter)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Entry_ApplyingCaption; G_L_Entry_ApplyingCaptionLbl)
            {
            }
            column(gdeAppliedAmountCaption; AppliedAmountCaptionLbl)
            {
            }
            column(OriginalEntry__Debit_Amount_Caption; OriginalEntry__Debit_Amount_CaptionLbl)
            {
            }
            column(OriginalEntry__Credit_Amount_Caption; OriginalEntry__Credit_Amount_CaptionLbl)
            {
            }
            column(OriginalEntry_DescriptionCaption; OriginalEntry_DescriptionCaptionLbl)
            {
            }
            column(OriginalEntry_AmountCaption; OriginalEntry_AmountCaptionLbl)
            {
            }
            column(OriginalEntry__Document_No__Caption; OriginalEntry__Document_No__CaptionLbl)
            {
            }
            column(OriginalEntry__Posting_Date_Caption; OriginalEntry__Posting_Date_CaptionLbl)
            {
            }
            column(OriginalEntry__Entry_No__Caption; OriginalEntry__Entry_No__CaptionLbl)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            dataitem(OriginalEntry; "G/L Entry")
            {
                CalcFields = "Applied Amount";
                DataItemLink = "G/L Account No." = FIELD("No.");
                DataItemTableView = SORTING("G/L Account No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date") WHERE(Closed = CONST(false));
                RequestFilterFields = "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "Document Type", "Document No.";
                column(OriginalEntry_Entry_No_; "Entry No.")
                {
                }
                column(OriginalEntry_G_L_Account_No_; "G/L Account No.")
                {
                }
                dataitem(AppliedEntry; "G/L Entry")
                {
                    CalcFields = "Applied Amount";
                    DataItemLink = "G/L Account No." = FIELD("G/L Account No.");
                    DataItemTableView = SORTING("G/L Account No.", "Posting Date") WHERE(Closed = CONST(false));

                    trigger OnAfterGetRecord()
                    begin
                        if (Applying = Applying::Free) and ByAmount then begin
                            TApplyEntry.Init();
                            TApplyEntry."Entry No." := "Entry No.";
                            TApplyEntry.Amount := Amount - "Applied Amount";
                            TApplyEntry.Insert();
                            TotalAmount := TotalAmount + TApplyEntry.Amount;
                        end else begin
                            "Applies-to ID" := OriginalEntry."Document No.";
                            "Amount to Apply" := (Amount - "Applied Amount");
                            TotalAmount := TotalAmount + "Amount to Apply";
                            if Abs(TotalAmount) > Abs(OriginalAmount) then begin
                                "Amount to Apply" := "Amount to Apply" - (TotalAmount + OriginalAmount);
                                TotalAmount := -OriginalAmount;
                            end;
                            Modify;
                            Apply := true;
                            if TotalAmount = -OriginalAmount then
                                CurrReport.Break();
                        end;
                    end;

                    trigger OnPostDataItem()
                    var
                        lreGLEntry: Record "G/L Entry";
                    begin
                        if (Applying = Applying::Free) and ByAmount then
                            if TotalAmount = -(OriginalEntry.Amount - OriginalEntry."Applied Amount") then begin
                                TApplyEntry.FindSet();
                                repeat
                                    lreGLEntry.Get(TApplyEntry."Entry No.");
                                    lreGLEntry."Applies-to ID" := OriginalEntry."Document No.";
                                    lreGLEntry."Amount to Apply" := TApplyEntry.Amount;
                                    lreGLEntry.Modify();
                                until TApplyEntry.Next() = 0;
                                Apply := true;
                            end;
                        AppliedAmount := 0;

                        TApplyEntry.Reset();
                        TApplyEntry.DeleteAll();
                        Clear(TApplyEntry);
                        TDetailedGLEntry.Reset();
                        TDetailedGLEntry.DeleteAll();
                        Clear(TDetailedGLEntry);

                        if Apply then begin
                            OriginalEntry."Applies-to ID" := OriginalEntry."Document No.";
                            OriginalEntry."Amount to Apply" := OriginalEntry.Amount - OriginalEntry."Applied Amount";
                            OriginalEntry.Modify();
                            Clear(ApplyGLEntry);

                            DetailedGLEntry.Reset();
                            if DetailedGLEntry.FindLast then
                                LastEntry := DetailedGLEntry."Entry No.";

                            ApplyGLEntry.NotUseRequestForm;
                            ApplyGLEntry.PostApplyGLEntry(OriginalEntry);
                            Clear(ApplyGLEntry);

                            DetailedGLEntry.Reset();
                            DetailedGLEntry.SetFilter("Entry No.", '>%1', LastEntry);
                            if DetailedGLEntry.FindSet then begin
                                repeat
                                    if (DetailedGLEntry."Applied G/L Entry No." = OriginalEntry."Entry No.") and
                                       (DetailedGLEntry."G/L Entry No." <> OriginalEntry."Entry No.")
                                    then begin
                                        TDetailedGLEntry := DetailedGLEntry;
                                        TDetailedGLEntry.Insert();
                                        AppliedAmount := AppliedAmount + DetailedGLEntry.Amount;
                                    end;
                                until DetailedGLEntry.Next() = 0;
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmount := 0;
                        Apply := false;

                        SetRange("Entry No.");
                        SetRange("G/L Account No.", OriginalEntry."G/L Account No.");
                        if OriginalEntry.Amount < 0 then
                            SetFilter(Amount, '>0')
                        else
                            SetFilter(Amount, '<0');
                        if ByBusUnit then
                            SetRange("Business Unit Code", OriginalEntry."Business Unit Code");
                        if ByPostingDate then
                            SetRange("Posting Date", OriginalEntry."Posting Date");
                        if ByDocNo then
                            SetRange("Document No.", OriginalEntry."Document No.");
                        if ByExtDocNo then
                            SetRange("External Document No.", OriginalEntry."External Document No.");
                        if (Applying = Applying::Unicate) and ByAmount then
                            SetRange(Amount, -(OriginalEntry.Amount - OriginalEntry."Applied Amount"));

                        if Applying = Applying::Unicate then
                            if Count <> 1 then
                                CurrReport.Break();
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(gdeAppliedAmount; -AppliedAmount)
                    {
                    }
                    column(OriginalEntry__Credit_Amount_; OriginalEntry."Credit Amount")
                    {
                    }
                    column(OriginalEntry__Debit_Amount_; OriginalEntry."Debit Amount")
                    {
                    }
                    column(OriginalEntry_Amount; OriginalEntry.Amount)
                    {
                    }
                    column(OriginalEntry_Description; OriginalEntry.Description)
                    {
                    }
                    column(OriginalEntry__Posting_Date_; OriginalEntry."Posting Date")
                    {
                    }
                    column(OriginalEntry__Document_No__; OriginalEntry."Document No.")
                    {
                    }
                    column(OriginalEntry__Entry_No__; OriginalEntry."Entry No.")
                    {
                    }
                    column(greTDetailedGLEntry_Amount; TDetailedGLEntry.Amount)
                    {
                    }
                    column(greGLEntry__Credit_Amount_; GLEntry."Credit Amount")
                    {
                    }
                    column(greGLEntry__Debit_Amount_; GLEntry."Debit Amount")
                    {
                    }
                    column(greTDetailedGLEntry_Amount_Control1100171027; TDetailedGLEntry.Amount)
                    {
                    }
                    column(greGLEntry_Description; GLEntry.Description)
                    {
                    }
                    column(greGLEntry__Posting_Date_; GLEntry."Posting Date")
                    {
                    }
                    column(greGLEntry__Document_No__; GLEntry."Document No.")
                    {
                    }
                    column(greTDetailedGLEntry__G_L_Entry_No__; TDetailedGLEntry."G/L Entry No.")
                    {
                    }
                    column(Integer_Number; Number)
                    {
                    }
                    column(greGLEntry__G_L_Account_No__; GLEntry."G/L Account No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TDetailedGLEntry.FindSet
                        else
                            TDetailedGLEntry.Next;

                        GLEntry.Get(TDetailedGLEntry."G/L Entry No.");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TDetailedGLEntry.Count);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    OriginalAmount := Amount - "Applied Amount";
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Close by")
                    {
                        Caption = 'Close by';
                        field(ByBusUnit; ByBusUnit)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies if the G/L entries have to be according to the business unit code applied.';
                        }
                        field(ColumnDim; ColumnDim)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies if the G/L entries have to be according to the dimensions applied.';
                            Visible = false;

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Close Income Statement", ColumnDim);
                            end;
                        }
                        field(ByDocNo; ByDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies if the G/L entries have to be according to the document number applied.';
                        }
                        field(ByExtDocNo; ByExtDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'External Document No.';
                            ToolTip = 'Specifies if the G/L entries have to be according to the external document number applied.';
                        }
                        field(ByPostingDate; ByPostingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posting Date';
                            ToolTip = 'Specifies if the G/L entries have to be according to the posting date applied.';
                        }
                        field(ByAmount; ByAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Amount';
                            ToolTip = 'Specifies if the G/L entries have to be according to the amount applied.';
                        }
                    }
                    field(Applying; Applying)
                    {
                        ApplicationArea = Basic, Suite;
                        OptionCaption = 'Free Applying,Unicate Applying';
                        ToolTip = 'Specifies if the G/L entries have to be free or unicate applied.';
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
        AccFilter := "G/L Account".GetFilters;
        GLEntryFilter := OriginalEntry.GetFilters;
    end;

    var
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Entry_ApplyingCaptionLbl: Label 'G/L Entry Applying';
        AppliedAmountCaptionLbl: Label 'Applied Amount';
        OriginalEntry__Debit_Amount_CaptionLbl: Label 'Debit Amount';
        OriginalEntry__Credit_Amount_CaptionLbl: Label 'Credit Amount';
        OriginalEntry_DescriptionCaptionLbl: Label 'Description';
        OriginalEntry_AmountCaptionLbl: Label 'Amount';
        OriginalEntry__Document_No__CaptionLbl: Label 'Document No.';
        OriginalEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        OriginalEntry__Entry_No__CaptionLbl: Label 'Entry No.';
        Applying: Option Free,Unicate;
        ByBusUnit: Boolean;
        ByDocNo: Boolean;
        ByExtDocNo: Boolean;
        ByAmount: Boolean;
        ByPostingDate: Boolean;
        Apply: Boolean;
        ColumnDim: Text[250];
        DimSelectionBuf: Record "Dimension Selection Buffer";
        AccFilter: Text;
        GLEntryFilter: Text;
        DetailedGLEntry: Record "Detailed G/L Entry";
        LastEntry: Integer;
        TotalAmount: Decimal;
        OriginalAmount: Decimal;
        TApplyEntry: Record "G/L Entry" temporary;
        ApplyGLEntry: Codeunit "G/L Entry -Post Application";
        AppliedAmount: Decimal;
        GLEntry: Record "G/L Entry";
        TDetailedGLEntry: Record "Detailed G/L Entry" temporary;
}
#endif
