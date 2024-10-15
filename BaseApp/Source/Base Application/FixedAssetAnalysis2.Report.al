report 31042 "Fixed Asset - Analysis 2"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssetAnalysis2.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Fixed Asset - Analysis 2 (Obsolete)';
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
            column(TblCptnFAFilter; TableCaption + ': ' + FAFilter)
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
            column(FooterText; Text002Txt + ': ' + GroupHeadLine)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
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
            column(Fixed_Asset_Global_Dimension_1_Code; "Global Dimension 1 Code")
            {
            }
            column(Fixed_Asset_Global_Dimension_2_Code; "Global Dimension 2 Code")
            {
            }
            column(Fixed_Asset_Component_of_Main_Asset; "Component of Main Asset")
            {
            }
            column(Fixed_Asset_FA_Location_Code; "FA Location Code")
            {
            }
            column(Fixed_Asset_FA_Posting_Group; "FA Posting Group")
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
                if not FADeprBook.Get("No.", DeprBookCode) then
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

                BeforeAmount := 0;
                EndingAmount := 0;
                if BudgetReport then
                    BudgetDepreciation.Calculate("No.", GetStartDate(StartingDate), EndingDate, DeprBookCode, BeforeAmount, EndingAmount);

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
                MakeAmountHeadLine(7, PostingType4, PostingTypeNo4, Period4);
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
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book for the printing of entries.';
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
        if GroupTotals = GroupTotals::"FA Posting Group" then
            FAGenReport.SetFAPostingGroup("Fixed Asset", DeprBook.Code);
        if GroupTotals = GroupTotals::"Tax Depreciation Group Code" then
            FAGenReport.SetFATaxDeprGroup("Fixed Asset", DeprBook.Code);
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters;
        if BudgetReport then
            MainHeadLineText := Text001Txt
        else
            MainHeadLineText := Text000Txt;
        DeprBookText := StrSubstNo(Text012Txt, DeprBook.TableCaption, DeprBookCode);
        if PrintDetails then begin
            FANo := "Fixed Asset".FieldCaption("No.");
            FADescription := "Fixed Asset".FieldCaption(Description);
        end;
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingType: Record "FA Posting Type";
        FADateType: Record "FA Date Type";
        FAGenReport: Codeunit "FA General Report";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        DeprBookCode: Code[10];
        FAFilter: Text;
        MainHeadLineText: Text[100];
        DeprBookText: Text[50];
        GroupCodeName: Text[50];
        GroupHeadLine: Text[50];
        FANo: Text[50];
        FADescription: Text[100];
        HeadLineText: array[7] of Text[50];
        PostingType1: Text[30];
        PostingType2: Text[30];
        PostingType3: Text[30];
        PostingType4: Text[30];
        DateType1: Text[30];
        DateType2: Text[30];
        DateType3: Text[30];
        Date: array[3] of Date;
        StartingDate: Date;
        EndingDate: Date;
        AcquisitionDate: Date;
        DisposalDate: Date;
        BeforeAmount: Decimal;
        EndingAmount: Decimal;
        Amounts: array[4] of Decimal;
        Period1: Option "Before Starting Date","Net Change","at Ending Date";
        Period2: Option "Before Starting Date","Net Change","at Ending Date";
        Period3: Option "Before Starting Date","Net Change","at Ending Date";
        Period4: Option "Before Starting Date","Net Change","at Ending Date";
        PostingTypeNo1: Integer;
        PostingTypeNo2: Integer;
        PostingTypeNo3: Integer;
        PostingTypeNo4: Integer;
        DateTypeNo1: Integer;
        DateTypeNo2: Integer;
        DateTypeNo3: Integer;
        PrintDetails: Boolean;
        BudgetReport: Boolean;
        SalesReport: Boolean;
        TypeExist: Boolean;
        Group: Code[50];
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group","Tax Depreciation Group Code";
        Text000Txt: Label 'Fixed Asset - Analysis';
        Text001Txt: Label 'Fixed Asset - Analysis (Budget Report)';
        Text002Txt: Label 'Group Total';
        Text003Txt: Label 'Sold';
        Text004Txt: Label 'Group Totals: %1';
        Text005Err: Label '%1 or %2 must be specified only together with the option %3.', Comment = '%1=fieldcaption.proceedsondisposal;%2=fieldcaption.gain/loss;%3=period';
        Text006Err: Label 'The Starting Date must be specified when you use the option %1.';
        Text007Err: Label 'The date type %1 is not a valid option.';
        Text008Err: Label 'The posting type %1 is not a valid option.';
        Text009Err: Label '%1 has been modified in fixed asset %2.', Comment = '%1=fieldcaption.fapostinggroup;%2=number';
        Text010Txt: Label 'before Starting Date,Net Change,at Ending Date';
        Text011Txt: Label ' ,FA Class,FA Subclass,FA Location,Main Asset,Global Dimension 1,Global Dimension 2,FA Posting Group';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        Text012Txt: Label '%1: %2', Comment = '%1=depreciationbook.tablecaption ;%2=depreciationbook.code';
        Text013Err: Label '%1 %2', Comment = '%1=postingtype;%2=period';
        Text014Txt: Label '%1 %2', Comment = '%1=grouptotals,componentofmainasset';

    local procedure SkipRecord(): Boolean
    begin
        AcquisitionDate := FADeprBook."Acquisition Date";
        DisposalDate := FADeprBook."Disposal Date";

        if "Fixed Asset".Inactive then
            exit(true);
        if AcquisitionDate = 0D then
            exit(true);
        if (AcquisitionDate > EndingDate) and (EndingDate > 0D) then
            exit(true);
        if SalesReport and (DisposalDate = 0D) then
            exit(true);
        if SalesReport and (EndingDate > 0D) and
           ((DisposalDate > EndingDate) or (DisposalDate < StartingDate))
        then
            exit(true);

        if not SalesReport and (DisposalDate > 0D) and (DisposalDate < StartingDate) then
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
        HeadLineText[6] := DateType3;
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
        HeadLineText[i] := StrSubstNo(Text013Err, ltePostingType, SelectStr(lopPeriod + 1, Text010Txt));
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
                        GroupHeadLine := StrSubstNo('%1 %2', SelectStr(GroupTotals + 1, Text011Txt), "Component of Main Asset");
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
                    GroupHeadLine := "FA Posting Group";
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

    local procedure GetStartDate(ldaStartDate: Date): Date
    begin
        if ldaStartDate = 0D then
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

