report 1005 "Job Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JobJournalTest.rdlc';
    Caption = 'Job Journal - Test';

    dataset
    {
        dataitem("Job Journal Batch"; "Job Journal Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Journal Template Name", Name;
            column(Job_Journal_Batch_Name; Name)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                PrintOnlyIfDetail = true;
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Job_Journal_Batch___Journal_Template_Name_; "Job Journal Batch"."Journal Template Name")
                {
                }
                column(Job_Journal_Batch__Name; "Job Journal Batch".Name)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Job_Journal_Line__TABLECAPTION__________JobJnlLineFilter; "Job Journal Line".TableCaption + ': ' + JobJnlLineFilter)
                {
                }
                column(JobJnlLineFilter; JobJnlLineFilter)
                {
                }
                column(Job_Journal_Batch___Journal_Template_Name_Caption; Job_Journal_Batch___Journal_Template_Name_CaptionLbl)
                {
                }
                column(Job_Journal_Batch__NameCaption; Job_Journal_Batch__NameCaptionLbl)
                {
                }
                column(Job_Journal___TestCaption; Job_Journal___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Job_Journal_Line__Line_Amount_Caption; "Job Journal Line".FieldCaption("Line Amount"))
                {
                }
                column(Job_Journal_Line__Unit_Price_Caption; "Job Journal Line".FieldCaption("Unit Price"))
                {
                }
                column(Job_Journal_Line__Total_Cost__LCY__Caption; "Job Journal Line".FieldCaption("Total Cost (LCY)"))
                {
                }
                column(Job_Journal_Line__Unit_Cost__LCY__Caption; "Job Journal Line".FieldCaption("Unit Cost (LCY)"))
                {
                }
                column(Job_Journal_Line__Work_Type_Code_Caption; "Job Journal Line".FieldCaption("Work Type Code"))
                {
                }
                column(Job_Journal_Line__Unit_of_Measure_Code_Caption; "Job Journal Line".FieldCaption("Unit of Measure Code"))
                {
                }
                column(Job_Journal_Line_QuantityCaption; "Job Journal Line".FieldCaption(Quantity))
                {
                }
                column(Job_Journal_Line__No__Caption; "Job Journal Line".FieldCaption("No."))
                {
                }
                column(Job_Journal_Line__Document_No__Caption; "Job Journal Line".FieldCaption("Document No."))
                {
                }
                column(Job_Journal_Line_TypeCaption; "Job Journal Line".FieldCaption(Type))
                {
                }
                column(Job_Journal_Line__Job_No__Caption; "Job Journal Line".FieldCaption("Job No."))
                {
                }
                column(Job_Journal_Line__Posting_Date_Caption; Job_Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                dataitem("Job Journal Line"; "Job Journal Line")
                {
                    DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                    DataItemLinkReference = "Job Journal Batch";
                    DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(Job_Journal_Line__Line_Amount_; "Line Amount")
                    {
                    }
                    column(Job_Journal_Line__Unit_Price_; "Unit Price")
                    {
                    }
                    column(Job_Journal_Line__Total_Cost__LCY__; "Total Cost (LCY)")
                    {
                    }
                    column(Job_Journal_Line__Unit_Cost__LCY__; "Unit Cost (LCY)")
                    {
                    }
                    column(Job_Journal_Line__Work_Type_Code_; "Work Type Code")
                    {
                    }
                    column(Job_Journal_Line__Unit_of_Measure_Code_; "Unit of Measure Code")
                    {
                    }
                    column(Job_Journal_Line_Quantity; Quantity)
                    {
                    }
                    column(Job_Journal_Line__No__; "No.")
                    {
                    }
                    column(Job_Journal_Line_Type; Type)
                    {
                    }
                    column(Job_Journal_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Job_Journal_Line__Job_No__; "Job No.")
                    {
                    }
                    column(Job_Journal_Line__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Job_Journal_Line_Journal_Template_Name; "Journal Template Name")
                    {
                    }
                    column(Job_Journal_Line_Line_No_; "Line No.")
                    {
                    }
                    dataitem(DimensionLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(ShowDimensionLoop1; Number = 1)
                        {
                        }
                        column(ShowDimensionLoop2; Number > 1)
                        {
                        }
                        column(DimensionsCaption; DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.FindSet then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry.Next = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                            DimSetEntry.SetRange("Dimension Set ID", "Job Journal Line"."Dimension Set ID");
                        end;
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(ErrorText_Number_; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        UserSetupManagement: Codeunit "User Setup Management";
                        InvtPeriodEndDate: Date;
                        TempErrorText: Text[250];
                        IsHandled: Boolean;
                    begin
                        if EmptyLine then
                            exit;

                        MakeRecurringTexts("Job Journal Line");

                        CheckJob("Job Journal Line");

                        IsHandled := false;
                        OnAfterGetRecordOnBeforeJobTaskError("Job Journal Line", IsHandled);
                        if not IsHandled then
                            if "Job No." <> '' then
                                if "Job Task No." = '' then
                                    AddError(StrSubstNo(Text001, FieldCaption("Job Task No.")))
                                else begin
                                    if not JT.Get("Job No.", "Job Task No.") then
                                        AddError(StrSubstNo(Text015, JT.TableCaption, "Job Task No."))
                                end;

                        if Type <> Type::"G/L Account" then
                            if "Gen. Prod. Posting Group" = '' then
                                AddError(StrSubstNo(Text001, FieldCaption("Gen. Prod. Posting Group")))
                            else
                                if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                                    AddError(
                                      StrSubstNo(
                                        Text004, GenPostingSetup.TableCaption,
                                        "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));

                        if "Document No." = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Document No.")));

                        OnAfterGetrecordOnAfterCheckDocumentNo("Job Journal Line", ErrorCounter, ErrorText);

                        if "No." = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("No.")))
                        else
                            case Type of
                                Type::Resource:
                                    if not Res.Get("No.") then
                                        AddError(StrSubstNo(Text005, "No."))
                                    else begin
                                        if Res."Privacy Blocked" then
                                            AddError(StrSubstNo(Text006, Res.FieldCaption("Privacy Blocked"), false, "No."));
                                        if Res.Blocked then
                                            AddError(StrSubstNo(Text006, Res.FieldCaption(Blocked), false, "No."));
                                    end;
                                Type::Item:
                                    if not Item.Get("No.") then
                                        AddError(StrSubstNo(Text007, "No."))
                                    else
                                        if Item.Blocked then
                                            AddError(StrSubstNo(Text008, Item.FieldCaption(Blocked), false, "No."));
                                Type::"G/L Account":
                                    ;
                            end;

                        CheckRecurringLine("Job Journal Line");

                        if "Posting Date" = 0D then
                            AddError(StrSubstNo(Text001, FieldCaption("Posting Date")))
                        else begin
                            if "Posting Date" <> NormalDate("Posting Date") then
                                AddError(StrSubstNo(Text009, FieldCaption("Posting Date")));

                            if "Job Journal Batch"."No. Series" <> '' then
                                if NoSeries."Date Order" and ("Posting Date" < LastPostingDate) then
                                    AddError(Text010);
                            LastPostingDate := "Posting Date";

                            if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                                AddError(TempErrorText);

                            if Type = Type::Item then begin
                                InvtPeriodEndDate := "Posting Date";
                                if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                                    AddError(StrSubstNo(Text011, Format("Posting Date")))
                            end;
                        end;

                        if "Document Date" <> 0D then
                            if "Document Date" <> NormalDate("Document Date") then
                                AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                        if "Job Journal Batch"."No. Series" <> '' then begin
                            if LastDocNo <> '' then
                                if ("Document No." <> LastDocNo) and ("Document No." <> IncStr(LastDocNo)) then
                                    AddError(Text012);
                            LastDocNo := "Document No.";
                        end;

                        if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr);

                        TableID[1] := DATABASE::Job;
                        No[1] := "Job No.";
                        TableID[2] := DimMgt.TypeToTableID2(Type.AsInteger());
                        No[2] := "No.";
                        TableID[3] := DATABASE::"Resource Group";
                        No[3] := "Resource Group No.";
                        OnAfterAssignDimTableID("Job Journal Line", TableID, No);

                        if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr);
                    end;

                    trigger OnPreDataItem()
                    begin
                        JobJnlTemplate.Get("Job Journal Batch"."Journal Template Name");
                        if JobJnlTemplate.Recurring then begin
                            if GetFilter("Posting Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000, FieldCaption("Posting Date")));
                            SetRange("Posting Date", 0D, WorkDate);
                            if GetFilter("Expiration Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000, FieldCaption("Expiration Date")));
                            SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate);
                        end;

                        if "Job Journal Batch"."No. Series" <> '' then
                            NoSeries.Get("Job Journal Batch"."No. Series");
                        LastPostingDate := 0D;
                        LastDocNo := '';
                    end;
                }
            }
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies that the dimensions for each entry or posting group are included.';
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
        JobJnlLineFilter := "Job Journal Line".GetFilters;
    end;

    var
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 must be specified.';
        Text002: Label 'Job %1 does not exist.';
        Text003: Label '%1 must not be %2 for job %3.';
        Text004: Label '%1 %2 %3 does not exist.';
        Text005: Label 'Resource %1 does not exist.';
        Text006: Label '%1 must be %2 for resource %3.';
        Text007: Label 'Item %1 does not exist.';
        Text008: Label '%1 must be %2 for item %3.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label 'The lines are not listed according to posting date because they were not entered in that order.';
        Text011: Label '%1 is not within your allowed range of posting dates.';
        Text012: Label 'There is a gap in the number series.';
        Text013: Label '%1 cannot be specified.';
        Text014: Label '<Month Text>', Locked = true;
        AccountingPeriod: Record "Accounting Period";
        Job: Record Job;
        JT: Record "Job Task";
        Res: Record Resource;
        Item: Record Item;
        JobJnlTemplate: Record "Job Journal Template";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        DimSetEntry: Record "Dimension Set Entry";
        InvtPeriod: Record "Inventory Period";
        DimMgt: Codeunit DimensionManagement;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        JobJnlLineFilter: Text;
        LastPostingDate: Date;
        LastDocNo: Code[20];
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimText: Text[120];
        OldDimText: Text[120];
        ShowDim: Boolean;
        Continue: Boolean;
        Text015: Label '%1 %2 does not exist.';
        Job_Journal_Batch___Journal_Template_Name_CaptionLbl: Label 'Journal Template';
        Job_Journal_Batch__NameCaptionLbl: Label 'Journal Batch';
        Job_Journal___TestCaptionLbl: Label 'Job Journal - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Job_Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

    local procedure CheckRecurringLine(JobJnlLine2: Record "Job Journal Line")
    begin
        with JobJnlLine2 do
            if JobJnlTemplate.Recurring then begin
                if "Recurring Method" = 0 then
                    AddError(StrSubstNo(Text001, FieldCaption("Recurring Method")));
                if Format("Recurring Frequency") = '' then
                    AddError(StrSubstNo(Text001, FieldCaption("Recurring Frequency")));
                if "Recurring Method" = "Recurring Method"::Variable then
                    if Quantity = 0 then
                        AddError(StrSubstNo(Text001, FieldCaption(Quantity)));
            end else begin
                if "Recurring Method" <> 0 then
                    AddError(StrSubstNo(Text013, FieldCaption("Recurring Method")));
                if Format("Recurring Frequency") <> '' then
                    AddError(StrSubstNo(Text013, FieldCaption("Recurring Frequency")));
            end;
    end;

    local procedure CheckJob(var JobJournalLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJob(JobJournalLine, ErrorCounter, ErrorText, IsHandled);
        if IsHandled then
            exit;

        if JobJournalLine."Job No." = '' then
            AddError(StrSubstNo(Text001, JobJournalLine.FieldCaption("Job No.")))
        else
            if not Job.Get(JobJournalLine."Job No.") then
                AddError(StrSubstNo(Text002, JobJournalLine."Job No."))
            else begin
                if Job.Blocked <> Job.Blocked::" " then
                    AddError(StrSubstNo(Text003, Job.FieldCaption(Blocked), Job.Blocked, JobJournalLine."Job No."));
            end;
    end;

    local procedure MakeRecurringTexts(var JobJnlLine2: Record "Job Journal Line")
    begin
        with JobJnlLine2 do
            if ("Posting Date" <> 0D) and ("No." <> '') and ("Recurring Method" <> 0) then begin
                Day := Date2DMY("Posting Date", 1);
                Week := Date2DWY("Posting Date", 2);
                Month := Date2DMY("Posting Date", 2);
                MonthText := Format("Posting Date", 0, Text014);
                AccountingPeriod.SetRange("Starting Date", 0D, "Posting Date");
                if not AccountingPeriod.FindLast then
                    AccountingPeriod.Name := '';
                "Document No." :=
                  DelChr(PadStr(StrSubstNo("Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen("Document No.")), '>');
                Description :=
                  DelChr(PadStr(StrSubstNo(Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                      MaxStrLen(Description)), '>');
            end;
    end;

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignDimTableID(JobJournalLine: Record "Job Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCheckDocumentNo(JobJournalLine: Record "Job Journal Line"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeJobTaskError(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJob(var JobJournalLine: Record "Job Journal Line"; var ErrorCounter: Integer; var ErrorText: Array[50] of Text[250]; var IsHandled: Boolean)
    begin
    end;
}

