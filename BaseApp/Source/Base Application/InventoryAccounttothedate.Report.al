#if not CLEAN19
report 11760 "Inventory Account to the date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './InventoryAccounttothedate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Account to Date (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = WHERE("Account Type" = CONST(Posting));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
            column(PeriodGLDtFilter; StrSubstNo(Text000, ToDate))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(ShowApplyEntries; ShowApplyEntries)
            {
            }
            column(GLAccTableCaption; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(No_GLAcc; "No.")
            {
            }
            column(No_Name; Name)
            {
            }
            column(Dim1Caption; FieldCaption("Global Dimension 1 Code"))
            {
            }
            column(Dim2Caption; FieldCaption("Global Dimension 2 Code"))
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(Name_GLAcc; "G/L Account".Name)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = FIELD("No."), "Posting Date" = FIELD("Date Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = SORTING("G/L Account No.", "Posting Date");
                    column(Amount_GLE; Amount)
                    {
                    }
                    column(RemainingAmount_GLE; RemAmount)
                    {
                    }
                    column(AppliedAmount_GLE; "Applied Amount")
                    {
                    }
                    column(PostingDate_GLE; Format("Posting Date"))
                    {
                    }
                    column(DocumentType_GLE; Format("Document Type"))
                    {
                    }
                    column(DocumentNo_GLE; "Document No.")
                    {
                    }
                    column(Description_GLE; Description)
                    {
                    }
                    column(Glob1Dim_GLE; "Global Dimension 1 Code")
                    {
                        AutoFormatType = 1;
                    }
                    column(Glob2Dim_GLE; "Global Dimension 2 Code")
                    {
                    }
                    dataitem("Detailed G/L Entry"; "Detailed G/L Entry")
                    {
                        DataItemLink = "G/L Entry No." = FIELD("Entry No.");
                        DataItemTableView = SORTING("G/L Entry No.", "Posting Date") WHERE(Unapplied = CONST(false));
                        dataitem(AppliedGLEntry; "G/L Entry")
                        {
                            DataItemLink = "Entry No." = FIELD("Applied G/L Entry No.");
                            DataItemTableView = SORTING("Entry No.");
                            column(EntryNo_AGLE; "G/L Entry"."Entry No.")
                            {
                            }
                            column(AppliedAmount_AGLE; "Detailed G/L Entry".Amount)
                            {
                            }
                            column(PostingDate_AGLE; Format("Posting Date"))
                            {
                            }
                            column(DocumentType_AGLE; Format("Document Type"))
                            {
                            }
                            column(DocumentNo_AGLE; "Document No.")
                            {
                            }
                            column(Description_AGLE; Description)
                            {
                            }
                            column(Glob1Dim_AGLE; "Global Dimension 1 Code")
                            {
                                AutoFormatType = 1;
                            }
                            column(Glob2Dim_AGLE; "Global Dimension 2 Code")
                            {
                            }
                            column(RepCount_AGLE; RepCount)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                RepCount += 1;
                            end;
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowApplyEntries then
                                CurrReport.Break();

                            SetFilter("Posting Date", '..%1', ToDate);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Applied Amount");
                        if ((Amount - "Applied Amount") = 0) and (not ShowApplyEntries) then
                            CurrReport.Skip();

                        RemAmount := Amount - "Applied Amount";
                        if (RemAmount = 0) and (not ShowZeroRemainAmt) then
                            CurrReport.Skip();

                        Clear(RepCount);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Date Filter", '..%1', ToDate);
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(Name1_GLEntry; "G/L Account".Name)
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                if PrintOnlyOnePerPage then begin
                    GLEntryPage.Reset();
                    GLEntryPage.SetRange("G/L Account No.", "No.");
                    if CurrReport.PrintOnlyIfDetail and GLEntryPage.FindFirst() then
                        PageGroupNo := PageGroupNo + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                if GetFilter("Date Filter") <> '' then
                    ToDate := GetRangeMax("Date Filter");
                if ToDate = 0D then
                    ToDate := Today;
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
                    field(NewPageperGLAcc; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per G/L Acc.';
                        ToolTip = 'Specifies if you want each G/L account to be printed on a separate page.';
                    }
                    field(NewShowApplyEntries; ShowApplyEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Apllied Entries';
                        MultiLine = true;
                        ToolTip = 'Specifies when the apllied entries is to be show';
                    }
                    field(NewShowZeroRemainAmt; ShowZeroRemainAmt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Entries with zero Remainig Amt.';
                        ToolTip = 'Specifies when the entries with zero remainig amt. is to be show';
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
        ReportCaption = 'Inventory Account to the date (Obsolete)';
        PageCaption = 'Page';
        PostingDateCaption = 'Posting Date';
        DocTypeCaption = 'Document Type';
        DocNoCaption = 'Document No.';
        DescCaption = 'Description';
        EntryNoCaption = 'Entry No.';
        AmountCaption = 'Amount';
        RemAmountCaption = 'Remaining Amount';
        GLAccNoCaption = 'Account No.';
        GLAccDescCaption = 'Account Name';
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters;
    end;

    var
        GLFilter: Text;
        ToDate: Date;
        PrintOnlyOnePerPage: Boolean;
        ShowApplyEntries: Boolean;
        PageGroupNo: Integer;
        RemAmount: Decimal;
        GLEntryPage: Record "G/L Entry";
        RepCount: Integer;
        ShowZeroRemainAmt: Boolean;
        Text000: Label 'To Date: %1';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewShowApplyEntries: Boolean)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        ShowApplyEntries := NewShowApplyEntries;
    end;
}
#endif
