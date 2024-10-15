#if not CLEAN18
report 31043 "Fixed Asset - Analys. Dep.Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssetAnalysDepBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Fixed Asset - Depreciation Book Analysis (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Fixed Asset Localization for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(gcoGroup; Group)
            {
            }
            column(gteMainHeadLineText; MainHeadLineText)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteDeprBookText; DeprBookText)
            {
            }
            column(gteDeprBookText2; DeprBookText2)
            {
            }
            column(Fixed_Asset__TABLECAPTION_________gteFAFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(gteHeadLineText_1_; HeadLineText[1])
            {
            }
            column(gteGroupCodeName; GroupCodeName)
            {
            }
            column(gteFANo; FANo)
            {
            }
            column(gteFADescription; FADescription)
            {
            }
            column(gteHeadLineText_2_; HeadLineText[2])
            {
            }
            column(gteHeadLineText_3_; HeadLineText[3])
            {
            }
            column(gteHeadLineText_4_; HeadLineText[4])
            {
            }
            column(gteHeadLineText_5_; HeadLineText[5])
            {
            }
            column(gteHeadLineText_6_; HeadLineText[6])
            {
            }
            column(gteHeadLineText_7_; HeadLineText[7])
            {
            }
            column(gteHeadLineText_8_; HeadLineText[8])
            {
            }
            column(gteHeadLineText_9_; HeadLineText[9])
            {
            }
            column(gteHeadLineText_10_; HeadLineText[10])
            {
            }
            column(gteGroupHeadLine; GroupHeadLine)
            {
            }
            column(Fixed_Asset__No__; "No.")
            {
            }
            column(Fixed_Asset_Description; Description)
            {
            }
            column(gdeAmounts_1_; Amounts[1])
            {
                AutoFormatType = 1;
            }
            column(gdeAmounts_2_; Amounts[2])
            {
                AutoFormatType = 1;
            }
            column(gdeAmounts_3_; Amounts[3])
            {
                AutoFormatType = 1;
            }
            column(gdaDate_1_; Date[1])
            {
            }
            column(gdaDate_2_; Date[2])
            {
            }
            column(SetSalesMark; SetSalesMark)
            {
            }
            column(gdaDate_3_; Date[3])
            {
            }
            column(gdeAmounts_4_; Amounts[4])
            {
                AutoFormatType = 1;
            }
            column(Fixed_Asset__Global_Dimension_1_Code_; "Global Dimension 1 Code")
            {
            }
            column(Fixed_Asset__Global_Dimension_2_Code_; "Global Dimension 2 Code")
            {
            }
            column(gteInfo1; Info1)
            {
            }
            column(gdaDate2_1_; Date2[1])
            {
            }
            column(gdaDate2_2_; Date2[2])
            {
            }
            column(gdaDate2_3_; Date2[3])
            {
            }
            column(gdeAmounts2_1_; Amounts2[1])
            {
                AutoFormatType = 1;
            }
            column(gdeAmounts2_2_; Amounts2[2])
            {
                AutoFormatType = 1;
            }
            column(gdeAmounts2_3_; Amounts2[3])
            {
                AutoFormatType = 1;
            }
            column(gdeAmounts2_4_; Amounts2[4])
            {
                AutoFormatType = 1;
            }
            column(gteInfo2; Info2)
            {
            }
            column(SetSalesMark2; SetSalesMark2)
            {
            }
            column(gcoDeprBookCode; DeprBookCode)
            {
            }
            column(gcoDeprBookCode2; DeprBookCode2)
            {
            }
            column(Fixed_Asset__FA_Posting_Group_; "FA Posting Group")
            {
            }
            column(gtcText002__________gteGroupHeadLine; Text002Txt + ': ' + GroupHeadLine)
            {
            }
            column(gcoDeprBookCode_Control70; DeprBookCode)
            {
            }
            column(gcoDeprBookCode2_Control71; DeprBookCode2)
            {
            }
            column(gcoDeprBookCode_Control72; DeprBookCode)
            {
            }
            column(gcoDeprBookCode2_Control73; DeprBookCode2)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Depr__BookCaption; Depr__BookCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Fixed_Asset_FA_Subclass_Code; "FA Subclass Code")
            {
            }
            column(Fixed_Asset_FA_Class_Code; "FA Class Code")
            {
            }
            column(Fixed_Asset_Component_of_Main_Asset; "Component of Main Asset")
            {
            }
            column(Fixed_Asset_FA_Location_Code; "FA Location Code")
            {
            }
            column(Fixed_Asset_Tax_Depreciation_Group_Code; "Tax Depreciation Group Code")
            {
            }
            column(gboPrintDetails; PrintDetails)
            {
            }
            column(gopGroupTotals; GroupTotals)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if (not FADeprBook.Get("No.", DeprBookCode)) and (not FADeprBook2.Get("No.", DeprBookCode2)) then
                    CurrReport.Skip();
                if SkipRecord then
                    CurrReport.Skip();

                if GroupTotals = GroupTotals::"FA Posting Group" then
                    if "FA Posting Group" <> FADeprBook."FA Posting Group" then
                        Error(Text009Err, FieldCaption("FA Posting Group"), "No.");

                if GroupTotals = GroupTotals::"Tax Depreciation Group Code" then
                    if "Tax Depreciation Group Code" <> FADeprBook."Depreciation Group Code" then
                        Error(Text009Err, FieldCaption("Tax Depreciation Group Code"), "No.");

                case GroupTotals of
                    GroupTotals::"FA Class":
                        Group := "FA Class Code";
                    GroupTotals::"FA Subclass":
                        Group := "FA Subclass Code";
                    GroupTotals::"Main Asset":
                        Group := "Component of Main Asset";
                    GroupTotals::"Global Dimension 1":
                        Group := "Global Dimension 1 Code";
                    GroupTotals::"FA Location":
                        Group := "FA Location Code";
                    GroupTotals::"Global Dimension 2":
                        Group := "Global Dimension 2 Code";
                    GroupTotals::"FA Posting Group":
                        Group := "FA Posting Group";
                    GroupTotals::"Tax Depreciation Group Code":
                        Group := "Tax Depreciation Group Code";
                end;
                MakeGroupHeadLine;

                Date[1] := FAGenReport.GetLastDate("No.", DateTypeNo1, EndingDate, DeprBookCode, false);
                Date[2] := FAGenReport.GetLastDate("No.", DateTypeNo2, EndingDate, DeprBookCode, false);
                Date[3] := FAGenReport.GetLastDate("No.", DateTypeNo3, EndingDate, DeprBookCode, false);
                Date2[1] := FAGenReport.GetLastDate("No.", DateTypeNo1, EndingDate, DeprBookCode2, false);
                Date2[2] := FAGenReport.GetLastDate("No.", DateTypeNo2, EndingDate, DeprBookCode2, false);
                Date2[3] := FAGenReport.GetLastDate("No.", DateTypeNo3, EndingDate, DeprBookCode2, false);

                case FADeprBook."Depreciation Method" of
                    FADeprBook."Depreciation Method"::"Straight-Line":
                        if FADeprBook."Straight-Line %" <> 0 then
                            Info1 := CopyStr(Format(FADeprBook."Depreciation Method"), 1, 3) + '. ' +
                              Format(FADeprBook."Straight-Line %") + '%'
                        else
                            if FADeprBook."No. of Depreciation Years" <> 0 then
                                Info1 := CopyStr(Format(FADeprBook."Depreciation Method"), 1, 3) + '. ' +
                                  Format(Round(100 / FADeprBook."No. of Depreciation Years")) + '%'
                            else
                                Info1 := CopyStr(Format(FADeprBook."Depreciation Method"), 1, 3) + '.';
                    FADeprBook."Depreciation Method"::Manual:
                        Info1 := Format(FADeprBook."Depreciation Method");
                end;
                case FADeprBook2."Depreciation Method" of
                    FADeprBook2."Depreciation Method"::"Straight-Line":
                        if FADeprBook2."Straight-Line %" <> 0 then
                            Info2 := CopyStr(Format(FADeprBook2."Depreciation Method"), 1, 3) + '. ' +
                              Format(FADeprBook2."Straight-Line %") + '%'
                        else
                            if FADeprBook2."No. of Depreciation Years" <> 0 then
                                Info2 := CopyStr(Format(FADeprBook2."Depreciation Method"), 1, 3) + '. ' +
                                  Format(Round(100 / FADeprBook2."No. of Depreciation Years")) + '%'
                            else
                                Info2 := CopyStr(Format(FADeprBook2."Depreciation Method"), 1, 3) + '.';
                    FADeprBook."Depreciation Method"::Manual:
                        Info2 := Format(FADeprBook2."Depreciation Method");
                end;

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate("No.", GetStartDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);
                BeforeAmount2 := 0;
                EndingAmount2 := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate("No.", GetStartDate(StartingDate), EndingDate, DeprBookCode2, BeforeAmount2, EndingAmount2);

                if SetAmountToZero(PostingTypeNo1, Period1) then
                    Amounts[1] := 0
                else
                    Amounts[1] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo1, Period1, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero(PostingTypeNo2, Period2) then
                    Amounts[2] := 0
                else
                    Amounts[2] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo2, Period2, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero(PostingTypeNo3, Period3) then
                    Amounts[3] := 0
                else
                    Amounts[3] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo3, Period3, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero(PostingTypeNo4, Period4) then
                    Amounts[4] := 0
                else
                    Amounts[4] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo4, Period4, StartingDate, EndingDate,
                        DeprBookCode, BeforeAmount, EndingAmount, false, false);

                if SetAmountToZero2(PostingTypeNo1, Period1) then
                    Amounts2[1] := 0
                else
                    Amounts2[1] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo1, Period1, StartingDate, EndingDate,
                        DeprBookCode2, BeforeAmount2, EndingAmount2, false, false);

                if SetAmountToZero2(PostingTypeNo2, Period2) then
                    Amounts2[2] := 0
                else
                    Amounts2[2] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo2, Period2, StartingDate, EndingDate,
                        DeprBookCode2, BeforeAmount2, EndingAmount2, false, false);

                if SetAmountToZero2(PostingTypeNo3, Period3) then
                    Amounts2[3] := 0
                else
                    Amounts2[3] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo3, Period3, StartingDate, EndingDate,
                        DeprBookCode2, BeforeAmount2, EndingAmount2, false, false);

                if SetAmountToZero2(PostingTypeNo4, Period4) then
                    Amounts2[4] := 0
                else
                    Amounts2[4] := FAGenReport.CalcFAPostedAmount("No.", PostingTypeNo4, Period4, StartingDate, EndingDate,
                        DeprBookCode2, BeforeAmount2, EndingAmount2, false, false);
            end;

            trigger OnPreDataItem()
            begin
                case GroupTotals of
                    GroupTotals::"FA Class":
                        SetCurrentKey("FA Class Code");
                    GroupTotals::"FA Subclass":
                        SetCurrentKey("FA Subclass Code");
                    GroupTotals::"Main Asset":
                        SetCurrentKey("Component of Main Asset");
                    GroupTotals::"Global Dimension 1":
                        SetCurrentKey("Global Dimension 1 Code");
                    GroupTotals::"FA Location":
                        SetCurrentKey("FA Location Code");
                    GroupTotals::"Global Dimension 2":
                        SetCurrentKey("Global Dimension 2 Code");
                    GroupTotals::"FA Posting Group":
                        SetCurrentKey("FA Posting Group");
                    GroupTotals::"Tax Depreciation Group Code":
                        SetCurrentKey("Tax Depreciation Group Code");
                end;
                FAPostingType.CreateTypes;
                FADateType.CreateTypes;
                CheckDateType(DateType1, DateTypeNo1);
                CheckDateType(DateType2, DateTypeNo2);
                CheckDateType(DateType3, DateTypeNo3);
                CheckPostingType(PostingType1, PostingTypeNo1);
                CheckPostingType(PostingType2, PostingTypeNo2);
                CheckPostingType(PostingType3, PostingTypeNo3);
                CheckPostingType(PostingType4, PostingTypeNo4);
                MakeGroupTotalText;
                FAGenReport.ValidateDates(StartingDate, EndingDate);
                MakeDateHeadLine;
                MakeAmountHeadLine(3, PostingType1, PostingTypeNo1, Period1);
                MakeAmountHeadLine(4, PostingType2, PostingTypeNo2, Period2);
                MakeAmountHeadLine(5, PostingType3, PostingTypeNo3, Period3);
                MakeAmountHeadLine(6, PostingType4, PostingTypeNo4, Period4);

                GroupTotals := GroupTotals
            end;
        }
    }

    requestpage
    {
        Permissions = TableData "FA Setup" = r;
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Books';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book for the printing of entries.';
                    }
                    field(DeprBookCode2; DeprBookCode2)
                    {
                        ApplicationArea = Basic, Suite;
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the deprecation book code.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period.';
                    }
                    field(DateType1; DateType1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Field 1';
                        TableRelation = "FA Date Type"."FA Date Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the data field which can be printed.';
                    }
                    field(DateType2; DateType2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Field 2';
                        TableRelation = "FA Date Type"."FA Date Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the data field which can be printed.';
                    }
                    field(DateType3; DateType3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date Field 3';
                        TableRelation = "FA Date Type"."FA Date Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the data field which can be printed.';
                    }
                    field(PostingType1; PostingType1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Field 1';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the FA posting type which can be printed.';
                    }
                    field(Period1; Period1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period 1';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies the method for amounts calculation';
                    }
                    field(PostingType2; PostingType2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Field 2';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the FA posting type which can be printed.';
                    }
                    field(Period2; Period2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period 2';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies the method for amounts calculation';
                    }
                    field(PostingType3; PostingType3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Field 3';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the FA posting type which can be printed.';
                    }
                    field(Period3; Period3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period 3';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies the method for amounts calculation';
                    }
                    field(PostingType4; PostingType4)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Field 4';
                        TableRelation = "FA Posting Type"."FA Posting Type Name" WHERE("FA Entry" = CONST(true));
                        ToolTip = 'Specifies the FA posting type which can be printed.';
                    }
                    field(Period4; Period4)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period 4';
                        OptionCaption = 'before Starting Date,Net Change,at Ending Date';
                        ToolTip = 'Specifies the method for amounts calculation';
                    }
                    field(GroupTotals; GroupTotals)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group Totals';
                        OptionCaption = ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group,Tax Depreciation Group Code';
                        ToolTip = 'Specifies according to what the entries can be sumed.';
                    }
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print per Fixed Asset';
                        ToolTip = 'Specifies if the sum will be printed in common or only the Specifiesed FA cards.';
                    }
                    field(SalesReport; SalesReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Sold Assets';
                        ToolTip = 'Specifies only sold assets.';
                    }
                    field(BudgetReport; BudgetReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Budget Report';
                        ToolTip = 'Specifies if the budget report will be used';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GetFASetup;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DeprBook.Get(DeprBookCode);
        DeprBookText := StrSubstNo('%1%2 %3 %4', DeprBook.TableCaption, ' 1:', DeprBookCode, DeprBook.Description);
        DeprBook2.Get(DeprBookCode2);
        DeprBookText2 := StrSubstNo('%1%2 %3 %4', DeprBook.TableCaption, ' 2:', DeprBookCode2, DeprBook2.Description);

        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        if GroupTotals = GroupTotals::"Tax Depreciation Group Code" then
            FAGenReport.SetFATaxDeprGroup("Fixed Asset", DeprBook.Code);

        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters;

        MainHeadLineText := Text000;
        if BudgetReport then
            MainHeadLineText := StrSubstNo('%1 %2', MainHeadLineText, Text001Txt);

        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
    end;

    var
        Text000: Label 'Fixed Asset - Analys. Dep.Book';
        Text001Txt: Label '(Budget Report)';
        Text002Txt: Label 'Group Total';
        Text003Txt: Label 'Sold';
        Text004Txt: Label 'Group Totals: %1';
        Text005Err: Label '%1 or %2 must be specified only together with the option %3.', Comment = '%1=fieldcaption.proceedsondisposal;%2=fieldcaption.gain/loss;%3=period';
        Text006Err: Label 'The Starting Date must be specified when you use the option %1.';
        Text007Err: Label 'The date type %1 is not a valid option.';
        Text008Err: Label 'The posting type %1 is not a valid option.';
        Text009Err: Label '%1 has been modified in fixed asset %2.', Comment = '%1=fieldcaption.fapostinggroup;%2=number';
        Text010Txt: Label 'before Starting Date,Net Change,at Ending Date';
        Text012Txt: Label 'Default Tax. Depr. by Book';
        Text013Txt: Label 'FA Posting Group';
        CurrReport_PAGENOCaptionLbl: Label 'Page No.';
        Depr__BookCaptionLbl: Label 'Depr. Book';
        TotalCaptionLbl: Label 'Total';
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        DeprBook2: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        FAPostingType: Record "FA Posting Type";
        FADateType: Record "FA Date Type";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        DeprBookCode: Code[10];
        DeprBookCode2: Code[10];
        FAFilter: Text;
        MainHeadLineText: Text[100];
        DeprBookText: Text[100];
        DeprBookText2: Text[100];
        GroupCodeName: Text[50];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        HeadLineText: array[10] of Text[50];
        PostingType1: Text[30];
        PostingType2: Text[30];
        PostingType3: Text[30];
        PostingType4: Text[30];
        DateType1: Text[30];
        DateType2: Text[30];
        DateType3: Text[30];
        Info1: Text[30];
        Info2: Text[30];
        Date: array[3] of Date;
        Date2: array[3] of Date;
        StartingDate: Date;
        EndingDate: Date;
        AcquisitionDate: Date;
        AcquisitionDate2: Date;
        DisposalDate: Date;
        DisposalDate2: Date;
        BeforeAmount: Decimal;
        BeforeAmount2: Decimal;
        EndingAmount: Decimal;
        EndingAmount2: Decimal;
        Amounts: array[4] of Decimal;
        Amounts2: array[4] of Decimal;
        PostingTypeNo1: Integer;
        PostingTypeNo2: Integer;
        PostingTypeNo3: Integer;
        PostingTypeNo4: Integer;
        DateTypeNo1: Integer;
        DateTypeNo2: Integer;
        DateTypeNo3: Integer;
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        Period3: Option "Before Starting Date","Net Change","at Ending Date";
        Period4: Option "Before Starting Date","Net Change","at Ending Date";
        PrintDetails: Boolean;
        BudgetReport: Boolean;
        SalesReport: Boolean;
        TypeExist: Boolean;
        Group: Code[50];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group","Tax Depreciation Group Code";

    local procedure SkipRecord(): Boolean
    begin
        AcquisitionDate := FADeprBook."Acquisition Date";
        DisposalDate := FADeprBook."Disposal Date";
        AcquisitionDate2 := FADeprBook2."Acquisition Date";
        DisposalDate2 := FADeprBook2."Disposal Date";

        if "Fixed Asset".Inactive then
            exit(true);
        if (AcquisitionDate = 0D) and (AcquisitionDate2 = 0D) then
            exit(true);
        if (AcquisitionDate > EndingDate) and (AcquisitionDate2 > EndingDate) and (EndingDate > 0D) then
            exit(true);
        if SalesReport and (DisposalDate = 0D) and (DisposalDate2 = 0D) then
            exit(true);
        if SalesReport and (EndingDate > 0D) and
           ((DisposalDate > EndingDate) or (DisposalDate < StartingDate)) and
           ((DisposalDate2 > EndingDate) or (DisposalDate2 < StartingDate))
        then
            exit(true);

        if not SalesReport and (DisposalDate > 0D) and (DisposalDate < StartingDate) and
           (DisposalDate2 > 0D) and (DisposalDate2 < StartingDate)
        then
            exit(true);
        exit(false);
    end;

    local procedure SetSalesMark(): Text[30]
    begin
        if DisposalDate > 0D then
            if (EndingDate = 0D) or (DisposalDate <= EndingDate) then
                exit(Text003Txt);
        exit('');
    end;

    local procedure SetSalesMark2(): Text[30]
    begin
        if DisposalDate2 > 0D then
            if (EndingDate = 0D) or (DisposalDate2 <= EndingDate) then
                exit(Text003Txt);
        exit('');
    end;

    local procedure MakeGroupTotalText()
    begin
        case GroupTotals of
            GroupTotals::"FA Class":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Class Code");
            GroupTotals::"FA Subclass":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Subclass Code");
            GroupTotals::"Main Asset":
                GroupCodeName := "Fixed Asset".FieldCaption("Main Asset/Component");
            GroupTotals::"Global Dimension 1":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 1 Code");
            GroupTotals::"FA Location":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Location Code");
            GroupTotals::"Global Dimension 2":
                GroupCodeName := "Fixed Asset".FieldCaption("Global Dimension 2 Code");
            GroupTotals::"FA Posting Group":
                GroupCodeName := "Fixed Asset".FieldCaption("FA Posting Group");
            GroupTotals::"Tax Depreciation Group Code":
                GroupCodeName := "Fixed Asset".FieldCaption("Tax Depreciation Group Code");
        end;
        if GroupCodeName <> '' then
            GroupCodeName := StrSubstNo(Text004Txt, GroupCodeName);
    end;

    local procedure MakeDateHeadLine()
    begin
        if not PrintDetails then
            exit;
        HeadLineText[1] := DateType1;
        HeadLineText[2] := DateType2;
        HeadLineText[7] := DateType3;
        HeadLineText[8] := Text012Txt;
        HeadLineText[9] := Text013Txt;
        HeadLineText[10] := "Fixed Asset".FieldCaption("Global Dimension 1 Code") + ' ' +
          "Fixed Asset".FieldCaption("Global Dimension 2 Code");
    end;

    local procedure MakeAmountHeadLine(i: Integer; ltePostingType: Text[50]; linPostingTypeNo: Integer; lopPeriod: Option "Before Starting Date","Net Change","at Ending Date")
    begin
        if linPostingTypeNo = 0 then
            exit;
        case linPostingTypeNo of
            FADeprBook.FieldNo("Proceeds on Disposal"),
          FADeprBook.FieldNo("Gain/Loss"):
                if lopPeriod <> lopPeriod::"at Ending Date" then begin
                    lopPeriod := lopPeriod::"at Ending Date";
                    Error(
                      Text005Err,
                      FADeprBook.FieldCaption("Proceeds on Disposal"),
                      FADeprBook.FieldCaption("Gain/Loss"),
                      SelectStr(lopPeriod + 1, Text010Txt));
                end;
        end;
        if lopPeriod = lopPeriod::"Before Starting Date" then
            if StartingDate = 0D then
                Error(
                  Text006Err, SelectStr(lopPeriod + 1, Text010Txt));

        HeadLineText[i] := StrSubstNo('%1 %2', ltePostingType, SelectStr(lopPeriod + 1, Text010Txt));
    end;

    local procedure MakeGroupHeadLine()
    begin
        with "Fixed Asset" do
            case GroupTotals of
                GroupTotals::"FA Class":
                    GroupHeadLine := "FA Class Code";
                GroupTotals::"FA Subclass":
                    GroupHeadLine := "FA Subclass Code";
                GroupTotals::"Main Asset":
                    begin
                        GroupHeadLine := StrSubstNo('%1 %2', GroupTotals, "Component of Main Asset");
                        if "Component of Main Asset" = '' then
                            GroupHeadLine := GroupHeadLine + '*****';
                    end;
                GroupTotals::"Global Dimension 1":
                    GroupHeadLine := "Global Dimension 1 Code";
                GroupTotals::"FA Location":
                    GroupHeadLine := "FA Location Code";
                GroupTotals::"Global Dimension 2":
                    GroupHeadLine := "Global Dimension 2 Code";
                GroupTotals::"FA Posting Group":
                    GroupHeadLine := Format("FA Posting Group");
                GroupTotals::"Tax Depreciation Group Code":
                    GroupHeadLine := "Tax Depreciation Group Code";
            end;
        if GroupHeadLine = '' then
            GroupHeadLine := '*****';
    end;

    local procedure SetAmountToZero(linPostingTypeNo: Integer; lopPeriod: Option "Before Starting Date","Net Change","at Ending Date"): Boolean
    begin
        case linPostingTypeNo of
            FADeprBook.FieldNo("Proceeds on Disposal"),
          FADeprBook.FieldNo("Gain/Loss"):
                exit(false);
        end;
        if not SalesReport and (lopPeriod = lopPeriod::"at Ending Date") and (SetSalesMark <> '') then
            exit(true);
        exit(false);
    end;

    local procedure SetAmountToZero2(linPostingTypeNo: Integer; lopPeriod: Option "Before Starting Date","Net Change","at Ending Date"): Boolean
    begin
        case linPostingTypeNo of
            FADeprBook2.FieldNo("Proceeds on Disposal"),
          FADeprBook2.FieldNo("Gain/Loss"):
                exit(false);
        end;
        if not SalesReport and (lopPeriod = lopPeriod::"at Ending Date") and (SetSalesMark2 <> '') then
            exit(true);
        exit(false);
    end;

    local procedure GetStartDate(ldaStartDate: Date): Date
    begin
        if ldaStartDate <= 00000101D then
            exit(0D);

        exit(ldaStartDate - 1);
    end;

    local procedure CheckDateType(lteDateType: Text[30]; var linDateTypeNo: Integer)
    begin
        linDateTypeNo := 0;
        if lteDateType = '' then
            exit;
        with FADateType do begin
            SetRange("FA Entry", true);
            if FindSet then
                repeat
                    TypeExist := lteDateType = "FA Date Type Name";
                    if TypeExist then
                        linDateTypeNo := "FA Date Type No.";
                until (Next() = 0) or TypeExist;
        end;
        if not TypeExist then
            Error(Text007Err, lteDateType);
    end;

    local procedure CheckPostingType(ltePostingType: Text[30]; var linPostingTypeNo: Integer)
    begin
        linPostingTypeNo := 0;
        if ltePostingType = '' then
            exit;
        with FAPostingType do begin
            SetRange("FA Entry", true);
            if FindSet then
                repeat
                    TypeExist := ltePostingType = "FA Posting Type Name";
                    if TypeExist then
                        linPostingTypeNo := "FA Posting Type No.";
                until (Next() = 0) or TypeExist;
        end;
        if not TypeExist then
            Error(Text008Err, ltePostingType);
    end;

    local procedure GetFASetup()
    begin
        if DeprBookCode = '' then begin
            FASetup.Get();
            DeprBookCode := FASetup."Default Depr. Book";
        end;
        FAPostingType.CreateTypes;
        FADateType.CreateTypes;
    end;
}
#endif
